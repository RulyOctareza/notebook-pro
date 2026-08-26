import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:notebook_pro/core/sync/sync_status.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).valueOrNull ?? SyncStatus.offline;
    final last = ref.watch(syncServiceProvider).lastSyncedAt;
    final theme = Theme.of(context);

    final (icon, color, label) = switch (status) {
      SyncStatus.synced => (
        Icons.cloud_done_outlined,
        theme.colorScheme.primary,
        last == null
            ? 'Synced'
            : 'Synced ${DateFormat.jm().format(last.toLocal())}',
      ),
      SyncStatus.pending => (
        Icons.cloud_sync_outlined,
        theme.colorScheme.tertiary,
        'Syncing…',
      ),
      SyncStatus.offline => (
        Icons.cloud_off_outlined,
        theme.colorScheme.outline,
        'Offline',
      ),
      SyncStatus.conflict => (
        Icons.cloud_queue_outlined,
        theme.colorScheme.error,
        'Local edits kept',
      ),
    };

    return Tooltip(
      message: status == SyncStatus.conflict
          ? 'Remote changes deferred until local edits sync'
          : label,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: () =>
            ref.read(syncServiceProvider).pushPendingChanges(),
        icon: Icon(icon, size: 18, color: color),
        tooltip: label,
      ),
    );
  }
}
