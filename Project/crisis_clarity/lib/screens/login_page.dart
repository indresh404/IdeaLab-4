import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';
import 'admin_page.dart';
import 'user_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  bool _showLogoAnimation = true;

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoginMode = true;
  String _selectedRole = 'user'; // 'user' or 'admin'

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
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_isLoginMode) {
      // Handle login
      if (_selectedRole == 'admin') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UserPage()));
      }
    } else {
      // Handle signup
      if (_nameCtrl.text.isNotEmpty &&
          _ageCtrl.text.isNotEmpty &&
          _phoneCtrl.text.isNotEmpty &&
          _locationCtrl.text.isNotEmpty &&
          _passwordCtrl.text.isNotEmpty) {

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/success_signup.json',
                    height: 150,
                    repeat: false,
                    onLoaded: (composition) {
                      Future.delayed(composition.duration, () {
                        Navigator.pop(context);
                        if (_selectedRole == 'admin') {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
                        } else {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserPage()));
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Account Created!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields'),
            backgroundColor: AppTheme.primaryRed,
          ),
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
            // Background design
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -40,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Logo Animation (only plays at start)
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
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'assets/icons/CrisisClarity Logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      delay: const Duration(milliseconds: 500),
                      child: const Text(
                        'CRISIS CLARITY',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content (appears after animation)
            if (!_showLogoAnimation)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Small Logo and App Name Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeInLeft(
                            duration: const Duration(milliseconds: 800),
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/icons/CrisisClarity Logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FadeInRight(
                            duration: const Duration(milliseconds: 800),
                            child: const Text(
                              'CRISIS\nCLARITY',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Login/Signup Toggle
                      FadeInDown(
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLoginMode = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _isLoginMode ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          color: _isLoginMode ? AppTheme.primaryRed : Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLoginMode = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: !_isLoginMode ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: !_isLoginMode ? AppTheme.primaryRed : Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Form Fields
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoginMode ? 'Welcome Back' : 'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryRed,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Signup fields
                              if (!_isLoginMode) ...[
                                _buildField(
                                  Icons.person_outline_rounded,
                                  'Full Name',
                                  _nameCtrl,
                                ),
                                const SizedBox(height: 16),

                                _buildField(
                                  Icons.cake_outlined,
                                  'Age',
                                  _ageCtrl,
                                  isNumber: true,
                                ),
                                const SizedBox(height: 16),

                                _buildField(
                                  Icons.location_on_outlined,
                                  'Location',
                                  _locationCtrl,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Common fields
                              _buildField(
                                Icons.phone_android_rounded,
                                'Mobile Number',
                                _phoneCtrl,
                                isNumber: true,
                              ),
                              const SizedBox(height: 16),

                              _buildField(
                                Icons.lock_outline_rounded,
                                'Password',
                                _passwordCtrl,
                                isPassword: true,
                              ),

                              // Forgot password
                              if (_isLoginMode)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryRed,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 16),

                              // Role Selection (only for signup)
                              if (!_isLoginMode) ...[
                                Text(
                                  'Select Role',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildRoleCard(
                                        'User',
                                        Icons.person_rounded,
                                        'Receive alerts',
                                        _selectedRole == 'user',
                                            () => setState(() => _selectedRole = 'user'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildRoleCard(
                                        'Admin',
                                        Icons.admin_panel_settings_rounded,
                                        'Manage alerts',
                                        _selectedRole == 'admin',
                                            () => setState(() => _selectedRole = 'admin'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryRed,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 5,
                                    shadowColor: AppTheme.primaryRed.withOpacity(0.5),
                                  ),
                                  child: Text(
                                    _isLoginMode ? 'SIGN IN' : 'CREATE ACCOUNT',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                              // Terms
                              if (!_isLoginMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Center(
                                    child: Text(
                                      'By signing up, you agree to our Terms & Conditions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Lottie Animation at the bottom
                      FadeIn(
                        delay: const Duration(milliseconds: 500),
                        child: Container(
                          height: 450,
                          child: Lottie.asset(
                            _isLoginMode
                                ? 'assets/animations/login.json'
                                : 'assets/animations/signup.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String hint, TextEditingController ctrl,
      {bool isPassword = false, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        obscureText: isPassword ? _obscurePassword : false,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.primaryRed.withOpacity(0.6)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey[400],
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, String subtitle, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryRed : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryRed : Colors.grey[700],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppTheme.primaryRed.withOpacity(0.7) : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}