import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/animations/route_draw_painter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _busDriveController;
  late AnimationController _routeController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _busSlide;
  late Animation<double> _busScale;
  late Animation<double> _busGlow;
  late Animation<double> _routeProgress;
  late Animation<double> _busPinPosition;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // 1. Bus driving entrance animation
    _busDriveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _busSlide = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(parent: _busDriveController, curve: Curves.easeOutCubic),
    );
    _busScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _busDriveController, curve: Curves.easeOutBack),
    );
    _busGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _busDriveController, curve: Curves.easeIn),
    );

    // 2. Route track draw animation
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _routeProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _routeController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      ),
    );
    _busPinPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _routeController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // 3. Text reveal animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // 4. Subtle continuous floating idle pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _playSplashSequence();
  }

  void _playSplashSequence() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await _busDriveController.forward();
    _routeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    // Wait until local persistent auth state has finished reading from disk
    await auth.ensureInitialized();

    if (!mounted) return;

    if (auth.isLoggedIn) {
      // Validate that this physical device holds the active session
      final isValidSession = await auth.verifyActiveSession();
      if (!isValidSession && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }

      if (!mounted) return;
      if (auth.isDriver) {
        Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.mainScaffold);
      }
    } else if (!auth.onboardingCompleted) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _busDriveController.dispose();
    _routeController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle ambient background circles
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightBlue.withOpacity(0.5),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightBlue.withOpacity(0.3),
                ),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final maxH = constraints.maxHeight;
                final busImageHeight = (maxH * 0.22).clamp(110.0, 175.0);
                final verticalGap = (maxH * 0.02).clamp(8.0, 20.0);

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: maxH),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),

                          // Top Campus Badge
                          FadeTransition(
                            opacity: _textFade,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryBlue.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school_rounded,
                                    size: 15,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'UET GUJRANWALA (RCET)',
                                    style: AppStyles.badgeText.copyWith(
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: verticalGap),

                          // ANIMATED UET HINO BUS HERO
                          AnimatedBuilder(
                            animation: Listenable.merge([_busDriveController, _pulseController]),
                            builder: (context, child) {
                              final floatOffset = (_pulseController.value - 0.5) * 5;

                              return Transform.translate(
                                offset: Offset(_busSlide.value, floatOffset),
                                child: Transform.scale(
                                  scale: _busScale.value,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Opacity(
                                        opacity: _busGlow.value * 0.45,
                                        child: Container(
                                          width: 260,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                AppColors.secondaryBlue.withOpacity(0.4),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Real UET Bus Image with responsive bounds
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth: 300,
                                          maxHeight: busImageHeight,
                                        ),
                                        child: Image.asset(
                                          'assets/images/uet_bus.png',
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.directions_bus_rounded,
                                              size: 80,
                                              color: AppColors.primaryBlue,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Animated Road Track Curve with Moving GPS Node
                          SizedBox(
                            width: 260,
                            height: 40,
                            child: AnimatedBuilder(
                              animation: _routeController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: RouteDrawPainter(
                                    progress: _routeProgress.value,
                                    busPosition: _busPinPosition.value,
                                  ),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: verticalGap),

                          // Text Reveal: UniRide & Tagline
                          SlideTransition(
                            position: _textSlide,
                            child: FadeTransition(
                              opacity: _textFade,
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.goldBorder.withOpacity(0.6), width: 1.5),
                                      boxShadow: const [AppColors.cardShadow],
                                    ),
                                    padding: const EdgeInsets.all(5),
                                    child: Image.asset(
                                      'assets/images/uet_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const SizedBox(),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Uni',
                                        style: AppStyles.heading1.copyWith(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryText,
                                        ),
                                      ),
                                      Text(
                                        'Ride',
                                        style: AppStyles.heading1.copyWith(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.goldAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.appTagline,
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.secondaryText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: verticalGap),

                          // Bottom Campus Transport Status Tag
                          FadeTransition(
                            opacity: _textFade,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: AppStyles.cardBorder,
                                boxShadow: const [AppColors.cardShadow],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.goldAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'RCET Shuttle Fleet',
                                    style: AppStyles.bodySmall.copyWith(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
