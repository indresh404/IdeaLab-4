import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:crisis_clarity/components/user/post.dart';
import 'package:crisis_clarity/components/user/ai_chat_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crisis_clarity/features/alerts/providers/alert_provider.dart';
import 'package:crisis_clarity/features/alerts/domain/alert_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — filters + posts. Header/analytics live in UserPage.
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  final Future<void> Function() onRefresh;
  final bool isRefreshing;
  final Widget? analyticsCard;

  const HomeScreen({
    super.key,
    required this.onRefresh,
    required this.isRefreshing,
    this.analyticsCard,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedLocation = 0;
  int _selectedSeverity = 0;
  late final AnimationController _staggerCtrl;

  static const _locations = ['Mumbai', 'Thane', 'Palghar', 'Raigad', 'Nashik'];
  static const _severityFilters = [
    _SF('All',      null),
    _SF('Critical', SeverityLevel.red),
    _SF('Severe',   SeverityLevel.orange),
    _SF('Moderate', SeverityLevel.yellow),
    _SF('Info',     SeverityLevel.green),
  ];

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (old.key != widget.key) _staggerCtrl.forward(from: 0);
  }

  @override
  void dispose() { _staggerCtrl.dispose(); super.dispose(); }

  List<Post> _mapAlertsToPosts(List<AlertModel> alerts) {
    return alerts.map((a) {
      final severityStr = a.severity.toLowerCase();
      final severity = severityStr == 'critical' ? SeverityLevel.red : 
                       severityStr == 'high' ? SeverityLevel.orange : 
                       severityStr == 'medium' ? SeverityLevel.yellow : SeverityLevel.green;
      
      return Post(
        id: a.id,
        username: 'Emergency Alert',
        userAvatar: '', 
        userRole: 'Official',
        location: a.affectedZones.join(', '),
        timeAgo: 'Just now', 
        severity: severity,
        title: a.titleEn,
        content: a.descriptionEn,
        isPinned: severityStr == 'critical',
      );
    }).toList();
  }

  List<Post> _getFiltered(List<Post> posts) {
    if (_selectedSeverity == 0) return posts;
    final lvl = _severityFilters[_selectedSeverity].level;
    return posts.where((p) => p.severity == lvl).toList();
  }

  // ── Open Ask AI mini bottom-sheet, then slide up to full chat ─────────────
  void _showAIChat(Post post) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => _AskAIMiniSheet(
        post: post,
        onOpenFullChat: () {
          Navigator.pop(context); // close sheet
          _openFullChat(post);
        },
      ),
    );
  }

  void _openFullChat(Post post) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => AIChatScreen(post: post),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(activeAlertsProvider);
    
    return alertsAsync.when(
      data: (alerts) {
        final allPosts = _mapAlertsToPosts(alerts);
        // Combine with default hardcoded posts if needed, or just real alerts
        final posts = _getFiltered(allPosts.isEmpty ? _posts : allPosts);
        
        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: AppTheme.primaryRed,
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 60,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              if (widget.analyticsCard != null)
                SliverToBoxAdapter(child: widget.analyticsCard!),
              SliverToBoxAdapter(child: _buildLiveBanner()),
              SliverToBoxAdapter(child: _buildFilterCard()),
              SliverToBoxAdapter(child: _buildSectionHeader()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (_, i) => _PostCard(
                    key: ValueKey(posts[i].id),
                    post: posts[i],
                    index: i,
                    staggerCtrl: _staggerCtrl,
                    onAIChat: () => _showAIChat(posts[i]),
                  ),
                  childCount: posts.length,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Error: $e')),
    );
  }

  // ── Live banner ───────────────────────────────────────────────────────────
  Widget _buildLiveBanner() {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppTheme.primaryRed, AppTheme.primaryRed.withOpacity(0.82)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          _PulseDot(),
          const SizedBox(width: 10),
          const Expanded(child: Text('3 Active Alerts in your area — tap to view',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 13),
        ]),
      ),
    );
  }

  // ── Filter card ───────────────────────────────────────────────────────────
  Widget _buildFilterCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _filterLabel(Icons.location_on_rounded, 'Location'),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _locations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _LocationChip(
              label: _locations[i],
              isSelected: _selectedLocation == i,
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedLocation = i); },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Divider(color: Colors.grey[100], height: 1),
        const SizedBox(height: 14),
        _filterLabel(Icons.warning_rounded, 'Severity'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(_severityFilters.length, (i) => _SevChip(
            filter: _severityFilters[i],
            isSelected: _selectedSeverity == i,
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedSeverity = i); },
          )),
        ),
      ]),
    );
  }

  Widget _filterLabel(IconData icon, String label) => Row(children: [
    Icon(icon, size: 15, color: Colors.grey[600]),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
  ]);

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Today's Updates",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          Text('Real-time crisis information',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
        const Spacer(),
        _LiveLabel(),
      ]),
    );
  }

  // ── Posts ─────────────────────────────────────────────────────────────────
  static final List<Post> _posts = [
    Post(id: '1', username: 'NDRF Official',
        userAvatar: 'https://ui-avatars.com/api/?name=NDRF&background=FF0000&color=fff',
        userRole: 'Admin', location: 'Chembur, Mumbai', timeAgo: '15 mins ago',
        severity: SeverityLevel.red,
        title: '🚨 URGENT: Evacuation Required in Low-Lying Areas',
        content: 'The NDRF has issued an immediate evacuation order for residents in low-lying areas of Chembur, Kurla, and parts of Dharavi. Water levels are expected to reach 4-5 feet within 2 hours. Emergency shelters at Chembur Gymkhana and Kurla Municipal School.',
        feedbackCount: 234, hasNotification: true, isPinned: true),
    Post(id: '2', username: 'Mumbai Police',
        userAvatar: 'https://ui-avatars.com/api/?name=Police&background=0D47A1&color=fff',
        userRole: 'Verified', location: 'South Mumbai', timeAgo: '32 mins ago',
        severity: SeverityLevel.orange,
        title: '⚠️ Traffic Advisory: Multiple Roads Closed',
        content: 'Marine Drive, Peddar Road, JJ Flyover and Eastern Freeway are closed due to heavy rainfall. BEST has arranged additional buses on Western Express Highway.',
        feedbackCount: 156, hasNotification: true, isPinned: false),
    Post(id: '3', username: 'BMC Disaster Management',
        userAvatar: 'https://ui-avatars.com/api/?name=BMC&background=2E7D32&color=fff',
        userRole: 'Official', location: 'Andheri East', timeAgo: '1 hr ago',
        severity: SeverityLevel.yellow,
        title: '🌧️ Waterlogging Update: Pumps Deployed',
        content: 'BMC deployed 45 high-capacity pumps across waterlogging-prone areas. Andheri subway water level reducing. Hindmata cleared. Dadar TT still slow — avoid if possible.',
        feedbackCount: 89, hasNotification: false, isPinned: false),
    Post(id: '4', username: 'Indian Meteorological Dept',
        userAvatar: 'https://ui-avatars.com/api/?name=IMD&background=F57F17&color=fff',
        userRole: 'Government', location: 'Regional Office, Mumbai', timeAgo: '2 hrs ago',
        severity: SeverityLevel.green,
        title: '📊 Weather Update: Rainfall to Decrease',
        content: 'IMD forecasts rainfall intensity will decrease over 6-8 hours. Arabian Sea depression moving away. Orange alert remains for Mumbai, Thane, Palghar. Wind 45-55 km/h.',
        feedbackCount: 412, hasNotification: false, isPinned: false),
    Post(id: '5', username: 'Railway Ministry',
        userAvatar: 'https://ui-avatars.com/api/?name=Rail&background=6A1B9A&color=fff',
        userRole: 'Official', location: 'Central Railway HQ', timeAgo: '3 hrs ago',
        severity: SeverityLevel.yellow,
        title: '🚆 Train Services: Schedule Updates',
        content: 'Central Line: 20-25 min delay. Harbour line: 15 min. Western Line Churchgate–Virar: 15 min delay. 150 additional BEST buses on major routes.',
        feedbackCount: 278, hasNotification: true, isPinned: false),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulse dot
// ─────────────────────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  @override State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  late final Animation<double> _a = Tween(begin: 0.4, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(width: 9, height: 9,
      decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(_a.value),
          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 5 * _a.value)]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Live label
