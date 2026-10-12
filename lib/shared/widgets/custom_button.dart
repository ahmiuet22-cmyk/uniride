import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 54,
    this.padding,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = widget.backgroundColor ??
        (widget.isOutlined ? Colors.transparent : AppColors.primaryBlue);
    final effectiveFg = widget.textColor ??
        (widget.isOutlined ? AppColors.primaryBlue : Colors.white);

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: GestureDetector(
          onTapDown: widget.onPressed != null && !widget.isLoading
              ? (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _isPressed = true);
                }
              : null,
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: effectiveBg,
              foregroundColor: effectiveFg,
              elevation: widget.isOutlined ? 0 : 2,
              shadowColor: widget.isOutlined
                  ? Colors.transparent
                  : AppColors.primaryBlue.withOpacity(0.35),
              side: widget.isOutlined
                  ? BorderSide(color: effectiveFg, width: 1.5)
                  : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.radiusMedium,
              ),
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: effectiveFg),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          style: AppStyles.buttonText.copyWith(
                            color: effectiveFg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
