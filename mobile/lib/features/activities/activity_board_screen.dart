import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/activities/activity_repository.dart';
import 'package:wish_list_mobile/features/gifts/gift_models.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';
import 'package:wish_list_mobile/features/items/item_models.dart';
import 'package:wish_list_mobile/features/reservations/reservation_models.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

// Activity board: draw/Arrancar, leave, cure, activity lists + reserve/gift.
// Traceability: [REQ-ACT-001], [REQ-ACT-003], [REQ-ACT-005], [REQ-MOB-001]
class ActivityBoardScreen extends StatefulWidget {
  final ActivityRepository activityRepository;
  final ReservationRepository? reservationRepository;
  final GiftRepository? giftRepository;
  final AppStrings strings;
  final DesignTokens tokens;
  final int activityId;
  final int? viewerUserId;

  const ActivityBoardScreen({
    super.key,
    required this.activityRepository,
    required this.strings,
    required this.tokens,
    required this.activityId,
    this.reservationRepository,
    this.giftRepository,
    this.viewerUserId,
  });

  @override
  State<ActivityBoardScreen> createState() => _ActivityBoardScreenState();
}

class _ActivityBoardScreenState extends State<ActivityBoardScreen> {
  ActivityShell? _activity;
  ActivityAssignmentView? _assignment;
  List<ActivityWishlistView> _wishlists = const [];
  Map<int, List<WishlistItem>> _itemsByWishlist = const {};
  final Map<int, ReservationModel> _holdsByItemId = {};
  final Map<int, GiftModel> _openGiftsByItemId = {};
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final activity =
          await widget.activityRepository.fetchActivity(widget.activityId);
      final assignment = await widget.activityRepository.myAssignment(
        activityId: widget.activityId,
      );
      final wishlists = await widget.activityRepository.fetchActivityWishlists(
        activityId: widget.activityId,
      );
      final itemsByWishlist = <int, List<WishlistItem>>{};
      for (final list in wishlists.take(ActivityRepository.maxList)) {
        itemsByWishlist[list.id] =
            await widget.activityRepository.fetchActivityItems(
          activityId: widget.activityId,
          wishlistId: list.id,
        );
      }
      await _syncHoldsAndGiftsFromMine();
      if (!mounted) return;
      setState(() {
        _activity = activity;
        _assignment = assignment;
        _wishlists = wishlists;
        _itemsByWishlist = itemsByWishlist;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _syncHoldsAndGiftsFromMine() async {
    final repo = widget.reservationRepository;
    if (repo == null) return;
    try {
      final bundle = await repo.fetchMineWithOpenGifts();
      _holdsByItemId.removeWhere((_, _) => true);
      for (final hold in bundle.reservations.take(200)) {
        if (hold.activityId == widget.activityId) {
          _holdsByItemId[hold.itemId] = hold;
        }
      }
      _openGiftsByItemId.removeWhere((_, _) => true);
      for (final gift in bundle.openGifts.take(200)) {
        if (gift.activityId == widget.activityId) {
          _openGiftsByItemId[gift.itemId] = gift;
        }
      }
    } catch (_) {
      // Board still usable without my-reservations sync.
    }
  }

  Future<void> _run(Future<ActivityShell> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  bool _isOwner(ActivityWishlistView list) {
    if (list.viewerIsOwner) return true;
    final viewerId = widget.viewerUserId;
    return viewerId != null && list.ownerId == viewerId;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final activity = _activity;
    return Scaffold(
      appBar: AppBar(title: Text(s.activityBoardTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : activity == null
              ? Center(child: Text(_error ?? s.genericError))
              : _boardBody(context, activity, s),
    );
  }

  Widget _boardBody(BuildContext context, ActivityShell activity, AppStrings s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(activity.name, style: Theme.of(context).textTheme.headlineSmall),
        Text('${_modeLabel(activity, s)} · ${_statusLabel(activity, s)}'),
        if (activity.needsDropoutRecovery)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(s.activityNeedsCureLabel),
          ),
        if (_assignment?.recipientUsername != null)
          Text(
            '${s.activityYourRecipientLabel}: @${_assignment!.recipientUsername}',
          ),
        if (_error != null) Text(_error!),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._inviteActions(activity, s),
            ..._manageActions(activity, s),
            ..._participantActions(activity, s),
          ],
        ),
        const SizedBox(height: 16),
        Text(s.activityListsHeading),
        ..._wishlists.map((list) => _wishlistSection(list, activity, s)),
        const SizedBox(height: 16),
        Text(s.activityPersonalWishlistsHeading),
      ],
    );
  }

