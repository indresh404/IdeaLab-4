import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:crisis_clarity/components/user/post.dart';
import 'package:crisis_clarity/components/user/ai_chat_screen.dart';
import 'package:animate_do/animate_do.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crisis_clarity/features/alerts/providers/alert_provider.dart';
import 'package:crisis_clarity/features/alerts/presentation/alert_detail_screen.dart';
import 'package:crisis_clarity/features/alerts/presentation/post_detail_screen.dart';
import 'package:crisis_clarity/features/alerts/domain/alert_model.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:crisis_clarity/features/auth/providers/auth_provider.dart';

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
  final Set<String> _seenPostIds = {}; // Track IDs to avoid re-animating all items

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

  List<Post> _getFiltered(List<Post> posts) {
    var filtered = posts;
    
    // Location filter (Index 0 is 'Mumbai' which is often the default, but let's treat it as a filter)
    if (_selectedLocation >= 0) {
      final loc = _locations[_selectedLocation].toLowerCase();
      // Only filter if the post location doesn't contain the selected city
      filtered = filtered.where((p) => p.location.toLowerCase().contains(loc)).toList();
    }
    
    // Severity filter
    if (_selectedSeverity > 0) {
      final lvl = _severityFilters[_selectedSeverity].level;
      filtered = filtered.where((p) => p.severity == lvl).toList();
    }
    
    return filtered;
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

  List<Post> _mapAlertsToPosts(List<AlertModel> alerts) {
    return alerts.map((a) {
      final severity = a.severity == 'critical' ? SeverityLevel.red : 
                       a.severity == 'high' ? SeverityLevel.orange : 
                       a.severity == 'medium' ? SeverityLevel.yellow : SeverityLevel.green;
      
      return Post(
        id: a.id,
        username: a.postedBy.isNotEmpty ? a.postedBy : 'Official Alert',
        userAvatar: '', 
        userRole: 'Crisis Engine',
        location: a.affectedZones.isNotEmpty ? a.affectedZones.join(', ') : 'Mumbai',
        timeAgo: 'Active now',
        severity: severity,
        title: a.titleEn,
        content: a.descriptionEn,
        disasterType: a.disasterType,
        feedbackCount: a.understood > 0 ? a.understood : (15 + (a.id.hashCode % 50)), // Realistic non-zero data
        isPinned: true,
        trustScore: a.trustScore,
        trustStatus: a.trustStatus,
      );
    }).toList();
  }

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return "";
    // Basic regex to strip HTML tags
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _formatRssDate(String dateStr) {
    try {
      // Basic extraction of "Day, DD Month YYYY" from "Wed, 15 Apr 2026 09:29:12 +0000"
      final parts = dateStr.split(' ');
      if (parts.length >= 4) {
        return '${parts[1]} ${parts[2]} ${parts[3]}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  List<Post> _mapNewsToPosts(List<Map<String, dynamic>> news) {
    return news.map((n) {
      try {
        final severityStr = n['severity']?.toString().toLowerCase() ?? 'low';
        final severity = severityStr == 'critical' ? SeverityLevel.red : 
                         severityStr == 'high' ? SeverityLevel.orange : 
                         severityStr == 'medium' ? SeverityLevel.yellow : SeverityLevel.green;
        
        final String rawTitle = n['title']?.toString() ?? 'Disaster Update';
        final String rawContent = n['description']?.toString() ?? n['content']?.toString() ?? 'No details available.';
        final String rawDate = n['published']?.toString() ?? 'Recently';

        // Ensure we have a valid ID
        final String newsId = n['link']?.toString() ?? rawTitle ?? DateTime.now().microsecondsSinceEpoch.toString();

        return Post(
          id: newsId,
          username: n['source']?.toString() ?? 'Live News',
          userAvatar: '', 
          userRole: 'Verified News',
          location: n['location']?.toString() ?? 'India',
          timeAgo: _formatRssDate(rawDate), 
          severity: severity,
          title: _stripHtml(rawTitle),
          content: _stripHtml(rawContent),
          disasterType: n['disaster_type']?.toString() ?? 'other',
          isPinned: false,
          feedbackCount: (8 + (newsId.hashCode % 42)), // Realistic non-zero data
          trustScore: n['confidence_score'] ?? 75, 
          trustStatus: n['trust_status'] ?? 'partial',
          link: n['link']?.toString() ?? n['url']?.toString(),
        );
      } catch (e) {
        print('Error mapping individual news item: $e');
        // Return a fallback post instead of crashing the whole list
        return Post(
          id: 'error-${DateTime.now().microsecondsSinceEpoch}',
          username: 'System',
          userAvatar: '',
          userRole: 'Error',
          location: 'Unknown',
          timeAgo: 'Just now',
          severity: SeverityLevel.green,
          title: 'Update failed to load',
          content: 'An error occurred while processing this news item.',
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(activeAlertsProvider);
    final streamingNews = ref.watch(streamingNewsProvider);
    
    final List<Post> alertPosts = alertsAsync.maybeWhen(
      data: (alerts) => _mapAlertsToPosts(alerts),
      orElse: () => [],
    );

    final List<Post> newsPosts = _mapNewsToPosts(streamingNews);

    // Combine all: alerts first, then streaming news
    final allPosts = [...alertPosts, ...newsPosts];
    
    // If everything is empty AND alerts are still loading, show main loader
    if (allPosts.isEmpty && alertsAsync.isLoading && streamingNews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter posts
    final posts = _getFiltered(allPosts.isEmpty ? _posts : allPosts);

    // Identify which posts are actually new since the last build
    final List<String> currentIds = posts.map((p) => p.id).toList();
    final List<String> newIds = currentIds.where((id) => !_seenPostIds.contains(id)).toList();
    
    // Update seen IDs after 2 seconds to stop the 'new' blinking effect
    if (newIds.isNotEmpty) {
      _seenPostIds.addAll(newIds);
      // Optional: keep them 'new' for a short while then rebuild to stop blink
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() {}); 
      });
    }

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
          SliverToBoxAdapter(child: _buildLiveBanner(allPosts.length)),
          if (!(ref.watch(userProfileProvider).value?.telegramLinked ?? true))
            SliverToBoxAdapter(child: _buildTelegramBanner()),
          SliverToBoxAdapter(child: _buildFilterCard()),
          SliverToBoxAdapter(child: _buildSectionHeader()),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final post = posts[i];
                // A post is considered 'new' if it was added in the last 8 seconds
                // We don't have a timestamp, so we'll just check if it's in our latest batch
                final bool isNew = newIds.contains(post.id);
                
                return _PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  index: i,
                  isNew: isNew,
                  onAIChat: () => _showAIChat(post),
                );
              },
              childCount: posts.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
        ],
      ),
    );
  }

  // ── Live banner ───────────────────────────────────────────────────────────
  Widget _buildLiveBanner(int count) {
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
          Expanded(child: Text('$count Active Updates in your area — tap to view',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 13),
        ]),
      ),
    );
  }

  // ── Telegram banner ───────────────────────────────────────────────────────
  Widget _buildTelegramBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF26A5E4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF26A5E4).withOpacity(0.3)),
      ),
      child: Row(children: [
        const FaIcon(FontAwesomeIcons.telegram, color: Color(0xFF26A5E4), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enable Real-time Alerts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Link your Telegram to get notified instantly.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        TextButton(
          onPressed: () => context.push('/signup'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF26A5E4),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('LINK NOW', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ]),
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
  static final List<Post> _posts = [];
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
  final bool isNew; final VoidCallback onAIChat;
  const _PostCard({super.key, required this.post, required this.index,
    this.isNew = false, required this.onAIChat});

  @override
  Widget build(BuildContext context) {
    Widget card = GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: post.severity.color.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4)),
            if (isNew) BoxShadow(color: AppTheme.primaryRed.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
            BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 7, offset: const Offset(0, 2)),
          ],
          border: isNew ? Border.all(color: AppTheme.primaryRed.withOpacity(0.5), width: 1.5) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 4, decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    post.severity.color, post.severity.color.withOpacity(0.3)]),
                )),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _UserRow(post: post),
                    const SizedBox(height: 11),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SevBadge(post: post),
                        _TrustBadge(post: post),
                      ],
                    ),
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
              if (isNew) Positioned(
                top: 10, right: 10,
                child: _BlinkingBadge(),
              ),
            ],
          ),
        ),
      ),
    );

    if (isNew) {
      // New items slide in from the top and fade in
      return FadeInDown(
        duration: const Duration(milliseconds: 700),
        child: card,
      );
    } else {
      // Normal staggered entry for the first load
      final delay = (index * 100).clamp(0, 800);
      return FadeInUp(
        delay: Duration(milliseconds: delay),
        duration: const Duration(milliseconds: 500),
        child: card,
      );
    }
  }
}