// ─────────────────────────────────────────────────────────────────────────────
class _LiveLabel extends StatefulWidget {
  @override State<_LiveLabel> createState() => _LiveLabelState();
}
class _LiveLabelState extends State<_LiveLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  late final Animation<double> _a = Tween(begin: 0.5, end: 1.0)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2 * _a.value)),
      ),
      child: Row(children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(
            shape: BoxShape.circle, color: AppTheme.primaryRed.withOpacity(_a.value))),
        const SizedBox(width: 5),
        const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
            color: AppTheme.primaryRed, letterSpacing: 0.5)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter helpers
// ─────────────────────────────────────────────────────────────────────────────
class _SF {
  final String label; final SeverityLevel? level;
  const _SF(this.label, this.level);
}

class _LocationChip extends StatelessWidget {
  final String label; final bool isSelected; final VoidCallback onTap;
  const _LocationChip({required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryRed : Colors.grey[50],
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[200]!),
        boxShadow: isSelected ? [BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.grey[700],
      )),
    ),
  );
}

class _SevChip extends StatelessWidget {
  final _SF filter; final bool isSelected; final VoidCallback onTap;
  const _SevChip({required this.filter, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = filter.level?.color ?? Colors.grey[600]!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey[50],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isSelected ? color.withOpacity(0.45) : Colors.grey[200]!,
              width: isSelected ? 1.5 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(
              shape: BoxShape.circle, color: isSelected ? color : Colors.grey[400])),
          const SizedBox(width: 6),
          Text(filter.label, style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? color : Colors.grey[600])),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post card
// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Post post; final int index;
  final AnimationController staggerCtrl; final VoidCallback onAIChat;
  const _PostCard({super.key, required this.post, required this.index,
    required this.staggerCtrl, required this.onAIChat});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.12).clamp(0.0, 0.75);
    return AnimatedBuilder(
      animation: staggerCtrl,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(
            ((staggerCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Opacity(opacity: t,
            child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: post.severity.color.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 7, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 4, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                post.severity.color, post.severity.color.withOpacity(0.3)]),
            )),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _UserRow(post: post),
                const SizedBox(height: 11),
                _SevBadge(post: post),
                const SizedBox(height: 9),
                Text(post.title, style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.3, letterSpacing: -0.2)),
                const SizedBox(height: 7),
                Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
                const SizedBox(height: 13),
                Divider(color: Colors.grey[100], height: 1),
                const SizedBox(height: 11),
                _ActionRow(post: post, onAIChat: onAIChat),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User row