  Widget _wishlistSection(
    ActivityWishlistView list,
    ActivityShell activity,
    AppStrings s,
  ) {
    final owner = _isOwner(list);
    final items = _itemsByWishlist[list.id] ?? const <WishlistItem>[];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(list.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (list.ownerUsername != null) Text('@${list.ownerUsername}'),
          if (owner) _ownerAddForm(list, activity, s),
          ...items.map((item) => _itemRow(item, owner: owner, s: s)),
        ],
      ),
    );
  }

  Widget _ownerAddForm(
    ActivityWishlistView list,
    ActivityShell activity,
    AppStrings s,
  ) {
    return _ActivityItemAddForm(
      strings: s,
      onSubmit: (title, priceRaw) => _createItem(
        list: list,
        activity: activity,
        title: title,
        priceRaw: priceRaw,
      ),
    );
  }

  Future<void> _createItem({
    required ActivityWishlistView list,
    required ActivityShell activity,
    required String title,
    required String priceRaw,
  }) async {
    try {
      final price = priceRaw.trim().isEmpty ? null : int.tryParse(priceRaw.trim());
      await widget.activityRepository.createActivityItem(
        activityId: activity.id,
        wishlistId: list.id,
        title: title,
        priceCents: price,
        currency: activity.currency,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Widget _itemRow(WishlistItem item, {required bool owner, required AppStrings s}) {
    return ListTile(
      title: Text(item.title),
      subtitle: item.priceCents == null
          ? null
          : Text('${item.priceCents} ${item.currency ?? ''}'),
      trailing: owner ? _ownerActions(item, s) : _peerActions(item, s),
    );
  }

  Widget? _ownerActions(WishlistItem item, AppStrings s) {
    final gifts = widget.giftRepository;
    if (gifts == null || item.receivedGift) return null;

    return TextButton(
      onPressed: () => _ownerReceiveFlow(item, gifts),
      child: Text(
        item.pendingConfirmGiftId != null
            ? s.confirmReceivedButton
            : s.markReceivedButton,
      ),
    );
  }

  Widget? _peerActions(WishlistItem item, AppStrings s) {
    final reservations = widget.reservationRepository;
    if (reservations == null) return null;

    final holdActions = _holdPeerActions(item, reservations, s);
    if (holdActions != null) return holdActions;

    final giftActions = _openGiftPeerActions(item, s);
    if (giftActions != null) return giftActions;

    return _availabilityPeerTrailing(item, reservations, s);
  }

  Widget? _holdPeerActions(
    WishlistItem item,
    ReservationRepository reservations,
    AppStrings s,
  ) {
    final hold = _holdsByItemId[item.id];
    if (hold == null) return null;
    if (hold.status != 'active' && hold.status != 'expired_grace') return null;

    final gifts = widget.giftRepository;
    return Wrap(
      spacing: 4,
      children: [
        TextButton(
          onPressed: () => _extendHold(hold, reservations),
          child: Text(s.extendReservationButton),
        ),
        if (gifts != null)
          TextButton(
            onPressed: () => _markPurchased(hold, gifts),
            child: Text(s.markPurchasedButton),
          ),
      ],
    );
  }

  Widget? _openGiftPeerActions(WishlistItem item, AppStrings s) {
    final gifts = widget.giftRepository;
    final openGift = _openGiftsByItemId[item.id];
    if (gifts == null || openGift == null) return null;
    if (openGift.status != 'purchased_secret') return null;

    return TextButton(
      onPressed: () => _markDelivered(openGift, gifts),
      child: Text(s.markDeliveredButton),
    );
  }

  Widget _availabilityPeerTrailing(
    WishlistItem item,
    ReservationRepository reservations,
    AppStrings s,
  ) {
    if (item.availability == 'available' || item.availability == null) {
      return TextButton(
        onPressed: () => _reserve(item, reservations),
        child: Text(s.reserveButton),
      );
    }
    if (item.availability == 'reserved_by_me') {
      return Text(s.availabilityReservedByMe);
    }
    return Text(s.availabilityUnavailable);
  }

  Future<void> _reserve(WishlistItem item, ReservationRepository repo) async {
    try {
      final date = DateTime.now().toUtc().add(const Duration(days: 7));
      final iso =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hold = await repo.create(itemId: item.id, estimatedDate: iso);
      _holdsByItemId[item.id] = hold;
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _extendHold(
    ReservationModel hold,
    ReservationRepository repo,
  ) async {
    try {
      final date = DateTime.now().toUtc().add(const Duration(days: 14));
      final iso =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final updated = await repo.extend(
        reservationId: hold.id,
        estimatedDate: iso,
      );
      _holdsByItemId[updated.itemId] = updated;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _markPurchased(
    ReservationModel hold,
    GiftRepository gifts,
  ) async {
    try {
      final gift = await gifts.markPurchased(reservationId: hold.id);
      _holdsByItemId.remove(hold.itemId);
      _openGiftsByItemId[gift.itemId] = gift;
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _markDelivered(GiftModel gift, GiftRepository gifts) async {
    try {
      await gifts.markDelivered(giftId: gift.id);
      _openGiftsByItemId.remove(gift.itemId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  // [REQ-GIFT-003] Path 1 confirm or Path 2 owner mark received on the activity board.
  Future<void> _ownerReceiveFlow(WishlistItem item, GiftRepository gifts) async {
    final note = await _promptThankYouNote();
    if (note == null || !mounted) return;
    final trimmed = note.trim();
    final thankYou = trimmed.isEmpty ? null : trimmed;
    try {
      final pendingId = item.pendingConfirmGiftId;
      if (pendingId != null) {
        await gifts.confirmReceived(giftId: pendingId, thankYouNote: thankYou);
      } else {
        await gifts.ownerMarkReceived(itemId: item.id, thankYouNote: thankYou);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<String?> _promptThankYouNote() async {
    final controller = TextEditingController();
    final s = widget.strings;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.thankYouOptionalLabel),
        content: TextField(
          controller: controller,
          maxLength: 500,
          decoration: InputDecoration(labelText: s.thankYouOptionalLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.dialogCancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(s.confirmReceivedButton),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  List<Widget> _inviteActions(ActivityShell activity, AppStrings s) {
    if (!activity.isInvited) return const [];
    return [
      ElevatedButton(
        onPressed: () async {
          try {
            await widget.activityRepository.acceptInvite(activityId: activity.id);
            await _load();
          } catch (e) {
            if (!mounted) return;
            setState(() => _error = e.toString());
          }
        },
        child: Text(s.activityAcceptAction),
      ),
      OutlinedButton(
        onPressed: () async {
          final navigator = Navigator.of(context);
          try {
            await widget.activityRepository.declineInvite(activityId: activity.id);
            if (!mounted) return;
            navigator.maybePop();
          } catch (e) {
            if (!mounted) return;
            setState(() => _error = e.toString());
          }
        },
        child: Text(s.activityDeclineAction),
      ),
    ];
  }

  List<Widget> _manageActions(ActivityShell activity, AppStrings s) {
    if (!activity.viewerCanManage) return const [];
    final actions = <Widget>[];
    if (!activity.isSealed && activity.isSecretSanta) {
      actions.add(
        ElevatedButton(
          onPressed: () => _run(
            () => widget.activityRepository.draw(activityId: activity.id),
          ),
          child: Text(s.activityDrawAction),
        ),
      );
    }
    if (!activity.isSealed && activity.isOpenGifting) {
      actions.add(
        ElevatedButton(
          onPressed: () => _run(
            () => widget.activityRepository.arrancar(activityId: activity.id),
          ),
          child: Text(s.activityArrancarAction),
        ),
      );
    }
    if (activity.needsDropoutRecovery) {
      actions.addAll([
        ElevatedButton(
          onPressed: () => _run(
            () => widget.activityRepository.blindBridge(activityId: activity.id),
          ),
          child: Text(s.activityBlindBridgeAction),
        ),
        ElevatedButton(
          onPressed: () => _run(
            () => widget.activityRepository.fullRedraw(activityId: activity.id),
          ),
          child: Text(s.activityFullRedrawAction),
        ),
      ]);
    }
    actions.add(
      OutlinedButton(
        onPressed: () => _run(
          () => widget.activityRepository.cancel(activityId: activity.id),
        ),
        child: Text(s.activityCancelAction),
      ),
    );
    return actions;
  }

  List<Widget> _participantActions(ActivityShell activity, AppStrings s) {
    if (activity.isInvited) return const [];
    return [
      OutlinedButton(
        onPressed: () => _run(
          () => widget.activityRepository.leave(activityId: activity.id),
        ),
        child: Text(s.activityLeaveAction),
      ),
    ];
  }

  String _modeLabel(ActivityShell activity, AppStrings s) {
    return activity.isSecretSanta
        ? s.activityModeSecretSantaLabel
        : s.activityModeOpenGiftingLabel;
  }

  String _statusLabel(ActivityShell activity, AppStrings s) {
    if (activity.isSealed) return s.activityStatusSealedLabel;
    if (activity.status == ActivityLifecycleStatus.cancelled) {
      return s.activityStatusCancelledLabel;
    }
    return s.activityStatusOpenLabel;
  }
}

class _ActivityItemAddForm extends StatefulWidget {
  final AppStrings strings;
  final Future<void> Function(String title, String priceRaw) onSubmit;

  const _ActivityItemAddForm({
    required this.strings,
    required this.onSubmit,
  });

  @override
  State<_ActivityItemAddForm> createState() => _ActivityItemAddFormState();
}

class _ActivityItemAddFormState extends State<_ActivityItemAddForm> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          TextField(
            key: const Key('activity_item_title'),
            controller: _titleController,
            decoration: InputDecoration(labelText: s.addItemButton),
          ),
          TextField(
            key: const Key('activity_item_price'),
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: s.itemPriceLabel),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => widget.onSubmit(
                _titleController.text,
                _priceController.text,
              ),
              child: Text(s.saveItemButton),
            ),
          ),
        ],
      ),
    );
  }
}
