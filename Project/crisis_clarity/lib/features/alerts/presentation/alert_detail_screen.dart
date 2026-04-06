import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import '../domain/alert_model.dart';
import '../../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class AlertDetailScreen extends ConsumerStatefulWidget {
  final String alertId;

  const AlertDetailScreen({super.key, required this.alertId});

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  String _selectedLang = 'en';
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    // Initial language based on user profile
    final user = ref.read(userProfileProvider).value;
    if (user != null) _selectedLang = user.preferredLanguage;
  }

  Future<void> _submitFeedback(String response, AlertModel alert) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    
    await ref.read(alertRepositoryProvider).submitFeedback(alert.id, user.uid, response);
    setState(() => _hasVoted = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(activeAlertsProvider);
    final alert = alertsAsync.value?.firstWhere((a) => a.id == widget.alertId);
    
    if (alert == null) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    final severityColor = _getSeverityColor(alert.severity);
    final updatesAsync = ref.watch(alertUpdatesProvider(alert.id));
    final safetyAsync = ref.watch(safetyInstructionsProvider(alert.disasterType));
    final hasVotedAsync = ref.watch(hasRespondedProvider(alert.id));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(alert, severityColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageToggle(),
                  const SizedBox(height: 24),
                  _buildMainContent(alert),
                  const SizedBox(height: 32),
                  _buildSafetyInstructions(safetyAsync),
                  const SizedBox(height: 32),
                  _buildUpdatesTimeline(updatesAsync),
                  const SizedBox(height: 40),
                  _buildFeedbackWidget(hasVotedAsync.value ?? _hasVoted, alert),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Share.share('${alert.getLocalizedTitle(_selectedLang)}\n\n${alert.getLocalizedSimplified(_selectedLang)}\n\nStay alert via CrisisClarity'),
        icon: const Icon(Icons.share_rounded),
        label: const Text('SHARE ALERT'),
      ),
    );
  }

  Widget _buildSliverAppBar(AlertModel alert, Color color) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(color: color),
            Positioned(
              right: -50, top: -50,
              child: Icon(_getIcon(alert.disasterType), size: 250, color: Colors.white.withOpacity(0.15)),
            ),
            Center(child: Icon(_getIcon(alert.disasterType), size: 80, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['en', 'hi', 'mr'].map((lang) {
          final isSelected = _selectedLang == lang;
          return GestureDetector(
            onTap: () => setState(() => _selectedLang = lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryRed : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lang == 'en' ? 'ENG' : lang == 'hi' ? 'हिंदी' : 'मराठी',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainContent(AlertModel alert) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          alert.getLocalizedTitle(_selectedLang),
          style: GoogleFonts.dmSerifDisplay(fontSize: 32, height: 1.1),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: Colors.black45),
            const SizedBox(width: 4),
            Text(
              timeago.format(alert.createdAt),
              style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.secondaryTeal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.secondaryTeal.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIMPLIFIED ALERT',
                style: TextStyle(color: AppTheme.secondaryTeal, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                alert.getLocalizedSimplified(_selectedLang),
                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyInstructions(AsyncValue<List<Map<String, String>>> safetyAsync) {
    return safetyAsync.when(
      data: (steps) {
        if (steps.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SAFETY INSTRUCTIONS', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value[_selectedLang] ?? entry.value['en'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 12, backgroundColor: AppTheme.primaryRed, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildUpdatesTimeline(AsyncValue<List<Map<String, dynamic>>> updatesAsync) {
    return updatesAsync.when(
      data: (updates) {
        if (updates.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LIVE UPDATES', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
            const SizedBox(height: 16),
            ...updates.map((upd) => _buildUpdateCard(upd)),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> update) {
    final msg = update['message$_selectedLang'] ?? update['messageEn'] ?? '';
    final time = (update['createdAt'] as Timestamp).toDate();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primaryRed),
              const SizedBox(width: 6),
              Text(timeago.format(time), style: const TextStyle(fontSize: 11, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 6),
          Text(msg, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFeedbackWidget(bool hasVoted, AlertModel alert) {
    if (hasVoted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.secondaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryTeal, size: 40),
            const SizedBox(height: 12),
            const Text('Voted Successfully!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Your feedback helps authorities improve alerts.', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );
    }
    return Column(
      children: [
        const Text('Did you understand this alert?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryTeal),
                onPressed: () => _submitFeedback('understood', alert),
                child: const Text('I UNDERSTOOD ✓'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                onPressed: () => _submitFeedback('not_understood', alert),
                child: const Text('I NEED HELP ✗'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Getters
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return AppTheme.errorRed;
      case 'high': return AppTheme.primaryRed;
      case 'medium': return AppTheme.warningAmber;
      case 'low': return AppTheme.secondaryTeal;
      default: return Colors.grey;
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'flood': return Icons.water_drop_rounded;
      case 'storm': return Icons.bolt_rounded;
      case 'fire': return Icons.local_fire_department_rounded;
      case 'evacuation': return Icons.exit_to_app_rounded;
      case 'cyclone': return Icons.cyclone_rounded;
      case 'earthquake': return Icons.vibration_rounded;
      default: return Icons.emergency_rounded;
    }
  }
}
