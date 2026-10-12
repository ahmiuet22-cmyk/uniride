import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../providers/notification_provider.dart';

class AppDrawer extends StatelessWidget {
  final Function(int tabIndex)? onSelectTab;
  final int currentTabIndex;

  const AppDrawer({super.key, this.onSelectTab, this.currentTabIndex = 0});

  void _showDigitalBusPass(BuildContext context, AuthProvider auth, BusProvider busProvider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pass Card Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, Color(0xFF002966)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/images/uet_logo.png',
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.school_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UET GUJRANWALA',
                                  style: AppStyles.badgeText.copyWith(
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Official Student Bus Pass',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: AppStyles.badgeText.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Student Info & QR Code
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.lightBlue,
                          child: Text(
                            auth.student.name.isNotEmpty ? auth.student.name[0] : 'S',
                            style: AppStyles.heading2.copyWith(color: AppColors.primaryBlue),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(auth.student.name, style: AppStyles.heading3.copyWith(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(
                                'Roll No: ${auth.student.studentId}',
                                style: AppStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              Text(
                                auth.student.department,
                                style: AppStyles.bodySmall.copyWith(color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 18),

                    // Route details in pass
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppStyles.radiusMedium,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_bus_rounded, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ASSIGNED ROUTE',
                                  style: AppStyles.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                Text(
                                  'Route 1 • Chanda Qila / Wapda Town',
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryText,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // QR Code visual placeholder
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 130, color: AppColors.primaryText),
                          Text(
                            'PASS-RCET-2026-CS123',
                            style: AppStyles.bodySmall.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text(
                      'Scan this digital pass while boarding campus bus',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusMedium),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close Pass'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelplineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusLarge),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency_rounded, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Transport Helpline', style: AppStyles.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For emergency assistance, route inquiries, or bus delays, contact the RCET Transport Office:',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildContactRow(
              icon: Icons.phone_in_talk_rounded,
              title: 'Campus Transport Controller',
              value: '+92 55 9200388',
            ),
            const SizedBox(height: 10),
            _buildContactRow(
              icon: Icons.security_rounded,
              title: 'RCET Campus Security',
              value: '+92 55 9200389',
            ),
            const SizedBox(height: 10),
            _buildContactRow(
              icon: Icons.local_hospital_rounded,
              title: 'Rescue Emergency',
              value: '1122',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppStyles.radiusMedium,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.secondaryText)),
                Text(value, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final busProvider = Provider.of<BusProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);
    final student = auth.student;

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 16,
      child: Column(
        children: [
          // Drawer Header with University & Student Info
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, Color(0xFF00224D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.goldBorder, width: 1.5),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        'assets/images/uet_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showDigitalBusPass(context, auth, busProvider),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Pass',
                              style: AppStyles.badgeText.copyWith(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  student.name,
                  style: AppStyles.heading2.copyWith(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.studentId} • ${student.department}',
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Assigned Live Bus Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Route 1: Hino GAU-2555 Active',
                        style: AppStyles.badgeText.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Drawer Menu Items Scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildDrawerTile(
                  icon: Icons.home_rounded,
                  title: 'Home Dashboard',
                  highlight: currentTabIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) onSelectTab!(0);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.map_rounded,
                  title: 'Live Transit Map',
                  badgeText: 'GPS',
                  highlight: currentTabIndex == 1,
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) onSelectTab!(1);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.alt_route_rounded,
                  title: 'Bus Routes & Stops',
                  highlight: currentTabIndex == 2,
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) onSelectTab!(2);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Bus Timetable & Shifts',
                  highlight: currentTabIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) onSelectTab!(3);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.notifications_rounded,
                  title: 'Alerts & Notices',
                  badgeText: notifProvider.hasUnread ? '${notifProvider.unreadCount}' : null,
                  highlight: currentTabIndex == 4,
                  onTap: () {
                    Navigator.pop(context);
                    if (onSelectTab != null) onSelectTab!(4);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.badge_rounded,
                  title: 'Digital Bus Pass (QR)',
                  onTap: () {
                    Navigator.pop(context);
                    _showDigitalBusPass(context, auth, busProvider);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: AppColors.divider, height: 1),
                ),

                _buildDrawerTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Emergency & Helpline',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelplineDialog(context);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.logout_rounded,
                  title: 'Log Out',
                  iconColor: AppColors.danger,
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.login,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Drawer Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UniRide RCET Campus',
                  style: AppStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    String? badgeText,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: highlight ? AppColors.lightBlue.withOpacity(0.6) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: highlight
                ? BorderSide(color: AppColors.primaryBlue.withOpacity(0.15))
                : BorderSide.none,
          ),
          dense: true,
          leading: Icon(
            icon,
            color: iconColor ?? (highlight ? AppColors.primaryBlue : AppColors.primaryText),
            size: 22,
          ),
          title: Text(
            title,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? AppColors.primaryBlue : AppColors.primaryText,
              fontSize: 14,
            ),
          ),
          trailing: badgeText != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: AppStyles.badgeText.copyWith(color: Colors.white, fontSize: 10),
                  ),
                )
              : (highlight
                  ? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryBlue, size: 12)
                  : null),
          onTap: onTap,
        ),
      ),
    );
  }
}
