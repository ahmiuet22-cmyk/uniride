import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/proximity_alert_service.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../alerts/screens/notifications_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../map/screens/live_map_screen.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../../routes/screens/routes_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  GlobalKey<ScaffoldState>? _scaffoldKey;

  GlobalKey<ScaffoldState> get _key => _scaffoldKey ??= GlobalKey<ScaffoldState>();

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openDrawer() {
    _key.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final busProvider = Provider.of<BusProvider>(context);
    final favProvider = Provider.of<FavoritesProvider>(context);

    // Continuous 5 km Proximity Geofence Monitor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && busProvider.buses.isNotEmpty) {
        ProximityAlertService().checkProximity(
          buses: busProvider.buses,
          studentStop: favProvider.selectedPickupStop,
          notifProvider: notifProvider,
          context: context,
          onTrackBus: (bus) {
            busProvider.selectBus(bus);
            _switchTab(1); // Switch to Live Map tab
          },
        );
      }
    });

    final List<Widget> pages = [
      HomeScreen(onSwitchTab: _switchTab, onOpenDrawer: _openDrawer),
      LiveMapScreen(onOpenDrawer: _openDrawer),
      RoutesScreen(onOpenDrawer: _openDrawer),
      ScheduleScreen(onOpenDrawer: _openDrawer),
      NotificationsScreen(onOpenDrawer: _openDrawer),
    ];

    return Scaffold(
      key: _key,
      drawer: AppDrawer(
        onSelectTab: _switchTab,
        currentTabIndex: _currentIndex,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.border.withOpacity(0.9),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140A2240),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.map_rounded,
                  label: 'Live Map',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.alt_route_rounded,
                  label: 'Routes',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.calendar_month_rounded,
                  label: 'Timetable',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                  badgeCount: notifProvider.unreadCount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _switchTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.goldLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.goldBorder.withOpacity(0.8), width: 1.2)
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? AppColors.primaryBlue : AppColors.mutedText,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -7,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.goldAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.goldAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
