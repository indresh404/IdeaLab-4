import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:crisis_clarity/features/auth/providers/auth_provider.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:crisis_clarity/components/user/home_screen.dart';
import 'package:crisis_clarity/components/user/alert_section.dart';
import 'package:crisis_clarity/components/user/update_section.dart';
import 'package:crisis_clarity/components/user/profile_section.dart';
import 'package:crisis_clarity/components/user/ai_chat_screen.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});
  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  // ── Loading / refresh ─────────────────────────────────────────────────────
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  static const _loadingMessages = [
    "Connecting to emergency services...",
    "Fetching real-time crisis data...",
    "Analyzing local threat levels...",
    "Loading safety alerts...",
    "Preparing your feed...",
    "Checking updates in your area...",
    "Calibrating emergency response...",
    "Loading community reports...",
  ];
  int _msgIndex = 0;
  Timer? _msgTimer;

  // ── Nav bounce ────────────────────────────────────────────────────────────
  late final List<AnimationController> _bounceCtrl;
  late final List<Animation<double>> _bounceAnim;

  // ── Glow ──────────────────────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // ── Lottie AI FAB ─────────────────────────────────────────────────────────
  late final AnimationController _lottieCtrl;
  Timer? _lottieTimer;
  bool _isLottiePlaying = false;
  final _rng = Random();

  // ── Pulse for header badge ────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ── HomeScreen refresh key ────────────────────────────────────────────────
  int _homeRefreshKey = 0;

  static const _navItems = [
    _NavItem(Icons.home_rounded,               Icons.home_outlined,              'Home'),
    _NavItem(Icons.notifications_active_rounded, Icons.notifications_none_rounded, 'Alerts'),
    _NavItem(Icons.bolt_rounded,               Icons.bolt_outlined,              'Updates'),
    _NavItem(Icons.person_rounded,             Icons.person_outline_rounded,     'Profile'),
  ];

  @override
  void initState() {
    super.initState();

    // Bounce controllers
    _bounceCtrl = List.generate(4, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400)));
    _bounceAnim = _bounceCtrl.map((c) => TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0),  weight: 20),
    ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    // Glow
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowAnim = Tween(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Pulse
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Lottie FAB
    _lottieCtrl = AnimationController(vsync: this);
    _lottieCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _isLottiePlaying = false);
        _scheduleLottie();
      }
    });

    _bounceCtrl[0].forward();
    _startInitialLoad();
  }

  void _startInitialLoad() {
    _msgTimer = Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (_isInitialLoading && mounted) {
        setState(() => _msgIndex = (_msgIndex + 1) % _loadingMessages.length);
      }
    });
    Future.wait([
      Future.delayed(const Duration(seconds: 5)),
      _fetchData(),
    ]).then((_) {
      if (mounted) {
        _msgTimer?.cancel();
        setState(() => _isInitialLoading = false);
        _scheduleLottie();
      }
    });
  }

  void _scheduleLottie() {
    _lottieTimer?.cancel();
    _lottieTimer = Timer(Duration(seconds: 5 + _rng.nextInt(5)), () {
      if (mounted && _selectedIndex == 0) {
        setState(() => _isLottiePlaying = true);
        _lottieCtrl.forward(from: 0);
      } else {
        _scheduleLottie();
      }
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      _fetchData(),
    ]);
    if (mounted) {
      setState(() {
        _isRefreshing = false;
        _homeRefreshKey++;
      });
    }
  }

  Future<void> _fetchData() async =>
      Future.delayed(const Duration(milliseconds: 800));

  @override
  void dispose() {
    for (final c in _bounceCtrl) c.dispose();
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _lottieCtrl.dispose();
    _lottieTimer?.cancel();
    _msgTimer?.cancel();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (_selectedIndex == index) return;
    setState(() { _previousIndex = _selectedIndex; _selectedIndex = index; });
    _bounceCtrl[index].forward(from: 0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        extendBody: true,
        backgroundColor: const Color(0xFFF2F3F7),
        body: Column(children: [
          _UserHeader(
            pulseAnim: _pulseAnim,
            userName: ref.watch(userProfileProvider).value?.name ?? 'User',
          ),
          Expanded(
            child: _isInitialLoading ? _buildLoadingBody() : _buildPageBody(),
          ),
        ]),
        bottomNavigationBar: _isInitialLoading
            ? const SizedBox.shrink()
            : _buildBottomNav(),
      ),
      if (_isRefreshing) const _RefreshOverlay(),
    ]);
  }

  // ── Loading body ───────────────────────────────────────────────────────────
  Widget _buildLoadingBody() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Lottie.asset('assets/animations/home_loading.json',
              width: 300, height: 300, fit: BoxFit.contain),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: Text(_loadingMessages[_msgIndex],
              key: ValueKey(_msgIndex),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600,
                  color: AppTheme.primaryRed),
            ),
          ),
          const SizedBox(height: 6),
          Text('Please wait...', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      ),
    );
  }

  // ── Page body ──────────────────────────────────────────────────────────────
  Widget _buildPageBody() {
    final screens = [
      HomeScreen(
        key: ValueKey('home_$_homeRefreshKey'),
        onRefresh: _handleRefresh,
        isRefreshing: _isRefreshing,
        analyticsCard: const _AnalyticsCard(),
      ),
      const AlertSection(),
      const UpdateSection(),
      const ProfileSection(),
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, anim) {
        final forward = _selectedIndex > _previousIndex;
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(forward ? 0.06 : -0.06, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_selectedIndex), child: screens[_selectedIndex]),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
      child: SizedBox(
        height: 76,
        child: Stack(clipBehavior: Clip.none, children: [
          // Nav pill bar
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, child) => Container(
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryRed.withOpacity(0.45),
                      blurRadius: 28, spreadRadius: -4, offset: const Offset(0, 12)),
                  BoxShadow(color: AppTheme.primaryRed.withOpacity(_glowAnim.value * 0.28),
                      blurRadius: 48, spreadRadius: 2),
                ],
              ),
              child: child,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LayoutBuilder(builder: (_, constraints) {
                final slotW = constraints.maxWidth / 5;
                return Stack(children: [
                  // Sliding pill indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    left: _pillLeft(_selectedIndex, slotW),
                    top: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      width: slotW * 0.76, height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                    ),
                  ),
                  // Nav buttons
                  Row(children: [
                    _navBtn(0, slotW), // Home
                    _navBtn(1, slotW), // Alerts
                    SizedBox(width: slotW), // FAB gap
                    _navBtn(2, slotW), // Updates
                    _navBtn(3, slotW), // Profile
                  ]),
                ]);
              }),
            ),
          ),

          // ── Centred AI FAB ────────────────────────────────────────────────
          Positioned(
            top: -18, left: 0, right: 0,
            child: Center(
              child: _AiFab(
                lottieCtrl: _lottieCtrl,
                isPlaying: _isLottiePlaying,
                onTap: () => _openAIChat(),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // FAB opens full AIChatScreen with no post (generic mode)
  void _openAIChat() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const AIChatScreen(), // post = null → generic
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  double _pillLeft(int index, double slotW) {
    final slot = index < 2 ? index : index + 1;
    return slot * slotW + slotW * 0.12;
  }

  Widget _navBtn(int navIndex, double slotW) => SizedBox(
    width: slotW, height: 76,
    child: _NavButton(
      item: _navItems[navIndex],
      isSelected: _selectedIndex == navIndex,
      bounceAnim: _bounceAnim[navIndex],
      onTap: () => _onNavTap(navIndex),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// User header
// ─────────────────────────────────────────────────────────────────────────────
class _UserHeader extends StatelessWidget {
  final Animation<double> pulseAnim;
  final String userName;
  const _UserHeader({required this.pulseAnim, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRed,
            Color.lerp(AppTheme.primaryRed, Colors.deepOrange, 0.28)!],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.25),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                    blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Icon(Icons.emergency, color: AppTheme.primaryRed, size: 24),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hi, $userName', style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.4)),
                  Row(children: [
                    Icon(Icons.location_on, size: 10, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 3),
                    Text('Mumbai, Maharashtra',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85))),
                  ]),
                ]),
            const Spacer(),
            _HBtn(icon: Icons.search, onTap: () {}),
            const SizedBox(width: 8),
            Stack(children: [
              _HBtn(icon: Icons.notifications_outlined, onTap: () {}),
              Positioned(top: 8, right: 8,
                  child: AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, __) => Container(
                      width: 9, height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryRed, width: 2),
                        boxShadow: [BoxShadow(
                            color: Colors.white.withOpacity(0.7 * pulseAnim.value),
                            blurRadius: 4)],
                      ),
                    ),
                  )),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _HBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics card