// ─────────────────────────────────────────────────────────────────────────────
class _UserRow extends StatelessWidget {
  final Post post;
  const _UserRow({required this.post});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 40, height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: post.severity.color.withOpacity(0.3), width: 2)),
      child: ClipOval(child: Image.network(post.userAvatar,
          errorBuilder: (_, __, ___) => CircleAvatar(
            backgroundColor: post.severity.color.withOpacity(0.18),
            child: Text(post.username[0], style: TextStyle(
                color: post.severity.color, fontWeight: FontWeight.bold, fontSize: 16)),
          ))),
    ),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Flexible(child: Text(post.username,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 6),
        _RoleBadge(role: post.userRole, color: post.severity.color),
      ]),
      const SizedBox(height: 2),
      Row(children: [
        Icon(Icons.location_on, size: 10, color: Colors.grey[400]),
        const SizedBox(width: 2),
        Flexible(child: Text(post.location,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Icon(Icons.access_time, size: 10, color: Colors.grey[400]),
        const SizedBox(width: 2),
        Text(post.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
    ])),
    if (post.isPinned) Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: post.severity.color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(Icons.push_pin, size: 13, color: post.severity.color),
    ),
  ]);
}

class _SevBadge extends StatelessWidget {
  final Post post;
  const _SevBadge({required this.post});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: post.severity.color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: post.severity.color.withOpacity(0.22)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.warning_amber_rounded, size: 11, color: post.severity.color),
      const SizedBox(width: 4),
      Text(post.severity.label.toUpperCase(), style: TextStyle(
          fontSize: 9.5, fontWeight: FontWeight.w800,
          color: post.severity.color, letterSpacing: 0.5)),
    ]),
  );
}

class _RoleBadge extends StatelessWidget {
  final String role; final Color color;
  const _RoleBadge({required this.role, required this.color});
  @override
  Widget build(BuildContext context) {
    final auth = ['Admin', 'Official', 'Government', 'Verified'].contains(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: auth ? color.withOpacity(0.12) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role, style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: auth ? color : Colors.blue[700], letterSpacing: 0.2)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row
// ─────────────────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final Post post; final VoidCallback onAIChat;
  const _ActionRow({required this.post, required this.onAIChat});

  @override
  Widget build(BuildContext context) => Row(children: [
    _ActBtn(icon: Icons.thumb_up_outlined, label: '${post.feedbackCount}',
        color: Colors.grey[600]!,
        onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
              _snack('Feedback recorded', post.severity.color));
        }),
    const SizedBox(width: 6),
    _ActBtn(
        icon: post.hasNotification ? Icons.notifications_active : Icons.notifications_none_rounded,
        label: post.hasNotification ? 'On' : 'Off',
        color: post.hasNotification ? post.severity.color : Colors.grey[500]!,
        onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
              _snack('Notifications updated', post.severity.color));
        }),
    const Spacer(),
    _AskAIButton(post: post, onTap: onAIChat),
  ]);

  SnackBar _snack(String msg, Color color) => SnackBar(
    content: Text(msg, style: const TextStyle(fontSize: 13)),
    duration: const Duration(seconds: 2),
    backgroundColor: color, behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
  );
}

