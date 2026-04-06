import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/alert_repository.dart';
import '../domain/alert_model.dart';
import '../../auth/providers/auth_provider.dart';

final alertRepositoryProvider = Provider((ref) => AlertRepository());

final activeAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  final user = ref.watch(userProfileProvider).value;
  if (user != null) {
    return ref.watch(alertRepositoryProvider).getActiveAlerts(user.location);
  }
  return Stream.value([]);
});

final alertUpdatesProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, alertId) {
  return ref.watch(alertRepositoryProvider).getAlertUpdates(alertId);
});

final safetyInstructionsProvider = FutureProvider.family<List<Map<String, String>>, String>((ref, disasterType) async {
  return await ref.watch(alertRepositoryProvider).getSafetyInstructions(disasterType);
});

final hasRespondedProvider = FutureProvider.family<bool, String>((ref, alertId) async {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return await ref.watch(alertRepositoryProvider).hasUserResponded(alertId, user.uid);
  }
  return false;
});
