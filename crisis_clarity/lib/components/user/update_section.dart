import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:crisis_clarity/features/alerts/providers/alert_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class UpdateSection extends ConsumerStatefulWidget {
  const UpdateSection({super.key});

  @override
  ConsumerState<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends ConsumerState<UpdateSection> {
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(liveNewsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Disaster Intelligence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: newsAsync.when(
              data: (news) {
                final filtered = news.where((n) {
                  final title = n['title']?.toString().toLowerCase() ?? "";
                  final desc = n['description']?.toString().toLowerCase() ?? "";
                  return title.contains(_searchQuery.toLowerCase()) || 
                         desc.contains(_searchQuery.toLowerCase());
                }).toList();

                if (news.isEmpty) return _buildEmptyState();
                if (filtered.isEmpty) return _buildNoResultsState();
                return _buildUpdatesList(filtered);
              },
              loading: () => _buildLoadingState(),
              error: (err, stack) => _buildErrorState(err.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search updates...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = "");
                }) 
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No matches for "$_searchQuery"', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _searchQuery = "");
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: Lottie.asset(
              'assets/animations/update_loading.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Scanning for latest updates...',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text('Failed to load updates: $error', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          TextButton(
            onPressed: () => ref.invalidate(liveNewsProvider),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300, height: 300,
            child: Lottie.asset('assets/animations/nothing_here_animation.json', fit: BoxFit.contain),
          ),
          const Text('No Recent Updates',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
          const SizedBox(height: 8),
          const Text('Check back later for real-time information.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(liveNewsProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed, foregroundColor: Colors.white),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesList(List<Map<String, dynamic>> news) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(liveNewsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: news.length,
        itemBuilder: (context, index) {
          final n = news[index];
          final severity = n['severity']?.toString().toLowerCase() ?? 'low';
          final isUrgent = severity == 'high' || severity == 'critical';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildUpdateCard(
              icon: _getIconForDisaster(n['disaster_type']?.toString()),
              title: n['title'] ?? 'Disaster Update',
              source: n['source'] ?? 'Verified News',
              time: _formatTimestamp(n['published']),
              description: n['description'] ?? 'No details available.',
              isUrgent: isUrgent,
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      if (timestamp is String) return timestamp;
      // Handle other formats if needed
      return 'Recently';
    } catch (e) {
      return 'Recently';
    }
  }

  IconData _getIconForDisaster(String? type) {
    switch (type?.toLowerCase()) {
      case 'flood': return Icons.water_drop;
      case 'fire': return Icons.local_fire_department;
      case 'storm': return Icons.cyclone;
      case 'earthquake': return Icons.landscape;
      default: return Icons.warning_amber_rounded;
    }
  }

  Widget _buildUpdateCard({
    required IconData icon,
    required String title,
    required String source,
    required String time,
    required String description,
    required bool isUrgent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUrgent ? AppTheme.primaryRed : Colors.grey[200]!, width: isUrgent ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: isUrgent ? AppTheme.primaryRed.withOpacity(0.1) : Colors.grey[100], shape: BoxShape.circle),
                  child: Icon(icon, color: isUrgent ? AppTheme.primaryRed : Colors.grey[600], size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Text(source, style: TextStyle(fontSize: 10, color: AppTheme.primaryRed, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('•  $time', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUrgent) _UrgentPulse(),
              ],
            ),
            const SizedBox(height: 12),
            Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _UrgentPulse extends StatefulWidget {
  @override State<_UrgentPulse> createState() => _UrgentPulseState();
}
class _UrgentPulseState extends State<_UrgentPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.5, end: 1.0).animate(_c),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: const Text('URGENT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.primaryRed)),
    ),
  );
}