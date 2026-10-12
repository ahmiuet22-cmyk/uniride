import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/stop_model.dart';
import '../../../providers/favorites_provider.dart';

import '../../../shared/widgets/skeleton_loader.dart';

class FavoriteStopsCarousel extends StatelessWidget {
  final Function(BusStopModel) onStopTap;

  const FavoriteStopsCarousel({
    super.key,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoritesProvider>(context);
    final stops = favProvider.favoriteStops;

    if (!favProvider.isLoaded) {
      return SizedBox(
        height: 124,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => const SkeletonLoader(
            width: 168,
            height: 124,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );
    }

    if (stops.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: AppStyles.radiusMedium,
          border: AppStyles.cardBorder,
        ),
        child: Column(
          children: [
            const Icon(Icons.star_outline_rounded, size: 32, color: AppColors.mutedText),
            const SizedBox(height: 8),
            Text('No favorite stops yet', style: AppStyles.heading3.copyWith(fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Save your frequent stops for quick ETA access.',
              style: AppStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final stop = stops[index];
          return _FavoriteStopCard(
            stop: stop,
            onTap: () => onStopTap(stop),
            onToggleFavorite: () => favProvider.toggleFavorite(stop.id),
          );
        },
      ),
    );
  }
}

class _FavoriteStopCard extends StatefulWidget {
  final BusStopModel stop;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _FavoriteStopCard({
    required this.stop,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  State<_FavoriteStopCard> createState() => _FavoriteStopCardState();
}

class _FavoriteStopCardState extends State<_FavoriteStopCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppStyles.radiusMedium,
            border: AppStyles.cardBorder,
            boxShadow: const [AppColors.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldBorder.withOpacity(0.6)),
                    ),
                    child: Text(
                      widget.stop.morningTiming.isNotEmpty
                          ? widget.stop.morningTiming
                          : '${widget.stop.defaultEtaMinutes} min',
                      style: AppStyles.badgeText.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onToggleFavorite();
                    },
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.goldAccent,
                      size: 22,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.stop.name,
                    style: AppStyles.heading3.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.stop.servingBusIds.length} buses stopping',
                    style: AppStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
