import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppStyles.appBarTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications Section
              Text('NOTIFICATIONS', style: AppStyles.sectionTitle),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusMedium,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Get alerts even when app is closed',
                      value: settings.pushNotifications,
                      onChanged: (v) => settings.togglePushNotifications(v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: 'Arrival Alerts',
                      subtitle: 'Notify when bus is 5 minutes away',
                      value: settings.arrivalAlerts,
                      onChanged: (v) => settings.toggleArrivalAlerts(v),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      title: 'Bus Delay Alerts',
                      subtitle: 'Notify on campus route delays & changes',
                      value: settings.busDelayAlerts,
                      onChanged: (v) => settings.toggleDelayAlerts(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Preferences Section
              Text('PREFERENCES', style: AppStyles.sectionTitle),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusMedium,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Location Services',
                      subtitle: 'Used for nearest stop & live distance',
                      value: settings.locationEnabled,
                      onChanged: (v) => settings.toggleLocation(v),
                    ),
                    _buildDivider(),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text('Language', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                        subtitle: Text(settings.language, style: AppStyles.bodySmall),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Default language is English.'), behavior: SnackBarBehavior.floating),
                          );
                        },
                      ),
                    ),
                    _buildDivider(),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text('Appearance', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                        subtitle: Text(settings.appearance, style: AppStyles.bodySmall),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Primary Light',
                            style: AppStyles.badgeText.copyWith(color: AppColors.primaryBlue),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Privacy & Security
              Text('PRIVACY & LEGAL', style: AppStyles.sectionTitle),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusMedium,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text('Privacy Policy', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
                        onTap: () => _showPolicyDialog(context, 'Privacy Policy'),
                      ),
                    ),
                    _buildDivider(),
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text('Terms of Service', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
                        onTap: () => _showPolicyDialog(context, 'Terms of Service'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // About Section
              Center(
                child: Column(
                  children: [
                    Text('UniRide v1.0.0', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Campus Transit Engineering • Build 2026', style: AppStyles.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        title: Text(title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: AppStyles.bodySmall),
        value: value,
        activeColor: AppColors.primaryBlue,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider.withOpacity(0.7));
  }

  void _showPolicyDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusLarge),
        title: Text(title, style: AppStyles.heading3),
        content: Text(
          'UniRide campus shuttle tracking respects student privacy. GPS data is only processed for campus transit timing and arrival simulations without third-party tracking.',
          style: AppStyles.bodyMedium,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