// ─────────────────────────────────────────────────────────────────────────────
class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Crisis Analytics',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          const Spacer(),
          _SmChip(icon: Icons.calendar_today, label: '7 days'),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _StatTile(color: const Color(0xFFE53935), label: 'Critical', count: '12', trend: '+3'),
          _StatTile(color: const Color(0xFFFF6D00), label: 'Severe',   count: '24', trend: '+5'),
          _StatTile(color: const Color(0xFFFDD835), label: 'Moderate', count: '38', trend: '-2'),
          _StatTile(color: const Color(0xFF43A047), label: 'Info',     count: '45', trend: '+8'),
        ]),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(day: 'Mon', factor: 0.80, color: const Color(0xFFE53935)),
            _Bar(day: 'Tue', factor: 0.60, color: const Color(0xFFFF6D00)),
            _Bar(day: 'Wed', factor: 0.92, color: const Color(0xFFE53935)),
            _Bar(day: 'Thu', factor: 0.50, color: const Color(0xFFFDD835)),
            _Bar(day: 'Fri', factor: 0.70, color: const Color(0xFFFF6D00)),
            _Bar(day: 'Sat', factor: 0.40, color: const Color(0xFF43A047)),
            _Bar(day: 'Sun', factor: 0.28, color: const Color(0xFF43A047)),
          ],
        ),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final Color color; final String label, count, trend;
  const _StatTile({required this.color, required this.label,
    required this.count, required this.trend});
  @override
  Widget build(BuildContext context) {
    final up = trend.startsWith('+');
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: color, height: 1)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 9,
              color: up ? Colors.green[600] : Colors.red[400]),
          Text(trend.replaceAll(RegExp(r'[+-]'), ''),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: up ? Colors.green[600] : Colors.red[400])),
        ]),
      ]),
    ));
  }
}

