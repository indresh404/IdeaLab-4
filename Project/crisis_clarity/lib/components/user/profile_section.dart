import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crisis_clarity/features/auth/providers/auth_provider.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSection extends ConsumerStatefulWidget {
  const ProfileSection({super.key});

  @override
  ConsumerState<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<ProfileSection> {
  // Local list of contacts
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString('emergency_contacts');
    if (contactsJson != null) {
      setState(() {
        _contacts = List<Map<String, dynamic>>.from(jsonDecode(contactsJson))
            .map((item) => item.map((key, value) => MapEntry(key, value.toString())))
            .toList();
      });
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contacts', jsonEncode(_contacts));
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact deleted'))
    );
  }

  void _addContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Emergency Contact', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Priya Joshi'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+91 ...'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Relation', hintText: 'e.g. Spouse, Doctor'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  _contacts.add({
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'relation': relationController.text,
                    'initial': nameController.text[0].toUpperCase(),
                  });
                  _saveContacts();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact added successfully'))
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final name = profile?.name ?? 'User';
    final location = profile?.location ?? 'Mumbai, Maharashtra';
    final phone = profile?.phone ?? 'Not Linked';
    final age = profile?.age?.toString() ?? 'N/A';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroHeader(context, name, initial, location)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildPersonalInfoCard(name, phone, location, age),
                const SizedBox(height: 16),
                _buildMedicalBadges(),
                const SizedBox(height: 16),
                _buildEmergencyContactsSection(),
                const SizedBox(height: 16),
                _buildSettingsCard(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildHeroHeader(BuildContext context, String name, String initial, String location) {
  return ConstrainedBox(
    constraints: BoxConstraints(minHeight: 200), // Force minimum height
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB71C1C), Color(0xFFE53935), Color(0xFFEF5350)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _logoutHeaderBtn(context),
                  const Text('My Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                  _headerIconBtn(icon: Icons.edit_outlined, onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              const SizedBox(height: 6),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 2),
              Text(location, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _logoutHeaderBtn(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                child: const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3))),
        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _headerIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3))),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildPersonalInfoCard(String name, String phone, String location, String age) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Information', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _infoRow(Icons.phone_outlined, 'Phone', phone),
          _infoRow(Icons.cake_outlined, 'Age', age),
          _infoRow(Icons.location_on_outlined, 'Area', location),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMedicalBadges() {
    return Row(
      children: [
        Expanded(child: _miniCard(icon: Icons.bloodtype_rounded, label: 'Blood Group', value: 'O+', color: const Color(0xFFD32F2F))),
        const SizedBox(width: 12),
        Expanded(child: _miniCard(icon: Icons.medical_information_outlined, label: 'Health Status', value: 'Healthy', color: const Color(0xFF388E3C))),
      ],
    );
  }

  Widget _miniCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ]),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Emergency Contacts', Icons.contacts_rounded),
              ElevatedButton.icon(
                onPressed: _addContact,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_contacts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No emergency contacts added yet.', style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = _contacts[index];
                return _buildContactTile(
                  index: index,
                  name: c['name']!,
                  relation: c['relation']!,
                  phone: c['phone']!,
                  initial: c['initial']!,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildContactTile({required int index, required String name, required String relation, required String phone, required String initial}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEEEEE))),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFEF5350)]), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(relation, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: AppTheme.primaryRed, size: 20),
            onPressed: () => _makeCall(phone),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
            onPressed: () => _deleteContact(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Settings', Icons.settings_outlined),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Manage alert preferences'),
          Divider(height: 1, color: Colors.grey[100]),
          _settingRow(icon: Icons.language_outlined, title: 'Language', subtitle: 'English'),
          Divider(height: 1, color: Colors.grey[100]),
          _settingRow(icon: Icons.security_outlined, title: 'Privacy & Security', subtitle: 'Manage your data'),
        ],
      ),
    );
  }

  Widget _settingRow({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.08), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: AppTheme.primaryRed, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500]))])),
          Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]), child: child);
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.primaryRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppTheme.primaryRed, size: 16)),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    ]);
  }
}