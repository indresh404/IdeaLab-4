import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/alert_provider.dart';
import 'widgets/alert_card.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final alertsAsync = ref.watch(activeAlertsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom Premium App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryRed,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'CrisisClarity',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(Icons.security_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Hello, ${userProfile?.name.split(' ')[0] ?? 'User'} 👋',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Stay safe in ${userProfile?.location ?? 'Mumbai'} today.',
                    style: GoogleFonts.outfit(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Safety Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryTeal,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryTeal.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.check_circle_rounded, color: AppTheme.secondaryTeal),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Status: SAFE',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'No immediate threats in your zone.',
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Actions Row
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction(context, Icons.phone_in_talk_rounded, 'Emergency', Colors.amber),
                      _buildQuickAction(context, Icons.map_rounded, 'Shelters', Colors.blue),
                      _buildQuickAction(context, Icons.medical_services_rounded, 'First Aid', Colors.green),
                      _buildQuickAction(context, Icons.info_outline_rounded, 'Tips', Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Alerts Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Alerts',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Alerts List
          alertsAsync.when(
            data: (alerts) {
              if (alerts.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AlertCard(alert: alerts[index]),
                  childCount: alerts.length,
                ),
              );
            },
            loading: () => _buildLoadingState(), // Fixed: Don't wrap a sliver in a SliverToBoxAdapter
            error: (e, __) => SliverToBoxAdapter(
              child: Center(child: Text('Error loading alerts: $e')),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          height: 60, width: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Lottie.asset('assets/animations/login.json', height: 150),
          const SizedBox(height: 16),
          Text(
            'No active alerts for your area.',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text('Stay safe!', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[50]!,
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            ),
          ),
          childCount: 2,
        ),
      ),
    );
  }
}