class _Bar extends StatelessWidget {
  final String day; final double factor; final Color color;
  const _Bar({required this.day, required this.factor, required this.color});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        width: 24, height: 52 * factor,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [color.withOpacity(0.35), color]),
          borderRadius: BorderRadius.circular(7),
        ),
      ),
      const SizedBox(height: 4),
      Text(day, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w500)),
    ],
  );
}

class _SmChip extends StatelessWidget {
  final IconData icon; final String label;
  const _SmChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(icon, size: 11, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Refresh overlay
// ─────────────────────────────────────────────────────────────────────────────
class _RefreshOverlay extends StatelessWidget {
  const _RefreshOverlay();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.2),
                  blurRadius: 28, spreadRadius: 4)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Lottie.asset('assets/animations/main_loader.json',
                  width: 100, height: 100, fit: BoxFit.contain),
              const SizedBox(height: 4),
              Text('Refreshing...', style: TextStyle(fontSize: 12.5,
                  fontWeight: FontWeight.w600, color: Colors.grey[700])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI FAB — Lottie plays periodically, slide-up to full chat on tap
// ─────────────────────────────────────────────────────────────────────────────
class _AiFab extends StatelessWidget {
  final AnimationController lottieCtrl;
  final bool isPlaying;
  final VoidCallback onTap;
  const _AiFab({required this.lottieCtrl, required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80, height: 80,
        child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
          Container(
            width: 74, height: 74,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryRed.withOpacity(0.15), width: 2),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryRed.withOpacity(0.35),
                    blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 6)),
                const BoxShadow(color: Colors.white, blurRadius: 0, spreadRadius: 3),
              ],
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: isPlaying ? 0.0 : 1.0,
              child: Icon(Icons.smart_toy_rounded, color: AppTheme.primaryRed, size: 40),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 10),
              opacity: isPlaying ? 1.0 : 0.0,
              child: Lottie.asset(
                'assets/animations/ai_button.json',
                controller: lottieCtrl,
                width: 70, height: 70,
                fit: BoxFit.contain,
                onLoaded: (c) => lottieCtrl.duration = c.duration,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav button
// ─────────────────────────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final _NavItem item; final bool isSelected;
  final Animation<double> bounceAnim; final VoidCallback onTap;
  const _NavButton({required this.item, required this.isSelected,
    required this.bounceAnim, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: bounceAnim,
        builder: (_, child) => Transform.scale(scale: bounceAnim.value, child: child),
        child: Icon(
          isSelected ? item.filledIcon : item.outlinedIcon,
          size: isSelected ? 26 : 23,
          color: isSelected ? AppTheme.primaryRed : Colors.white.withOpacity(0.75),
        ),
      ),
      const SizedBox(height: 3),
      AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(
          fontSize: isSelected ? 11 : 10,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppTheme.primaryRed : Colors.white.withOpacity(0.75),
        ),
        child: Text(item.label),
      ),
    ]),
  );
}

class _NavItem {
  final IconData filledIcon, outlinedIcon; final String label;
  const _NavItem(this.filledIcon, this.outlinedIcon, this.label);
}