class _ActBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Ask AI shimmer button
// ─────────────────────────────────────────────────────────────────────────────
class _AskAIButton extends StatefulWidget {
  final Post post; final VoidCallback onTap;
  const _AskAIButton({required this.post, required this.onTap});
  @override State<_AskAIButton> createState() => _AskAIButtonState();
}
class _AskAIButtonState extends State<_AskAIButton> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  @override void dispose() { _shimmer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.post.severity.color;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.72), color],
              stops: [0.0, _shimmer.value, 1.0],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: color.withOpacity(0.3 + 0.18 * _shimmer.value),
                blurRadius: 10 + 5 * _shimmer.value, offset: const Offset(0, 3))],
          ),
          child: child,
        ),
        child: Row(children: [
            const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          const Text('  Ask AI', style: TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ask AI Mini Sheet — slides up from bottom
// ─────────────────────────────────────────────────────────────────────────────
class _AskAIMiniSheet extends StatefulWidget {
  final Post post; final VoidCallback onOpenFullChat;
  const _AskAIMiniSheet({required this.post, required this.onOpenFullChat});
  @override State<_AskAIMiniSheet> createState() => _AskAIMiniSheetState();
}

class _AskAIMiniSheetState extends State<_AskAIMiniSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 480))..forward();
  late final Animation<double> _scale = Tween(begin: 0.93, end: 1.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  late final Animation<double> _fade =
  CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  static const _quickOpts = [
    _Opt('🏠', 'Nearest Shelters',   Color(0xFF4CAF50)),
    _Opt('🆘', 'Safety Tips',        Color(0xFFFF9800)),
    _Opt('📞', 'Emergency Contacts', Color(0xFF2196F3)),
    _Opt('🚗', 'Evacuation Routes',  Color(0xFF9C27B0)),
  ];

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.post.severity.color;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E16),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(margin: const EdgeInsets.only(top: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                // Lottie AI avatar
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [color.withOpacity(0.38), color.withOpacity(0.12)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                  ),
                  child: ClipOval(child: Lottie.asset(
                      'assets/animations/ai_loading.json', repeat: true, fit: BoxFit.cover)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Crisis AI Assistant', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 3),
                  Text(
                    widget.post.title.length > 42
                        ? '${widget.post.title.substring(0, 42)}…'
                        : widget.post.title,
                    style: TextStyle(fontSize: 11.5, color: color.withOpacity(0.85)),
                  ),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white54, size: 16),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.07), height: 1),
            const SizedBox(height: 16),

            // "What do you want to know?" label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('What do you want to know?',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.42))),
              ),
            ),
            const SizedBox(height: 12),

            // 2×2 quick option grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 3.1,
                children: _quickOpts.map((o) =>
                    _QuickTile(opt: o, onTap: widget.onOpenFullChat)).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Open full chat CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: GestureDetector(
                onTap: widget.onOpenFullChat,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.72)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                        color: color.withOpacity(0.42), blurRadius: 20, offset: const Offset(0, 7))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: 10),
                    const Text('Open Full AI Chat', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: -0.2)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick tile
// ─────────────────────────────────────────────────────────────────────────────
class _QuickTile extends StatefulWidget {
  final _Opt opt; final VoidCallback onTap;
  const _QuickTile({required this.opt, required this.onTap});
  @override State<_QuickTile> createState() => _QuickTileState();
}
class _QuickTileState extends State<_QuickTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) { HapticFeedback.selectionClick(); setState(() => _pressed = true); },
    onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: widget.opt.color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.opt.color.withOpacity(0.22)),
        ),
        child: Row(children: [
          Text(widget.opt.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.opt.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: widget.opt.color.withOpacity(0.9)),
              overflow: TextOverflow.ellipsis)),
        ]),
      ),
    ),
  );
}

class _Opt {
  final String icon, label; final Color color;
  const _Opt(this.icon, this.label, this.color);
}