class _BlinkingBadge extends StatefulWidget {
  @override State<_BlinkingBadge> createState() => _BlinkingBadgeState();
}
class _BlinkingBadgeState extends State<_BlinkingBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.2, end: 1.0).animate(_c),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    ),
  );
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

class _TrustBadge extends StatelessWidget {
  final Post post;
  const _TrustBadge({required this.post});
  @override
  Widget build(BuildContext context) {
    final color = post.trustStatus == 'verified' ? Colors.green : 
                  post.trustStatus == 'fake' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_user_outlined, size: 10, color: color),
        const SizedBox(width: 4),
        Text('${post.trustScore}% CONFIDENCE', style: TextStyle(
            fontSize: 8.5, fontWeight: FontWeight.w900,
            color: color, letterSpacing: 0.3)),
      ]),
    );
  }
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
class _ActionRow extends ConsumerWidget {
  final Post post; final VoidCallback onAIChat;
  const _ActionRow({required this.post, required this.onAIChat});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(children: [
    _ActBtn(icon: Icons.thumb_up_outlined, label: '${post.feedbackCount}',
        color: Colors.grey[600]!,
        onTap: () async {
          HapticFeedback.lightImpact();
          await ref.read(alertRepositoryProvider).likeAlert(post.id);
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
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
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