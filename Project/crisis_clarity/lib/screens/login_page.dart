import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../features/auth/presentation/signup_stepper.dart';
import '../features/auth/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  bool _showLogoAnimation = true;

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward().whenComplete(() {
      setState(() {
        _showLogoAnimation = false;
      });
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyPhone(
        phoneNumber: '+91${_phoneCtrl.text.trim()}',
        onCodeSent: (id, token) {
          setState(() {
            _verificationId = id;
            _otpSent = true;
            _isLoading = false;
          });
        },
        onVerificationFailed: (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Verification failed')),
          );
        },
        onVerificationCompleted: (credential) async {
          // Auto-signin if possible
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).signInWithOtp(
        _verificationId!,
        _otpCtrl.text.trim(),
      );
      
      // Wait for auth state to update
      final user = await ref.read(authStateProvider.future);
      if (user != null) {
        final profile = await ref.read(authRepositoryProvider).getUserProfile(user.uid);
        if (profile == null) {
          // No profile, sign out and show error + redirect to signup
          await ref.read(authControllerProvider.notifier).signOut();
          
          if (mounted) {
            setState(() => _isLoading = false);
            // Use Future.microtask to show snackbar outside of the build/nav cycle
            Future.microtask(() {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account not found. Please sign up first.')),
                );
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: SafeArea(
        child: Stack(
          children: [
            // Background circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              ),
            ),

            if (_showLogoAnimation)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeIn(
                      duration: const Duration(milliseconds: 1500),
                      child: ZoomIn(
                        duration: const Duration(milliseconds: 1500),
                        child: Container(
                          height: 180, width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset('assets/icons/Logo.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: Text(
                        'CRISIS CLARITY',
                        style: GoogleFonts.outfit( // Updated font
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_showLogoAnimation)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      // Small Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 50, width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset('assets/icons/Logo.png'),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'CRISIS\nCLARITY',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      
                      // Card
                      FadeInUp(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30)],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _otpSent ? 'Enter OTP' : 'Welcome to CrisisClarity',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryRed,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _otpSent 
                                  ? 'Check your messages for the verification code' 
                                  : 'Sign in with your phone number to receive disaster alerts for your area.',
                                style: TextStyle(color: Colors.black54, fontSize: 14),
                              ),
                              const SizedBox(height: 30),
                              
                              if (!_otpSent)
                                _buildField(Icons.phone_android_rounded, 'Mobile Number', _phoneCtrl)
                              else
                                _buildField(Icons.lock_clock_rounded, 'OTP Code', _otpCtrl, isOtp: true),
                              
                              const SizedBox(height: 30),
                              
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator())
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _otpSent ? _verifyOtp : _sendOtp,
                                    child: Text(_otpSent ? 'VERIFY OTP' : 'SIGN IN'),
                                  ),
                                ),
                              
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupStepper()));
                                  },
                                  child: Text(
                                    "New here? Create Account",
                                    style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      // Lottie
                      SizedBox(
                        height: 300,
                        child: Lottie.asset('assets/animations/login.json'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String hint, TextEditingController ctrl, {bool isOtp = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        maxLength: isOtp ? 6 : 10, // Max 10 digits for phone
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: Icon(icon, color: AppTheme.primaryRed.withOpacity(0.6)),
          prefixText: isOtp ? null : '+91 ', // Fixed +91 prefix
          prefixStyle: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}