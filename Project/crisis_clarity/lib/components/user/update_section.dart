import 'package:flutter/material.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:lottie/lottie.dart';

class UpdateSection extends StatefulWidget {
  const UpdateSection({super.key});

  @override
  State<UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<UpdateSection> {
  bool _isLoading = true;
  bool _hasUpdates = false; // Set to true to show updates, false for empty state

  @override
  void initState() {
    super.initState();
    // Show loading for 5 seconds then switch to empty state
    // Change _hasUpdates to true if you want to show updates instead
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasUpdates = false; // Set to true to show updates
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingState()
          : _hasUpdates
          ? _buildUpdatesList()
          : _buildEmptyState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: Lottie.asset(
              'assets/animations/update_loading.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 54),
          const Text(
            'Fetching latest updates...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
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
            width: 350,
            height: 350,
            child: Lottie.asset(
              'assets/animations/nothing_here_animation.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'No Recent Updates',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'There are no new updates at the moment.\nCheck back later for the latest information on weather, traffic, and emergency services.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              // Simulate refresh
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasUpdates = false; // Set to true to show updates
                  });
                }
              });
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildUpdateCard(
          icon: Icons.water_drop,
          title: 'Waterlogging in parts of Mumbai',
          source: 'BMC Control Room',
          time: 'Just now',
          description: 'Waterlogging reported in Kurla, Sion, and Dadar areas. Water levels: Kurla Bridge - 2ft, Sion - 1.5ft. Traffic diverted. Pumps deployed.',
          isUrgent: true,
        ),
        const SizedBox(height: 12),
        _buildUpdateCard(
          icon: Icons.train,
          title: 'Local Train Updates',
          source: 'Western Railway',
          time: '5 mins ago',
          description: 'Trains running 20-25 mins late on Western line due to waterlogging near Bandra. Central line services delayed by 15 mins. Harbour line functioning normally.',
          isUrgent: false,
        ),
        const SizedBox(height: 12),
        _buildUpdateCard(
          icon: Icons.electrical_services,
          title: 'Power Outage',
          source: 'BEST',
          time: '15 mins ago',
          description: 'Power supply disrupted in parts of Bandra East and Khar due to technical fault. Restoration work in progress. Estimated restoration time: 2 hours.',
          isUrgent: true,
        ),
        const SizedBox(height: 12),
        _buildUpdateCard(
          icon: Icons.local_hospital,
          title: 'Medical Emergency Services',
          source: 'Health Department',
          time: '25 mins ago',
          description: 'All major hospitals on high alert. Additional ambulances deployed in flood-prone areas. Emergency helpline: 108 active 24/7.',
          isUrgent: false,
        ),
        const SizedBox(height: 12),
        _buildUpdateCard(
          icon: Icons.school,
          title: 'School & College Closures',
          source: 'Education Department',
          time: '1 hr ago',
          description: 'All schools and colleges in Mumbai to remain closed tomorrow. Online classes will continue. Exams scheduled for tomorrow postponed.',
          isUrgent: false,
        ),
        const SizedBox(height: 12),
        _buildUpdateCard(
          icon: Icons.traffic,
          title: 'Traffic Advisory',
          source: 'Traffic Police',
          time: '1.5 hrs ago',
          description: 'Avoid Western Express Highway due to waterlogging at Kherwadi. Alternate routes: JVLR and LBS Marg. Andheri subway closed.',
          isUrgent: true,
        ),
      ],
    );
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
        border: Border.all(
          color: isUrgent ? AppTheme.primaryRed : Colors.grey[200]!,
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? AppTheme.primaryRed.withOpacity(0.1)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isUrgent ? AppTheme.primaryRed : Colors.grey[600],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            source,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}