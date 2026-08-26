import 'package:notebook_pro/core/sync/sync_status.dart';

/// Offline-first cloud sync entry point.
abstract class SyncService {
  Future<void> pushPendingChanges();
  Stream<SyncStatus> get status;
  DateTime? get lastSyncedAt;
}
