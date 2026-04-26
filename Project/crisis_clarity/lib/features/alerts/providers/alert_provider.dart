import 'dart:async';
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

final liveNewsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final response = await ref.watch(alertRepositoryProvider).fetchLiveNews();
    return response;
  } catch (e) {
    print('Error fetching live news: $e');
    return [];
  }
});

/// Streaming news provider — accumulates news items one-by-one via polling
final streamingNewsProvider = StateNotifierProvider<StreamingNewsNotifier, List<Map<String, dynamic>>>((ref) {
  return StreamingNewsNotifier(ref.watch(alertRepositoryProvider));
});

class StreamingNewsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final AlertRepository _repo;
  Timer? _timer;
  static const int _maxItems = 15;
  final Set<String> _seenTitles = {};

  StreamingNewsNotifier(this._repo) : super([]) {
    _startPolling();
  }

  void _startPolling() {
    // Fetch first item immediately
    _fetchNext();
    // Then poll every 12 seconds for a more dynamic demo feel
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _fetchNext());
  }

  Future<void> _fetchNext() async {
    try {
      final item = await _repo.fetchNextNewsItem();
      if (item != null) {
        final title = item['title']?.toString() ?? '';
        // Avoid duplicates by title
        if (!_seenTitles.contains(title)) {
          _seenTitles.add(title);
          // Prepend new item at top
          state = [item, ...state].take(_maxItems).toList();
        } else {
          // If we've seen all titles, clear and start fresh
          if (_seenTitles.length >= 20) {
            _seenTitles.clear();
          }
        }
      }
    } catch (e) {
      print('Streaming news fetch error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Streaming alerts provider — drip-feeds alerts one-by-one
final streamingAlertsProvider = StateNotifierProvider<StreamingAlertsNotifier, List<Map<String, dynamic>>>((ref) {
  return StreamingAlertsNotifier(ref.watch(alertRepositoryProvider));
});

class StreamingAlertsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final AlertRepository _repo;
  Timer? _timer;
  static const int _maxItems = 10;
  final Set<String> _seenIds = {};

  StreamingAlertsNotifier(this._repo) : super([]) {
    _startPolling();
  }

  void _startPolling() {
    _fetchNext();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _fetchNext());
  }

  Future<void> _fetchNext() async {
    try {
      final item = await _repo.fetchNextAlert();
      if (item != null) {
        final id = item['event_id']?.toString() ?? '';
        if (!_seenIds.contains(id)) {
          _seenIds.add(id);
          state = [item, ...state].take(_maxItems).toList();
        } else if (_seenIds.length >= 20) {
          _seenIds.clear();
        }
      }
    } catch (e) {
      print('Streaming alerts fetch error: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
