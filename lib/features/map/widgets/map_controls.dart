import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../providers/bus_provider.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onLocateMe;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final BusFilterOption selectedFilter;
  final Function(BusFilterOption) onFilterChanged;

  const MapControls({
    super.key,
    required this.onLocateMe,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Filter Chips Row at Top
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip('All Buses', BusFilterOption.all),
              const SizedBox(width: 8),
              _buildFilterChip('Active', BusFilterOption.active),
              const SizedBox(width: 8),
              _buildFilterChip('Approaching', BusFilterOption.approaching),
              const SizedBox(width: 8),
              _buildFilterChip('Delayed', BusFilterOption.delayed),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Zoom and Locate Controls Floating Column
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: AppStyles.cardBorder,
            boxShadow: const [AppColors.softShadow],
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.my_location_rounded, color: AppColors.primaryBlue),
                tooltip: 'Locate Me',
                onPressed: onLocateMe,
              ),
              const Divider(height: 1, indent: 6, endIndent: 6),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primaryText),
                tooltip: 'Zoom In',
                onPressed: onZoomIn,
              ),
              const Divider(height: 1, indent: 6, endIndent: 6),
              IconButton(
                icon: const Icon(Icons.remove_rounded, color: AppColors.primaryText),
                tooltip: 'Zoom Out',
                onPressed: onZoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, BusFilterOption option) {
    final isSelected = selectedFilter == option;

    return GestureDetector(
      onTap: () => onFilterChanged(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border,
            width: 1.2,
          ),
          boxShadow: const [AppColors.cardShadow],
        ),
        child: Text(
          label,
          style: AppStyles.badgeText.copyWith(
            color: isSelected ? Colors.white : AppColors.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
