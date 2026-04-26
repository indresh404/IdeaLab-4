import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers/network_provider.dart';
import '../theme/app_theme.dart';

class IpEntryScreen extends ConsumerStatefulWidget {
  const IpEntryScreen({super.key});

  @override
  ConsumerState<IpEntryScreen> createState() => _IpEntryScreenState();
}

class _IpEntryScreenState extends ConsumerState<IpEntryScreen> {
  final _controller = TextEditingController();
  bool _isManual = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue(String url) {
    ref.read(baseUrlProvider.notifier).state = url;
    ref.read(isNetworkConfiguredProvider.notifier).state = true;
    // GoRouter will automatically redirect since it's listening to this provider
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1C1E),
              AppTheme.primaryRed.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.hub_outlined, color: Colors.white, size: 64),
                const SizedBox(height: 32),
                Text(
                  'Network Setup',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose your backend environment for this session.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Option 1: Production
                _buildOption(
                  title: 'Production (Render)',
                  subtitle: 'crisis-clarity.onrender.com',
                  icon: Icons.cloud_done_outlined,
                  onTap: () => _onContinue('https://crisis-clarity.onrender.com'),
                ),
                
                const SizedBox(height: 20),
                
                // Option 2: Local/IP
                if (!_isManual)
                  _buildOption(
                    title: 'Manual IP / Local',
                    subtitle: 'Use a custom backend address',
                    icon: Icons.settings_ethernet,
                    onTap: () => setState(() => _isManual = true),
                  )
                else
                  Column(
                    children: [
                      TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'http://192.168.1.5:8000',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.link, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_controller.text.isNotEmpty) {
                              _onContinue(_controller.text.trim());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryRed,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('CONNECT TO IP'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isManual = false),
                        child: const Text('Back to options', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
