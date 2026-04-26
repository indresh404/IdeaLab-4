import 'package:flutter/material.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:lottie/lottie.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crisis_clarity/features/alerts/providers/alert_provider.dart';

class AlertSection extends ConsumerStatefulWidget {
  const AlertSection({super.key});

  @override
  ConsumerState<AlertSection> createState() => _AlertSectionState();
}

class _AlertSectionState extends ConsumerState<AlertSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streamingAlerts = ref.watch(streamingAlertsProvider);
    final alertsAsync = ref.watch(activeAlertsProvider);

    // Combine streaming alerts with existing alerts
    final apiAlerts = alertsAsync.maybeWhen(
      data: (alerts) => alerts,
      orElse: () => [],
    );

    final bool hasData = streamingAlerts.isNotEmpty || apiAlerts.isNotEmpty;

    if (!hasData) {
      return _buildWaitingState();
    }

    // Replay stagger when new alerts arrive
    if (_staggerCtrl.isCompleted) {
      _staggerCtrl.forward(from: 0);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: streamingAlerts.length + apiAlerts.length,
        itemBuilder: (context, index) {
          if (index < streamingAlerts.length) {
            return _buildStreamingAlertCard(
                streamingAlerts[index], index);
          }
          final alert = apiAlerts[index - streamingAlerts.length];
          return _buildApiAlertCard(alert, index);
        },
      ),
    );
  }

  Widget _buildStreamingAlertCard(Map<String, dynamic> alert, int index) {
    final severity = (alert['severity'] ?? 'medium').toString().toUpperCase();
    final isUrgent = severity == 'HIGH' || severity == 'CRITICAL';
    final color = isUrgent ? AppTheme.primaryRed : Colors.orange;
    final timeAgo = alert['timeAgo'] ?? 'Just now';

    final delay = (index * 0.12).clamp(0.0, 0.75);

    return AnimatedBuilder(
      animation: _staggerCtrl,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(
            ((_staggerCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
              offset: Offset(30 * (1 - t), 0), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isUrgent
                  ? AppTheme.primaryRed.withOpacity(0.4)
                  : Colors.grey[200]!,
              width: isUrgent ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.3)]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Icon(_getIcon(alert['disaster_type']),
                            color: color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert['title'] ?? 'Alert',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            Row(children: [
                              Text(
                                  (alert['location'] is Map)
                                      ? alert['location']['city'] ?? 'Mumbai'
                                      : 'Mumbai',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryRed,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('• $timeAgo',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                            ]),
                          ],
                        ),
                      ),
                      if (isUrgent) _UrgentPulse(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(alert['summary'] ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _Badge(severity, color),
                    const SizedBox(width: 8),
                    _Badge(
                        alert['trust_label'] ?? 'VERIFIED', Colors.green),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiAlertCard(dynamic alert, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(alert.titleEn,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(alert.descriptionEn, maxLines: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle),
          child:
              const Icon(Icons.warning, color: AppTheme.primaryRed, size: 20),
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'flood':
        return Icons.water_drop;
      case 'fire':
        return Icons.local_fire_department;
      case 'storm':
        return Icons.cyclone;
      case 'earthquake':
        return Icons.landscape;
      case 'heatwave':
        return Icons.thermostat;
      case 'industrial accident':
        return Icons.factory;
      case 'accident':
        return Icons.car_crash;
      case 'health emergency':
        return Icons.medical_services;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Widget _buildWaitingState() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: Lottie.asset('assets/animations/alert_loading.json',
                  fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            const Text('Scanning for live alerts...',
                style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('New alerts will appear one by one',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                color: AppTheme.primaryRed,
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3)),
      );
}

class _UrgentPulse extends StatefulWidget {
  @override
  State<_UrgentPulse> createState() => _UrgentPulseState();
}

class _UrgentPulseState extends State<_UrgentPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 0.5, end: 1.0).animate(_c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Text('URGENT',
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRed)),
        ),
      );
}