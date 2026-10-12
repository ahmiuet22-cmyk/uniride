import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = const [
    OnboardingItem(
      title: AppStrings.onb1Title,
      subtitle: AppStrings.onb1Desc,
      icon: Icons.alt_route_rounded,
      badgeText: 'OFFICIAL ROUTES',
      accentColor: AppColors.primaryBlue,
    ),
    OnboardingItem(
      title: AppStrings.onb2Title,
      subtitle: AppStrings.onb2Desc,
      icon: Icons.access_time_rounded,
      badgeText: 'VERIFIED TIMINGS',
      accentColor: AppColors.goldAccent,
    ),
    OnboardingItem(
      title: AppStrings.onb3Title,
      subtitle: AppStrings.onb3Desc,
      icon: Icons.campaign_rounded,
      badgeText: 'CAMPUS NOTICES',
      accentColor: AppColors.primaryBlue,
    ),
  ];

  void _finishOnboarding() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.completeOnboarding();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                'Skip',
                style: AppStyles.buttonText.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stylized Illustration Container
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.12),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Decorative concentric circles
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.9),
                                  boxShadow: const [AppColors.softShadow],
                                ),
                              ),
                              Container(
                                width: 90,
                                height: 90,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: [AppColors.blueGlow],
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 46,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.badgeText,
                            style: AppStyles.badgeText.copyWith(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Title
                        Text(
                          item.title,
                          style: AppStyles.heading1.copyWith(
                            fontSize: 28,
                            color: AppColors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          item.subtitle,
                          style: AppStyles.bodyLarge.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator and Bottom Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primaryBlue
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Button
                  CustomButton(
                    text: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    icon: _currentPage == _pages.length - 1
                        ? Icons.arrow_forward_rounded
                        : null,
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;
  final Color accentColor;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
    required this.accentColor,
  });
}
