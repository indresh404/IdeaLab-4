import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../auth/providers/auth_provider.dart';
import '../../domain/alert_model.dart';
import '../../../../theme/app_theme.dart';

class AlertCard extends ConsumerWidget {
  final AlertModel alert;

  const AlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProfileProvider).value;
    final lang = user?.preferredLanguage ?? 'en';

    final severityColor = _getSeverityColor(alert.severity);

    return GestureDetector(
      onTap: () => context.push('/alert/${alert.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: severityColor.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: severityColor.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon + Severity + Time
            Row(
              children: [
                _buildTypeIcon(alert.disasterType, severityColor),
                const SizedBox(width: 12),
                _buildSeverityBadge(alert.severity, severityColor),
                const Spacer(),
                Text(
                  timeago.format(alert.createdAt),
                  style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              alert.getLocalizedTitle(lang),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                height: 1.2,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            // Description (Simplified)
            Text(
              alert.getLocalizedSimplified(lang),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Footer: Zone + Read More
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency_rounded, size: 14, color: AppTheme.primaryRed),
                    const SizedBox(width: 4),
                    Text(
                      'Impacted Zones: ${alert.affectedZones.join(", ")}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45),
                    ),
                  ],
                ),
                Text(
                  'READ MORE →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryRed,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return AppTheme.errorRed;
      case 'high': return AppTheme.primaryRed;
      case 'medium': return AppTheme.warningAmber;
      case 'low': return AppTheme.secondaryTeal;
      default: return Colors.grey;
    }
  }

  Widget _buildTypeIcon(String type, Color color) {
    IconData icon;
    switch (type.toLowerCase()) {
      case 'flood': icon = Icons.water_drop_rounded; break;
      case 'storm': icon = Icons.bolt_rounded; break;
      case 'fire': icon = Icons.local_fire_department_rounded; break;
      case 'evacuation': icon = Icons.exit_to_app_rounded; break;
      case 'cyclone': icon = Icons.cyclone_rounded; break;
      case 'earthquake': icon = Icons.vibration_rounded; break;
      default: icon = Icons.error_outline_rounded;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSeverityBadge(String severity, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        severity.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}
