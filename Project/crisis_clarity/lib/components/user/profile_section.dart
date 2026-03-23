import 'package:flutter/material.dart';
import 'package:crisis_clarity/theme/app_theme.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildProfileInfo(),
            const SizedBox(height: 20),
            _buildEmergencyContacts(),
            const SizedBox(height: 20),
            _buildSettingsOptions(),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryRed,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'RJ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Rahul Joshi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mumbai, Maharashtra',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Verified User',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email_outlined, 'Email', 'rahul.joshi@email.com'),
          _buildInfoRow(Icons.phone_outlined, 'Phone', '+91 98765 43210'),
          _buildInfoRow(Icons.cake_outlined, 'Date of Birth', '15 Aug 1990'),
          _buildInfoRow(Icons.bloodtype_outlined, 'Blood Group', 'O+'),
          _buildInfoRow(Icons.location_on_outlined, 'Address', 'Bandra West, Mumbai'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryRed,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEmergencyContact(
            name: 'Priya Joshi',
            relation: 'Spouse',
            phone: '+91 98765 43211',
          ),
          const SizedBox(height: 8),
          _buildEmergencyContact(
            name: 'Amit Sharma',
            relation: 'Brother',
            phone: '+91 98765 43212',
          ),
          const SizedBox(height: 8),
          _buildEmergencyContact(
            name: 'Dr. Mehta',
            relation: 'Family Doctor',
            phone: '+91 98765 43213',
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact({
    required String name,
    required String relation,
    required String phone,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  relation,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                phone,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone,
                    size: 14,
                    color: AppTheme.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.message,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOptions() {
    return Container(
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
        children: [
          _buildSettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage alert preferences',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English (Selected)',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.location_on_outlined,
            title: 'Location Settings',
            subtitle: 'Mumbai, Maharashtra',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage your data',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs, Contact us',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryRed),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryRed,
          side: BorderSide(color: AppTheme.primaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}