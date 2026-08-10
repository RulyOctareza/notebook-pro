import 'package:notebook_pro/core/sync/sync_service.dart';
import 'package:notebook_pro/core/sync/sync_status.dart';

class NoopSyncService implements SyncService {
  @override
  Future<void> pushPendingChanges() async {}

  @override
  Stream<SyncStatus> get status => Stream.value(SyncStatus.synced);
}
