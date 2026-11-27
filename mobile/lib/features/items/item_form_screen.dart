import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/items/image_compressor.dart';
import 'package:wish_list_mobile/features/items/item_image_picker.dart';
import 'package:wish_list_mobile/features/items/item_models.dart';
import 'package:wish_list_mobile/features/items/item_repository.dart';

// Add/edit item with paste-URL preview confirm (O3A) and optional price (O5A).
// Traceability: [REQ-ITEM-001], [REQ-ITEM-002], [REQ-ITEM-003], [REQ-ITEM-006], [REQ-ARCH-002]
class ItemFormScreen extends StatefulWidget {
  final DesignTokens tokens;
  final AppStrings strings;
  final ItemRepository itemRepository;
  final int wishlistId;
  final WishlistItem? existing;
  final ItemImagePicker? imagePicker;
  final String? initialStoreUrl;
  final String? initialTitle;

  const ItemFormScreen({
    super.key,
    required this.tokens,
    required this.strings,
    required this.itemRepository,
    required this.wishlistId,
    this.existing,
    this.imagePicker,
    this.initialStoreUrl,
    this.initialTitle,
  });

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _specs;
  late final TextEditingController _links;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _storeUrl;
  late final ItemImagePicker _picker;
  String _priority = 'medium';
  LinkPreview? _preview;
  bool _previewConfirmed = false;
  String? _error;
  bool _saving = false;
  List<CompressedImageBlob> _images = const [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final seedTitle = e?.title ?? widget.initialTitle ?? '';
    final seedLinks = e?.links.map((l) => l.url).join('\n') ?? '';
    final shareUrl = widget.initialStoreUrl?.trim() ?? '';
    _title = TextEditingController(text: seedTitle);
    _specs = TextEditingController(text: e?.specifications ?? '');
    _links = TextEditingController(
      text: seedLinks.isNotEmpty
          ? seedLinks
          : (shareUrl.isNotEmpty ? shareUrl : ''),
    );
    _price = TextEditingController(
      text: e?.priceCents != null ? '${e!.priceCents}' : '',
    );
    _currency = TextEditingController(text: e?.currency ?? '');
    _storeUrl = TextEditingController(text: shareUrl);
    _priority = e?.priority ?? 'medium';
    _picker = widget.imagePicker ?? ItemImagePicker();
  }

  @override
  void dispose() {
    _title.dispose();
    _specs.dispose();
    _links.dispose();
    _price.dispose();
    _currency.dispose();
    _storeUrl.dispose();
    super.dispose();
  }

  Future<void> _previewLink() async {
    setState(() {
      _error = null;
      _preview = null;
      _previewConfirmed = false;
    });
    try {
      final preview = await widget.itemRepository.previewLink(
        url: _storeUrl.text,
      );
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  void _applyPreview() {
    final preview = _preview;
    if (preview == null) return;
    if (_title.text.trim().isEmpty && preview.title.isNotEmpty) {
      _title.text = preview.title;
    }
    if (preview.sourceUrl.isNotEmpty &&
        !_links.text.contains(preview.sourceUrl)) {
      _links.text = [
        if (_links.text.trim().isNotEmpty) _links.text.trim(),
        preview.sourceUrl,
      ].join('\n');
    }
    setState(() => _previewConfirmed = true);
  }

  Future<void> _pickGallery() async {
    try {
      final remaining = CompressedImageBlob.maxImages - _images.length;
      if (remaining <= 0) return;
      final picked = await _picker.pickFromGallery(maxCount: remaining);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _images = [..._images, ...picked].take(CompressedImageBlob.maxImages).toList();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  Future<void> _pickCamera() async {
    try {
      if (_images.length >= CompressedImageBlob.maxImages) return;
      final shot = await _picker.pickFromCamera();
      if (!mounted || shot == null) return;
      setState(() {
        _images = [..._images, shot];
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final linkUrls = _links.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList(growable: false);
      final priceRaw = _price.text.trim();
      final currencyRaw = _currency.text.trim().toUpperCase();
      final priceCents = priceRaw.isEmpty ? null : int.tryParse(priceRaw);
      final currency = currencyRaw.isEmpty ? null : currencyRaw;

      if (widget.existing == null) {
        await widget.itemRepository.createItem(
          wishlistId: widget.wishlistId,
          title: _title.text,
          specifications: _specs.text.trim().isEmpty ? null : _specs.text.trim(),
          priority: _priority,
          priceCents: priceCents,
          currency: currency,
          linkUrls: linkUrls,
          confirmedPreview: _previewConfirmed ? _preview : null,
          images: _images,
        );
      } else {
        await widget.itemRepository.updateItem(
          itemId: widget.existing!.id,
          title: _title.text.trim(),
          specifications: _specs.text.trim().isEmpty ? null : _specs.text.trim(),
          priority: _priority,
          priceCents: priceCents,
          currency: currency,
          linkUrls: linkUrls,
          images: _images,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = widget.strings.errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? s.addItemButton : s.editItemTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _storeUrl,
            decoration: InputDecoration(labelText: s.pasteStoreUrlLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _previewLink,
            child: Text(s.previewLinkButton),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 8),
            Text('${_preview!.title}\n${_preview!.imageUrl}'),
            TextButton(
              onPressed: _applyPreview,
              child: Text(s.confirmPreviewButton),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: s.itemTitleLabel),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: widget.tokens.specBg,
              border: Border(
                left: BorderSide(color: widget.tokens.accent, width: 4),
              ),
            ),
            child: TextField(
              controller: _specs,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.itemSpecsLabel,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(s.itemPriorityLabel),
          Wrap(
            spacing: 8,
            children: [
              for (final p in ItemRepository.allowedPriorities)
                ChoiceChip(
                  label: Text(p),
                  selected: _priority == p,
                  onSelected: (_) => setState(() => _priority = p),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _links,
            maxLines: 3,
            decoration: InputDecoration(labelText: s.itemLinksLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: s.itemPriceLabel),
          ),
          TextField(
            controller: _currency,
            decoration: InputDecoration(labelText: s.itemCurrencyLabel),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                key: const Key('item_gallery_button'),
                onPressed: _saving ? null : _pickGallery,
                child: Text(s.addPhotosGalleryButton),
              ),
              OutlinedButton(
                key: const Key('item_camera_button'),
                onPressed: _saving ? null : _pickCamera,
                child: Text(s.addPhotoCameraButton),
              ),
            ],
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${s.selectedPhotosLabel}: ${_images.length}'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: widget.tokens.accent)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(s.saveItemButton),
          ),
        ],
      ),
    );
  }
}
