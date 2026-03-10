import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this import
import '../theme/app_theme.dart';
import 'login_page.dart';

// ─── DATA MODEL ──────────────────────────────────────────────────────────────

class _FeatureSlide {
  final String tag;
  final String headline;
  final String body;
  final IconData icon;
  final String lottieAsset;

  const _FeatureSlide({
    required this.tag,
    required this.headline,
    required this.body,
    required this.icon,
    required this.lottieAsset,
  });
}

// Updated with 5 features matching your requirements
const List<_FeatureSlide> _slides = [
  _FeatureSlide(
    tag: 'VERIFIED ALERTS',
    headline: 'Only Authorized\nEmergency Alerts',
    body:
    'Only disaster management authorities can publish alerts. Citizens receive accurate, verified information — eliminating rumors and misinformation during crises.',
    icon: Icons.verified_user_rounded,
    lottieAsset: 'assets/animations/login_animation_1.json',
  ),
  _FeatureSlide(
    tag: 'AI-POWERED',
    headline: 'AI Multilingual\nSimplification',
    body:
    'Complex official warnings are automatically translated and simplified into Marathi, Hindi, and English — ensuring everyone understands the danger, regardless of language.',
    icon: Icons.translate_rounded,
    lottieAsset: 'assets/animations/login_animation_2.json',
  ),
  _FeatureSlide(
    tag: 'WHATSAPP ALERTS',
    headline: 'Delivered Where\nYou Are',
    body: 'Emergency alerts reach you directly on WhatsApp — the platform you use daily. No app switching, no delays, just instant life-saving information.',
    icon: FontAwesomeIcons.whatsapp, // Now this works!
    lottieAsset: 'assets/animations/login_animation_3.json',
  ),
  _FeatureSlide(
    tag: 'STEP-BY-STEP',
    headline: 'Clear Safety\nInstructions',
    body:
    'No more confusing long messages. Each alert presents numbered safety steps, helping you act quickly and correctly when every second counts.',
    icon: Icons.checklist_rounded,
    lottieAsset: 'assets/animations/login_animation_4.json',
  ),
  _FeatureSlide(
    tag: 'FEEDBACK LOOP',
    headline: 'Close The\nClarity Gap',
    body:
    'Tap "Understood" or "Not Understood." Authorities see comprehension data in real time, improving future alerts and ensuring no one is left confused.',
    icon: Icons.bar_chart_rounded,
    lottieAsset: 'assets/animations/login_animation_5.json',
  ),
];

// ─── INTRO PAGE ───────────────────────────────────────────────────────────────

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _continueVisible = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: Stack(
        children: [
          // ── Subtle background texture dots ──
          Positioned.fill(child: _BackgroundTexture()),

          // ── Main page view ──
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            itemCount: _slides.length,
            onPageChanged: (i) {
              setState(() {
                _currentPage = i;
                if (i == _slides.length - 1) {
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted) setState(() => _continueVisible = true);
                  });
                } else {
                  _continueVisible = false;
                }
              });
            },
            itemBuilder: (context, index) => _SlideView(
              slide: _slides[index],
              index: index,
              isActive: index == _currentPage,
            ),
          ),

          // ── Top bar: brand name with REAL LOGO ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Real Logo instead of alert icon
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/icons/CrisisClarity Logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'CRISIS\nCLARITY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    // Skip button
                    if (_currentPage < _slides.length - 1)
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.25)),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Vertical page indicator (right side) ──
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_slides.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 6,
                    height: isActive ? 28 : 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Bottom: scroll hint OR continue button ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 400),
                  crossFadeState: _continueVisible
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: _currentPage < _slides.length - 1
                      ? GestureDetector(
                    onTap: _goToNext,
                    child: _ScrollHintButton(),
                  )
                      : const SizedBox.shrink(),
                  secondChild: _ContinueButton(onTap: _navigateToLogin),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SLIDE VIEW ───────────────────────────────────────────────────────────────

class _SlideView extends StatefulWidget {
  final _FeatureSlide slide;
  final int index;
  final bool isActive;

  const _SlideView({
    required this.slide,
    required this.index,
    required this.isActive,
  });

  @override
  State<_SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<_SlideView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tagFade;
  late Animation<Offset> _tagSlide;
  late Animation<double> _headFade;
  late Animation<Offset> _headSlide;
  late Animation<double> _bodyFade;
  late Animation<Offset> _bodySlide;
  late Animation<double> _imgFade;
  late Animation<double> _imgScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _setupAnimations();
    if (widget.isActive) _controller.forward();
  }

  void _setupAnimations() {
    _tagFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4)));
    _tagSlide = Tween<Offset>(
        begin: const Offset(-0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)));

    _headFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.6)));
    _headSlide = Tween<Offset>(
        begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _controller,
        curve:
        const Interval(0.15, 0.65, curve: Curves.easeOutCubic)));

    _bodyFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.75)));
    _bodySlide = Tween<Offset>(
        begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _imgFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.7)));
    _imgScale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack)));
  }

  @override
  void didUpdateWidget(_SlideView old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, size.height * 0.13, 40, size.height * 0.14),
      child: isLandscape
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildTextContent()),
          const SizedBox(width: 24),
          Expanded(child: _buildLottiePanel()),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextContent(),
          const SizedBox(height: 24),
          Expanded(child: _buildLottiePanel()),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Feature tag chip
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => FadeTransition(
            opacity: _tagFade,
            child: SlideTransition(position: _tagSlide, child: child),
          ),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.slide.icon,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.slide.tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Headline
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => FadeTransition(
            opacity: _headFade,
            child: SlideTransition(position: _headSlide, child: child),
          ),
          child: Text(
            widget.slide.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Body
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => FadeTransition(
            opacity: _bodyFade,
            child: SlideTransition(position: _bodySlide, child: child),
          ),
          child: Text(
            widget.slide.body,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Slide counter
        AnimatedBuilder(
          animation: _controller,
          builder: (_, child) => FadeTransition(
              opacity: _bodyFade, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.index + 1} / ${_slides.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLottiePanel() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => FadeTransition(
        opacity: _imgFade,
        child: ScaleTransition(scale: _imgScale, child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Center(
              child: Lottie.asset(
                widget.slide.lottieAsset,
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (_, __, ___) => _FallbackIllustration(
                  icon: widget.slide.icon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BACKGROUND TEXTURE ──────────────────────────────────────────────────────

class _BackgroundTexture extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DotPainter());
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── FALLBACK ILLUSTRATION ───────────────────────────────────────────────────

class _FallbackIllustration extends StatelessWidget {
  final IconData icon;
  const _FallbackIllustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 80, color: Colors.white.withOpacity(0.25));
  }
}

// ─── SCROLL HINT BUTTON ──────────────────────────────────────────────────────

class _ScrollHintButton extends StatefulWidget {
  @override
  State<_ScrollHintButton> createState() => _ScrollHintButtonState();
}

class _ScrollHintButtonState extends State<_ScrollHintButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounce;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _offset = Tween<double>(begin: 0, end: 8).animate(
        CurvedAnimation(parent: _bounce, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _offset.value),
        child: child,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Swipe up',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.white.withOpacity(0.8), size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CONTINUE BUTTON ─────────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ContinueButton({required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.025).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'GET STARTED',
                  style: TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.primaryRed,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}