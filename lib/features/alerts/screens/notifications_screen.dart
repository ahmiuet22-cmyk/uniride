import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class NotificationsScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const NotificationsScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final notifications = notifProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppStyles.appBarTitle),
        centerTitle: false,
        leading: onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: onOpenDrawer,
              )
            : null,
        actions: [
          if (notifications.isNotEmpty) ...[
            if (notifProvider.hasUnread)
              TextButton(
                onPressed: () => notifProvider.markAllAsRead(),
                child: Text(
                  'Mark all read',
                  style: AppStyles.buttonText.copyWith(
                    fontSize: 13,
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white70, size: 22),
              tooltip: 'Clear All Alerts',
              onPressed: () => notifProvider.clearAll(),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            await notifProvider.refreshAlerts();
          },
          child: !notifProvider.isLoaded
              ? ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) => const SkeletonLoader(
                    width: double.infinity,
                    height: 86,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                )
              : notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        EmptyStateView(
                          icon: Icons.notifications_none_rounded,
                          title: 'No Active Alerts',
                          message:
                              'Live 5 km bus approaching alerts and admin broadcast notices will appear here automatically in real time.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return Dismissible(
                          key: Key('notif_${notif.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.9),
                              borderRadius: AppStyles.radiusMedium,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            notifProvider.deleteNotification(notif.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Alert "${notif.title}" deleted.'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: _NotificationCard(
                            notification: notif,
                            onTap: () => notifProvider.markAsRead(notif.id),
                            onDelete: () => notifProvider.deleteNotification(notif.id),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    Color iconFg;
    IconData iconData;

    switch (notification.category) {
      case NotificationCategory.info:
        iconBg = AppColors.lightBlue;
        iconFg = AppColors.primaryBlue;
        iconData = Icons.info_outline_rounded;
        break;
      case NotificationCategory.warning:
        iconBg = AppColors.lightBlue;
        iconFg = AppColors.primaryBlue;
        iconData = Icons.campaign_rounded;
        break;
      case NotificationCategory.emergency:
        iconBg = AppColors.lightBlue;
        iconFg = AppColors.primaryBlue;
        iconData = Icons.notifications_active_rounded;
        break;
      case NotificationCategory.success:
        iconBg = AppColors.lightBlue;
        iconFg = AppColors.primaryBlue;
        iconData = Icons.check_circle_outline_rounded;
        break;
    }

    final formattedTime = DateFormat('h:mm a').format(notification.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF4F8FF),
          borderRadius: AppStyles.radiusMedium,
          border: Border.all(
            color: notification.isRead
                ? AppColors.border.withOpacity(0.6)
                : AppColors.primaryBlue.withOpacity(0.35),
            width: notification.isRead ? 1 : 1.3,
          ),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconFg, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppStyles.heading3.copyWith(
                            fontSize: 15,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: AppStyles.bodySmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.description,
                    style: AppStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      color: notification.isRead ? AppColors.secondaryText : AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
