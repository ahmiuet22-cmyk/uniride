import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/favorites_provider.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const ProfileScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final busProvider = Provider.of<BusProvider>(context);
    final favProvider = Provider.of<FavoritesProvider>(context);
    final student = auth.student;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile', style: AppStyles.appBarTitle),
        centerTitle: false,
        leading: onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: onOpenDrawer,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // Student Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusLarge,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.softShadow],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 46,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.goldAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(student.name, style: AppStyles.heading1.copyWith(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(
                      student.email,
                      style: AppStyles.bodySmall.copyWith(fontSize: 13, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: AppStyles.radiusMedium,
                        border: Border.all(color: AppColors.goldBorder.withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildProfileStat('Student ID', student.studentId),
                          Container(height: 24, width: 1, color: AppColors.border),
                          _buildProfileStat('Department', student.department),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu Options Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusMedium,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.star_outline_rounded,
                      title: 'Favorite Stops',
                      subtitle: '${favProvider.favoriteStops.length} stops saved',
                      onTap: () {
                        _showFavoriteStopsSheet(context, favProvider);
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.directions_bus_rounded,
                      title: 'My Bus',
                      subtitle: busProvider.mainLiveBus != null
                          ? '${busProvider.mainLiveBus!.name} • Active Bus'
                          : 'Campus Express Bus',
                      onTap: () {
                        final featured = busProvider.mainLiveBus ??
                            (busProvider.buses.isNotEmpty ? busProvider.buses.first : null);
                        if (featured != null) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.busDetails,
                            arguments: featured,
                          );
                        }
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Alerts, theme, notifications',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.settings);
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'Campus transport hotline & FAQ',
                      onTap: () => _showHelpDialog(context),
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About UniRide',
                      subtitle: 'Version 1.0.0 (Build 2026)',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              GestureDetector(
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppStyles.radiusMedium,
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Log Out',
                        style: AppStyles.buttonText.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppStyles.bodySmall.copyWith(fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppStyles.buttonText.copyWith(fontSize: 13, color: AppColors.primaryText),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.goldLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.goldBorder.withOpacity(0.5)),
          ),
          child: Icon(icon, color: AppColors.goldDark, size: 20),
        ),
        title: Text(title, style: AppStyles.heading3.copyWith(fontSize: 15)),
        subtitle: Text(subtitle, style: AppStyles.bodySmall.copyWith(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.divider.withOpacity(0.7));
  }

  void _showFavoriteStopsSheet(BuildContext context, FavoritesProvider fav) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved Favorite Stops', style: AppStyles.heading2.copyWith(fontSize: 18)),
            const SizedBox(height: 14),
            ...fav.favoriteStops.map(
              (s) => Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.place_rounded, color: AppColors.primaryBlue),
                  title: Text(s.name, style: AppStyles.bodyLarge),
                  subtitle: Text('Default wait: ${s.defaultEtaMinutes} min', style: AppStyles.bodySmall),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primaryBlue),
                    onPressed: () => fav.toggleFavorite(s.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusLarge),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text('Help & Support', style: AppStyles.heading3),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transport Assistant:'),
            SizedBox(height: 4),
            Text('Mr. Waqas Butt', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Phone: 0302-6669662', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
            SizedBox(height: 12),
            Text('Campus Departure Time:'),
            SizedBox(height: 4),
            Text('4:15 PM (Evening Return)', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text('Campus: UET Gujranwala (RCET)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusLarge),
        title: Row(
          children: [
            const Icon(Icons.directions_bus_rounded, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Text('About UniRide', style: AppStyles.heading3),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UniRide Transit Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 6),
            Text('Official campus bus tracking system for UET Gujranwala (RCET) students and staff.'),
            SizedBox(height: 12),
            Text('Version 1.0.0 • RCET Campus', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
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
}
