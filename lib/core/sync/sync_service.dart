import 'package:notebook_pro/core/sync/sync_status.dart';

/// Future Firebase sync entry point. MVP uses [NoopSyncService].
abstract class SyncService {
  Future<void> pushPendingChanges();
  Stream<SyncStatus> get status;
}
