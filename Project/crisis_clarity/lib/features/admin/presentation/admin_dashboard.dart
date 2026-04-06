import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../alerts/domain/alert_model.dart';
import '../data/admin_repository.dart';
import '../../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());

final allAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllAlerts();
});

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(allAlertsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.dmSerifDisplay(fontSize: 24)),
      ),
      body: alertsAsync.when(
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No alerts found.'));
          }
          
          final totalUnderstood = alerts.fold(0, (sum, a) => sum + a.understood);
          final totalNotUnderstood = alerts.fold(0, (sum, a) => sum + a.notUnderstood);
          final avgComprehension = (totalUnderstood + totalNotUnderstood) > 0 
              ? (totalUnderstood / (totalUnderstood + totalNotUnderstood) * 100).toStringAsFixed(1)
              : '0';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(alerts.length, avgComprehension),
                const SizedBox(height: 32),
                Text('ALERT FEEDBACK', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
                const SizedBox(height: 16),
                _buildOverallComprehensionChart(totalUnderstood, totalNotUnderstood, avgComprehension),
                const SizedBox(height: 32),
                Text('ALL ALERTS', style: GoogleFonts.dmSerifDisplay(fontSize: 20)),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) => _buildAlertItem(alerts[index]),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/create-alert'),
        backgroundColor: AppTheme.primaryRed,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsGrid(int total, String avg) {
    return Row(
      children: [
        _buildStatCard('Total Alerts', total.toString(), Icons.emergency_rounded, AppTheme.primaryRed),
        const SizedBox(width: 16),
        _buildStatCard('Avg. Clarity', '$avg%', Icons.bar_chart_rounded, AppTheme.secondaryTeal),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallComprehensionChart(int understood, int notUnderstood, String avg) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(color: AppTheme.secondaryTeal, value: understood.toDouble(), title: '', radius: 25),
                PieChartSectionData(color: AppTheme.primaryRed, value: notUnderstood.toDouble(), title: '', radius: 15),
              ],
              centerSpaceRadius: 60,
              sectionsSpace: 4,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$avg%', style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: AppTheme.secondaryTeal)),
                const Text('Understood', style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(AlertModel alert) {
    final totalResponse = alert.understood + alert.notUnderstood;
    final rate = totalResponse > 0 ? (alert.understood / totalResponse) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.titleEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: rate,
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                  color: AppTheme.secondaryTeal,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text('${(rate * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryTeal)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$totalResponse total responses', style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}
