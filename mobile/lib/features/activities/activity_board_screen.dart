import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/activities/activity_repository.dart';
import 'package:wish_list_mobile/features/gifts/gift_repository.dart';
import 'package:wish_list_mobile/features/reservations/reservation_repository.dart';

// Activity board: draw/Arrancar, leave, cure prompts, private recipient.
// Traceability: [REQ-ACT-001], [REQ-ACT-003], [REQ-MOB-001]
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
      if (!mounted) return;
      setState(() {
        _activity = activity;
        _assignment = assignment;
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

  Future<void> _run(Future<ActivityShell> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
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
        Text(s.activityPersonalWishlistsHeading),
      ],
    );
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
