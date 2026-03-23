import 'package:flutter/material.dart';
import 'package:crisis_clarity/theme/app_theme.dart';

class SettingSection extends StatelessWidget {
  const SettingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsGroup(
            title: 'Preferences',
            children: [
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive real-time alerts',
                value: true,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'Vibrate for emergency alerts',
                value: true,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                icon: Icons.volume_up_outlined,
                title: 'Sound',
                subtitle: 'Play sound for alerts',
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            title: 'Alert Settings',
            children: [
              _buildSliderTile(
                icon: Icons.sensors_outlined,
                title: 'Alert Radius',
                subtitle: 'Receive alerts within',
                value: 10,
                min: 5,
                max: 50,
                unit: 'km',
                onChanged: (value) {},
              ),
              _buildChoiceTile(
                icon: Icons.priority_high_outlined,
                title: 'Alert Priority',
                subtitle: 'Red alerts only',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            title: 'Data & Storage',
            children: [
              _buildSwitchTile(
                icon: Icons.wifi_outlined,
                title: 'Download offline maps',
                subtitle: 'Use when no internet',
                value: false,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                icon: Icons.sync_outlined,
                title: 'Auto-update alerts',
                subtitle: 'Background updates',
                value: true,
                onChanged: (value) {},
              ),
              _buildInfoTile(
                icon: Icons.storage_outlined,
                title: 'Storage Used',
                subtitle: '245 MB',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            title: 'Accessibility',
            children: [
              _buildSwitchTile(
                icon: Icons.text_fields,
                title: 'Large Text',
                subtitle: 'Increase text size',
                value: false,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                icon: Icons.contrast,
                title: 'High Contrast',
                subtitle: 'Better visibility',
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            title: 'About',
            children: [
              _buildInfoTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0 (Build 101)',
              ),
              _buildInfoTile(
                icon: Icons.update_outlined,
                title: 'Last Updated',
                subtitle: 'March 10, 2026',
              ),
              _buildLinkTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              _buildLinkTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryRed, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryRed,
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: value,
                        min: min,
                        max: max,
                        divisions: 10,
                        activeColor: AppTheme.primaryRed,
                        onChanged: onChanged,
                      ),
                    ),
                    Text(
                      '${value.toInt()} $unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryRed, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryRed, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryRed, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: onTap,
    );
  }
}