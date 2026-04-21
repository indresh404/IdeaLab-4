import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../domain/user_model.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class SignupStepper extends ConsumerStatefulWidget {
  const SignupStepper({super.key});

  @override
  ConsumerState<SignupStepper> createState() => _SignupStepperState();
}

class _SignupStepperState extends ConsumerState<SignupStepper> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Controllers
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;
  bool _autoVerifying = false;

  // Step 2 Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedWard = 'Mira Road';
  String _selectedLang = 'en';
  
  // Step 3 Controllers
  final _verificationCodeController = TextEditingController();
  final _chatIdController = TextEditingController();
  bool _showCodeField = false;
  bool _isVerifyingTelegram = false;

  final List<String> _mumbaiRegions = [
    'Mira Road', 'Virar', 'Dahisar', 'Malad', 'Kandivali',
    'Borivali', 'Andheri', 'Bandra', 'Dadar', 'Kurla',
    'Chembur', 'Vashi', 'Thane', 'Mulund', 'Ghatkopar',
    'Sion', 'Colaba', 'Nagpada', 'Byculla', 'Lower Parel'
  ];


@override
void initState() {
  super.initState();
  // Check if user is already authenticated but profile is missing
  // If so, jump to Step 2 (Profile Info)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final user = ref.read(authStateProvider).value;
    final profile = ref.read(userProfileProvider).value;
    
    if (user != null && _currentStep == 0) {
      if (profile != null) {
        // If profile exists but Telegram is not linked, go to Telegram step (index 2)
        if (!profile.telegramLinked) {
          setState(() => _currentStep = 2);
          if (_pageController.hasClients) _pageController.jumpToPage(2);
        } else {
          // If profile and telegram both exist, go to success (index 3)
          setState(() => _currentStep = 3);
          if (_pageController.hasClients) _pageController.jumpToPage(3);
        }
      } else {
        // Just authenticated, go to Profile step (index 1)
        setState(() => _currentStep = 1);
        if (_pageController.hasClients) _pageController.jumpToPage(1);
      }
    }
  });
}

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _verificationCodeController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // --- Step 1: Phone Auth Logic ---
  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();
    
    String phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showSnackBar('Please enter a valid 10-digit number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);

      await repo.verifyPhone(
        phoneNumber: '+91$phone',
        onCodeSent: (id, token) {
          setState(() {
            _verificationId = id;
            _isLoading = false;
          });
          
          _showOtpDialog();
        },
        onVerificationFailed: (e) {
          setState(() => _isLoading = false);
          _showSnackBar(e.message ?? 'Verification failed', isError: true);
        },
        onVerificationCompleted: (credential) async {
          setState(() => _autoVerifying = true);
          try {
            await ref.read(authControllerProvider.notifier).signInWithCredential(credential);
            if (mounted) {
              setState(() {
                _autoVerifying = false;
                _isLoading = false;
              });
              _nextPage();
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _autoVerifying = false;
                _isLoading = false;
              });
              _showSnackBar('Auto-verification failed', isError: true);
            }
          }
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showOtpDialog() {
    _otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(child: Text('OTP Sent', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 24))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 6-digit verification code\nsent to your phone number',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              '+91 ${_phoneController.text.trim()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                hintText: '●●●●●●',
                hintStyle: TextStyle(color: Colors.grey[200]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryRed, width: 2),
                ),
              ),
              onChanged: (v) {
                if (v.length == 6) {
                  Navigator.pop(context);
                  _verifyOtp();
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _otpSent = false;
                      _verificationId = null;
                      _otpController.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_otpController.text.length == 6) {
                      Navigator.of(context).pop();
                      _verifyOtp();
                    } else {
                      _showSnackBar('Please enter valid 6-digit OTP', isError: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _verifyOtp() async {
  FocusScope.of(context).unfocus();
  
  if (_verificationId == null || _otpController.text.length != 6) {
    _showSnackBar('Please enter valid 6-digit OTP', isError: true);
    return;
  }

  setState(() => _isLoading = true);
  try {
    await ref.read(authControllerProvider.notifier).signInWithOtp(
          _verificationId!,
          _otpController.text.trim(),
        );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _otpSent = false;
        _verificationId = null;
        _otpController.clear();
      });
      
      // The router will automatically handle the redirection 
      // if the user already has a profile. 
      // If not, we manually move to the next page (Profile).
      final profile = ref.read(userProfileProvider).value;
      if (profile == null) {
        _nextPage();
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      _showSnackBar('Invalid OTP. Please try again.', isError: true);
    }
  }
}

  // --- Step 2: Save Profile ---
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    
    final userAuth = ref.read(authStateProvider).value;
    if (userAuth == null) {
      _showSnackBar('Authentication error. Please restart signup.', isError: true);
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter your name', isError: true);
      return;
    }

    if (_ageController.text.trim().isEmpty) {
      _showSnackBar('Please enter your age', isError: true);
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 13 || age > 120) {
      _showSnackBar('Please enter a valid age (13-120)', isError: true);
      return;
    }

    final userModel = UserModel(
      uid: userAuth.uid,
      name: _nameController.text.trim(),
      phone: '+91${_phoneController.text.trim()}',
      location: _selectedWard,
      preferredLanguage: _selectedLang,
      age: age,
      gender: _selectedGender,
      createdAt: DateTime.now(),
      telegramLinked: false,
    );

    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider.notifier).createUserProfile(userModel);
      if (mounted) {
        setState(() => _isLoading = false);
        _nextPage();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to save profile: $e', isError: true);
      }
    }
  }

  // --- Step 3: Telegram Verification with Chat ID ---
  Future<void> _openTelegram() async {
    FocusScope.of(context).unfocus();
    
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _showSnackBar('User not found. Please restart signup.', isError: true);
      return;
    }

    final String botUsername = 'CrisisClarity_bot';
    final String url = 'https://t.me/$botUsername?start=${user.uid}';

    try {
      final Uri uri = Uri.parse(url);
      bool launched = false;
      
      // Try tg:// protocol first
      final tgUri = Uri.parse('tg://resolve?domain=$botUsername&start=${user.uid}');
      if (await canLaunchUrl(tgUri)) {
        launched = await launchUrl(tgUri, mode: LaunchMode.externalApplication);
      }
      
      // Try https URL
      if (!launched && await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      
      if (launched) {
        setState(() {
          _showCodeField = true;
        });
        _showSnackBar(
          'Bot will send you a Verification Code and Chat ID',
          isError: false,
        );
      } else {
        _showTelegramNotInstalledDialog();
      }
    } catch (e) {
      _showSnackBar('Error opening Telegram', isError: true);
    }
  }

  Future<void> _verifyWithCode() async {
    FocusScope.of(context).unfocus();
    
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _showSnackBar('User not found', isError: true);
      return;
    }

    final enteredCode = _verificationCodeController.text.trim();
    final enteredChatId = _chatIdController.text.trim();

    if (enteredCode.isEmpty) {
      _showSnackBar('Please enter the verification code from Telegram', isError: true);
      return;
    }

    if (enteredChatId.isEmpty) {
      _showSnackBar('Please enter your Chat ID from Telegram', isError: true);
      return;
    }

    // Verify code matches user UID
    if (enteredCode == user.uid) {
      setState(() => _isLoading = true);

      try {
        // Update Firestore with Telegram info including Chat ID
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'telegramLinked': true,
          'telegramChatId': enteredChatId, // Store the Chat ID for sending alerts
          'telegramLinkedAt': FieldValue.serverTimestamp(),
        });

        _showSnackBar('✓ Telegram linked successfully! Chat ID saved.', isError: false);
        _nextPage();
      } catch (e) {
        _showSnackBar('Error: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _showSnackBar('Invalid verification code', isError: true);
    }
  }

  void _showTelegramNotInstalledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Open Telegram'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.telegram, size: 50, color: Color(0xFF26A5E4)),
            SizedBox(height: 16),
            Text('To connect Telegram:'),
            SizedBox(height: 8),
            Text('1. Open Telegram app manually'),
            Text('2. Search for @CrisisClarity_bot'),
            Text('3. Press Start button'),
            Text('4. Copy both Code and Chat ID'),
            Text('5. Paste them in the app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          IconButton(
                            onPressed: _previousPage,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        else
                          const SizedBox(width: 40),
                        Text(
                          'STEP ${_currentStep + 1} OF 4',
                          style: TextStyle(
                            color: AppTheme.primaryRed.withOpacity(0.6),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: 4,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppTheme.primaryRed,
                        dotColor: AppTheme.primaryRed.withOpacity(0.2),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
  return SingleChildScrollView(
    child: FadeInUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Lottie.asset('assets/animations/signup.json', height: 180),
            const SizedBox(height: 24),
            Text(
              'Verify your number',
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'We will send a one-time password to verify your identity',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 40),
            _buildPhoneField(),
            const SizedBox(height: 32),
            if (_autoVerifying)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Auto-verifying OTP...'),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('SEND CODE'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.phone_rounded, color: AppTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: GoogleFonts.outfit(fontSize: 16),
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'Phone Number',
                hintText: '98765 43210',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: FadeInUp(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Tell us about you',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_rounded,
                hint: 'Enter your full name',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      icon: Icons.cake_rounded,
                      hint: 'Years',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildDropdownField(
                      label: 'Gender',
                      value: _selectedGender,
                      items: const ['Male', 'Female', 'Other'],
                      onChanged: (v) => setState(() => _selectedGender = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Your Mumbai Area',
                value: _selectedWard,
                items: _mumbaiRegions,
                onChanged: (v) => setState(() => _selectedWard = v!),
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                label: 'Preferred Language',
                value: _selectedLang,
                items: const ['en', 'hi', 'mr'],
                labels: const {'en': 'English', 'hi': 'हिंदी', 'mr': 'मराठी'},
                onChanged: (v) => setState(() => _selectedLang = v!),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('CONTINUE'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const FaIcon(FontAwesomeIcons.telegram, size: 60, color: Color(0xFF26A5E4)),
                    const SizedBox(height: 20),
                    Text(
                      'Connect Telegram',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Get instant alerts on Telegram',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF26A5E4),
                        ),
                        onPressed: _openTelegram,
                        icon: const FaIcon(FontAwesomeIcons.telegram, size: 18, color: Colors.white),
                        label: const Text('OPEN TELEGRAM BOT'),
                      ),
                    ),

                    if (_showCodeField) ...[
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _verificationCodeController,
                          keyboardType: TextInputType.text,
                          style: GoogleFonts.outfit(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Verification Code',
                            hintText: 'Paste the code from Telegram',
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.content_paste),
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) {
                                  setState(() {
                                    _verificationCodeController.text = data!.text!;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _chatIdController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.outfit(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Chat ID',
                            hintText: 'Paste your Chat ID from Telegram',
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.content_paste),
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null) {
                                  setState(() {
                                    _chatIdController.text = data!.text!;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyWithCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('VERIFY & LINK', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],

                    if (!_showCodeField) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Tap the button above, then copy both the Verification Code and Chat ID from Telegram',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _nextPage,
                child: Text(
                  'Skip for now',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/success_signup.json', height: 200, repeat: false),
            const SizedBox(height: 24),
            Text(
              "You're all set!",
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "You'll receive alerts for Mumbai Zone $_selectedWard in ${_selectedLang == 'en' ? 'English' : _selectedLang == 'hi' ? 'Hindi' : 'Marathi'}.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                child: const Text('GO TO DASHBOARD'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType ?? TextInputType.text,
              style: GoogleFonts.outfit(fontSize: 16),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
              ),
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    Map<String, String>? labels,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(labels?[e] ?? e),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}