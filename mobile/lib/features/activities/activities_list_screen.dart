import 'package:flutter/material.dart';
import 'package:wish_list_mobile/core/i18n/app_strings.dart';
import 'package:wish_list_mobile/core/theme/design_tokens.dart';
import 'package:wish_list_mobile/features/activities/activity_board_screen.dart';
import 'package:wish_list_mobile/features/activities/activity_repository.dart';

// Lists the user's activities and supports create (Sprint A shell).
// Traceability: [REQ-ACT-001], [REQ-MOB-001]
class ActivitiesListScreen extends StatefulWidget {
  final ActivityRepository activityRepository;
  final AppStrings strings;
  final DesignTokens tokens;

  const ActivitiesListScreen({
    super.key,
    required this.activityRepository,
    required this.strings,
    required this.tokens,
  });

  @override
  State<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  late Future<List<ActivityShell>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.activityRepository.fetchActivities();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.activityRepository.fetchActivities();
    });
    await _future;
  }

  Future<void> _create() async {
    final created = await widget.activityRepository.createActivity(
      name: widget.strings.createActivityButton,
      currency: 'CRC',
      assignmentMode: ActivityAssignmentMode.secretSanta,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActivityBoardScreen(
          activityRepository: widget.activityRepository,
          strings: widget.strings,
          tokens: widget.tokens,
          activityId: created.id,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.activitiesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        label: Text(s.createActivityButton),
      ),
      body: FutureBuilder<List<ActivityShell>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <ActivityShell>[];
          if (items.isEmpty) {
            return Center(child: Text(s.noActivitiesYet));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final activity = items[index];
              return ListTile(
                title: Text(activity.name),
                subtitle: Text(
                  activity.isSealed
                      ? s.activityStatusSealedLabel
                      : activity.status == ActivityLifecycleStatus.cancelled
                          ? s.activityStatusCancelledLabel
                          : s.activityStatusOpenLabel,
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ActivityBoardScreen(
                        activityRepository: widget.activityRepository,
                        strings: widget.strings,
                        tokens: widget.tokens,
                        activityId: activity.id,
                      ),
                    ),
                  );
                  await _reload();
                },
              );
            },
          );
        },
      ),
    );
  }
}
