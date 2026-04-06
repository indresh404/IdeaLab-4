import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/groq_service.dart';
import '../data/admin_repository.dart';
import 'admin_dashboard.dart';
import '../../../theme/app_theme.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:go_router/go_router.dart';

class CreateAlertScreen extends ConsumerStatefulWidget {
  const CreateAlertScreen({super.key});

  @override
  ConsumerState<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends ConsumerState<CreateAlertScreen> {
  final _rawTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _severity = 'low';
  String _disasterType = 'other';
  List<String> _selectedWards = [];
  Map<String, dynamic>? _aiResult;
  bool _isLoading = false;

  final List<String> _mumbaiWards = [
    'A', 'B', 'C', 'D', 'E', 'F/South', 'F/North', 'G/South', 'G/North',
    'H/West', 'H/East', 'K/West', 'K/East', 'P/South', 'P/North',
    'R/South', 'R/Central', 'R/North', 'L', 'M/East', 'M/West', 'N', 'S', 'T'
  ];

  @override
  void dispose() {
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _runAI() async {
    if (_rawTextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter raw alert text first')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // In a real app, the API key would be fetched from environment variables or a secure vault
      const String apiKey = 'gsk_Zp8uKPrS8H8W8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X8X'; // PLACEHOLDER: USER WILL PROVIDE
      final groq = GroqService(apiKey: apiKey);
      final result = await groq.simplifyAlert(_rawTextController.text);
      
      setState(() {
        _aiResult = result;
        _severity = result['severity'] ?? 'low';
        _disasterType = result['disasterType'] ?? 'other';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Simplification Complete!')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
    }
  }

  Future<void> _submit() async {
    if (_selectedWards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one zone')));
      return;
    }
    if (_aiResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Run AI Simplification first')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final alertData = {
        'title': _aiResult!['titleEn'],
        'titleHi': _aiResult!['titleHi'],
        'titleMr': _aiResult!['titleMr'],
        'description': _aiResult!['descriptionEn'],
        'descriptionHi': _aiResult!['descriptionHi'],
        'descriptionMr': _aiResult!['descriptionMr'],
        'simplifiedEn': _aiResult!['simplifiedEn'],
        'simplifiedHi': _aiResult!['simplifiedHi'],
        'simplifiedMr': _aiResult!['simplifiedMr'],
        'disasterType': _disasterType,
        'severity': _severity,
        'affectedZones': _selectedWards,
        'postedBy': 'admin_uid', // Fetch from Auth in real app
      };

      await repo.postAlert(alertData);
      
      // Also post safety instructions if present
      if (_aiResult!.containsKey('safetyStepsEn')) {
        final List<Map<String, String>> steps = [];
        final len = (_aiResult!['safetyStepsEn'] as List).length;
        for (int i = 0; i < len; i++) {
          steps.add({
            'en': _aiResult!['safetyStepsEn'][i],
            'hi': _aiResult!['safetyStepsHi'][i],
            'mr': _aiResult!['safetyStepsMr'][i],
          });
        }
        await repo.postSafetyInstructions(_disasterType, steps);
      }

      setState(() => _isLoading = false);
      context.pop();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text('New Disaster Alert', style: GoogleFonts.dmSerifDisplay(fontSize: 20))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RAW ALERT TEXT (ENGLISH)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 8),
              _buildRawInput(),
              const SizedBox(height: 24),
              
              Row(
                children: [
                   Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryTeal),
                      onPressed: _isLoading ? null : _runAI,
                      icon: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('AUTO-SIMPLIFY (AI)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              if (_aiResult != null) _buildAIRatherUI(),
              
              const SizedBox(height: 24),
              Text('AFFECTED ZONES (MUMBAI WARDS)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 12),
              _buildWardSelector(),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
                  onPressed: _isLoading || _aiResult == null ? null : _submit,
                  child: const Text('PUBLISH ALERT NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRawInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
      child: TextField(
        controller: _rawTextController,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Paste the official alert text from IMD, BMC, or Fire Dept here...',
          hintStyle: TextStyle(color: Colors.black26),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildWardSelector() {
    return MultiSelectChipField<String>(
      items: _mumbaiWards.map((e) => MultiSelectItem<String>(e, e)).toList(),
      onTap: (values) => _selectedWards = values.cast<String>(),
      scroll: false,
      headerColor: Colors.transparent,
      chipColor: Colors.white,
      selectedChipColor: AppTheme.primaryRed.withOpacity(0.1),
      selectedTextStyle: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.transparent)),
    );
  }

  Widget _buildAIRatherUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.secondaryTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.secondaryTeal.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryTeal, size: 16),
              const SizedBox(width: 8),
              const Text('AI TRANSLATION READY', style: TextStyle(color: AppTheme.secondaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultItem('Title (EN)', _aiResult!['titleEn']),
          _buildResultItem('Title (HI)', _aiResult!['titleHi']),
          _buildResultItem('Title (MR)', _aiResult!['titleMr']),
          const Divider(),
          _buildResultItem('Disaster Type', _disasterType.toUpperCase()),
          _buildResultItem('Severity', _severity.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black38)),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}
