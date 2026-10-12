import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../providers/bus_provider.dart';
import '../../../shared/widgets/custom_button.dart';

class ReportIssueDialog extends StatefulWidget {
  final String busId;
  final String busName;

  const ReportIssueDialog({
    super.key,
    required this.busId,
    required this.busName,
  });

  @override
  State<ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<ReportIssueDialog> {
  final List<String> _issues = [
    'Bus is late',
    'Bus is overcrowded',
    'Bus is damaged or dirty',
    'Driver rash driving',
    'Route altered without notice',
    'Other issue',
  ];

  int _selectedIssueIndex = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() => _isSubmitting = true);
    final provider = Provider.of<BusProvider>(context, listen: false);

    await provider.reportBusIssue(
      busId: widget.busId,
      issueType: _issues[_selectedIssueIndex],
      description: _commentController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Report submitted for ${widget.busName}. Thank you!'),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusLarge),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.report_problem_rounded, color: AppColors.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Report Bus Issue', style: AppStyles.heading3),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reporting for ${widget.busName}',
                style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),

              const SizedBox(height: 16),

              // Issue choices
              ...List.generate(_issues.length, (index) {
                final isSelected = _selectedIssueIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIssueIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.lightBlue : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          size: 18,
                          color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _issues[index],
                            style: AppStyles.bodyMedium.copyWith(
                              color: isSelected ? AppColors.primaryBlue : AppColors.primaryText,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Additional notes
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Additional details (optional)...',
                ),
              ),

              const SizedBox(height: 20),

              CustomButton(
                text: 'Submit Report',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
