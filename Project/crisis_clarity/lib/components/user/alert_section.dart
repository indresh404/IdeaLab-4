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

class _AlertSectionState extends ConsumerState<AlertSection> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Show loading for 5 seconds then switch to empty state
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(activeAlertsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: alertsAsync.when(
        data: (alerts) => alerts.isEmpty ? _buildEmptyState() : _buildAlertList(alerts),
        loading: () => _buildLoadingState(),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAlertList(List<dynamic> alerts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Card(
          child: ListTile(
            title: Text(alert.titleEn),
            subtitle: Text(alert.descriptionEn),
            leading: const Icon(Icons.warning, color: Colors.red),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: Lottie.asset(
            'assets/animations/alert_loading.json',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 54),
        const Text(
          'Checking for alerts...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 350,
          height: 350,
          child: Lottie.asset(
            'assets/animations/nothing_here_animation.json',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 26),
        const Text(
          'No Active Alerts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'There are no alerts in your area right now.\nStay safe and check back later.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}