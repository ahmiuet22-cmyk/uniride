import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/email_otp_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../shared/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Tab index: 0 = Student, 1 = Driver
  int _selectedTabIndex = 0;

  // Student Sub-Mode: false = Login, true = Register
  bool _isRegisterMode = false;
  int _studentRegStep = 0; // 0 = Fill Details, 1 = Verify OTP
  int _registrationRoleIndex = 0; // 0 = Student, 1 = Staff

  // Student Login Controllers
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;

  // Student Registration Controllers
  final _regNameController = TextEditingController();
  final _regRollNoController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;

  // Staff Registration Controllers
  final _staffNameController = TextEditingController();
  final _staffEmailController = TextEditingController();
  final _staffPasswordController = TextEditingController();
  final _staffConfirmPasswordController = TextEditingController();
  bool _obscureStaffPassword = true;
  bool _obscureStaffConfirmPassword = true;

  // 6-Digit OTP Controllers
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _countdownTimer;

  // Driver Controllers
  final _driverIdController = TextEditingController();
  final _driverPinController = TextEditingController();
  String _selectedBusId = 'bus_gau_2555';
  bool _obscureDriverPin = true;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 0;
    _isRegisterMode = false;
    _studentRegStep = 0;
    _registrationRoleIndex = 0;
    _obscureLoginPassword = true;
    _obscureRegPassword = true;
    _obscureRegConfirmPassword = true;
    _obscureStaffPassword = true;
    _obscureStaffConfirmPassword = true;
    _obscureDriverPin = true;
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regRollNoController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _staffNameController.dispose();
    _staffEmailController.dispose();
    _staffPasswordController.dispose();
    _staffConfirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    _driverIdController.dispose();
    _driverPinController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  /// Handle Student Login (Username / Roll No / Email & Password)
  void _handleStudentLogin() async {
    final usernameOrEmail = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (usernameOrEmail.isEmpty) {
      _showToast('Please enter your username, roll number, or email.', isError: true);
      return;
    }
    if (password.isEmpty) {
      _showToast('Please enter your password.', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.loginWithUsernameAndPassword(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );

    if (res['success'] == true && mounted) {
      HapticFeedback.mediumImpact();
      _showToast('🎓 Welcome back, ${auth.student.name}!', isError: false);
      Navigator.pushReplacementNamed(context, AppRoutes.mainScaffold);
    } else if (mounted) {
      if (res['alreadyLoggedIn'] == true) {
        _showAlreadyLoggedInDialog(res['message'] ?? 'This account is already logged in on another device.');
      } else {
        _showToast(res['message'] ?? 'Login failed. Please try again.', isError: true);
      }
    }
  }

  /// Step 1 of Registration: Validate details & Dispatch OTP to Email
  void _handleSendRegistrationOtp() async {
    final fullName = _regNameController.text.trim();
    final rollNo = _regRollNoController.text.trim();
    final username = _regUsernameController.text.trim();
    final rawEmail = _regEmailController.text.trim();
    final password = _regPasswordController.text.trim();
    final confirmPassword = _regConfirmPasswordController.text.trim();

    if (fullName.isEmpty) {
      _showToast('Please enter your full name.', isError: true);
      return;
    }
    if (rollNo.isEmpty) {
      _showToast('Please enter your roll number (e.g. 2022-CS-123).', isError: true);
      return;
    }
    if (username.isEmpty) {
      _showToast('Please choose a username.', isError: true);
      return;
    }
    if (rawEmail.isEmpty) {
      _showToast('Please enter your email address.', isError: true);
      return;
    }

    String fullEmail = rawEmail.toLowerCase();
    if (!fullEmail.contains('@')) {
      fullEmail = '$fullEmail@student.uet.edu.pk';
      _regEmailController.text = fullEmail;
    }

    final isValidUetEmail = fullEmail.endsWith('@student.uet.edu.pk') || fullEmail.endsWith('@uet.edu.pk');
    if (!isValidUetEmail) {
      _showToast('Please enter a valid UET email (...@uet.edu.pk or ...@student.uet.edu.pk).', isError: true);
      return;
    }

    if (password.length < 4) {
      _showToast('Password must be at least 4 characters long.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showToast('Passwords do not match.', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final otp = await auth.sendRegistrationOtp(
      email: fullEmail,
      studentName: fullName,
    );

    if (otp != null && mounted) {
      setState(() {
        _studentRegStep = 1;
      });
      _startResendTimer();
      _otpFocusNodes[0].requestFocus();

      _showToast('📩 6-Digit OTP sent to ${EmailOtpService.maskEmail(fullEmail)}. Please check your inbox.', isError: false);
    }
  }


  /// Staff Registration Step 1: Validate Name & @uet.edu.pk Outlook Email and Dispatch OTP
  void _handleSendStaffRegistrationOtp() async {
    final fullName = _staffNameController.text.trim();
    final rawEmail = _staffEmailController.text.trim().toLowerCase();
    final password = _staffPasswordController.text.trim();
    final confirmPassword = _staffConfirmPasswordController.text.trim();

    if (fullName.isEmpty) {
      _showToast('Please enter your full name.', isError: true);
      return;
    }
    if (rawEmail.isEmpty) {
      _showToast('Please enter your official @uet.edu.pk email.', isError: true);
      return;
    }

    // Strict validation: Only @uet.edu.pk allowed (excluding student subdomain)
    if (!rawEmail.endsWith('@uet.edu.pk') || rawEmail.contains('@student.')) {
      _showToast('Sirf official UET Outlook email (@uet.edu.pk) allow hai.', isError: true);
      return;
    }

    if (password.length < 4) {
      _showToast('Password must be at least 4 characters long.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showToast('Passwords do not match.', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final otp = await auth.sendRegistrationOtp(
      email: rawEmail,
      studentName: fullName,
    );

    if (otp != null && mounted) {
      setState(() {
        _studentRegStep = 1;
      });
      _startResendTimer();
      _otpFocusNodes[0].requestFocus();

      _showToast('📬 6-Digit OTP sent to Outlook inbox: ${EmailOtpService.maskEmail(rawEmail)}', isError: false);
    }
  }

  /// Step 2 of Registration: Verify OTP and create Student or Staff Account
  void _handleVerifyAndRegister() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      _showToast('Please enter the full 6-digit OTP code.', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_registrationRoleIndex == 1) {
      // Staff / Faculty Member Registration
      final fullName = _staffNameController.text.trim();
      final email = _staffEmailController.text.trim().toLowerCase();
      final password = _staffPasswordController.text.trim();

      final res = await auth.registerStaffWithOtp(
        fullName: fullName,
        email: email,
        password: password,
        enteredOtp: otp,
      );

      if (res['success'] == true && mounted) {
        HapticFeedback.mediumImpact();
        _showToast('💼 Welcome to UniRide, ${auth.student.name} (Faculty/Staff)!', isError: false);
        Navigator.pushReplacementNamed(context, AppRoutes.mainScaffold);
      } else if (mounted) {
        _showToast(res['message'] ?? 'Invalid or expired OTP. Please try again.', isError: true);
      }
    } else {
      // Student Registration
      final fullName = _regNameController.text.trim();
      final rollNo = _regRollNoController.text.trim();
      final username = _regUsernameController.text.trim();
      final email = _regEmailController.text.trim();
      final password = _regPasswordController.text.trim();

      final res = await auth.registerStudentWithOtp(
        fullName: fullName,
        rollNo: rollNo,
        username: username,
        email: email,
        password: password,
        enteredOtp: otp,
      );

      if (res['success'] == true && mounted) {
        HapticFeedback.mediumImpact();
        _showToast('🎓 Account Created! Welcome ${auth.student.name} (${auth.student.department})', isError: false);
        Navigator.pushReplacementNamed(context, AppRoutes.mainScaffold);
      } else if (mounted) {
        _showToast(res['message'] ?? 'Invalid or expired OTP. Please try again.', isError: true);
      }
    }
  }



  void _handleDriverSignIn() async {
    final driverId = _driverIdController.text.trim();
    final pin = _driverPinController.text.trim();

    if (driverId.isEmpty || pin.isEmpty) {
      _showToast('Please enter your Driver ID and Security PIN.', isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    final bus = busProvider.getBusById(_selectedBusId);

    final res = await auth.signInAsDriver(
      driverIdOrPhone: driverId,
      pin: pin,
      busId: _selectedBusId,
      driverName: bus?.driver.name,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      HapticFeedback.mediumImpact();
      final driverName = res['driverName'] ?? auth.driver?.name ?? 'Driver';
      _showToast('👨‍✈️ Driver Duty Activated: $driverName (${bus?.name})', isError: false);
      Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
    } else if (res['alreadyLoggedIn'] == true) {
      HapticFeedback.heavyImpact();
      _showAlreadyLoggedInDialog(res['message'] ?? 'This driver account is already active on another device.');
    } else {
      HapticFeedback.vibrate();
      _showToast(res['message'] ?? 'Authentication failed. Please verify credentials.', isError: true);
    }
  }

  void _handleGuestLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nav = Navigator.of(context);
    await auth.continueAsGuest();
    if (mounted) {
      _showToast('Continuing as Guest Student', isError: false);
      nav.pushReplacementNamed(AppRoutes.mainScaffold);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? Colors.white : AppColors.goldAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusMedium),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAlreadyLoggedInDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCD34D), width: 2),
              ),
              child: const Icon(
                Icons.phonelink_lock_rounded,
                color: Color(0xFFD97706),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Active Device Session Detected',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ek Time Par Sirf 1 Mobile Allowed Hai',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleStudentLogin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Retry Login',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final busProvider = Provider.of<BusProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // University Official Branding Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.goldBorder, width: 2),
                          boxShadow: const [AppColors.cardShadow],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/images/uet_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_bus_rounded,
                            color: AppColors.primaryBlue,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'UniRide Campus Portal',
                        style: AppStyles.heading1.copyWith(
                          fontSize: 22,
                          color: AppColors.primaryBlue,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'UET Gujranwala • RCET Official Transit',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Role Switcher Tab (Student UET / Driver)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [AppColors.softShadow],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedTabIndex = 0;
                            _studentRegStep = 0;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? AppColors.primaryBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_rounded,
                                  size: 18,
                                  color: _selectedTabIndex == 0 ? Colors.white : AppColors.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Students',
                                  style: TextStyle(
                                    color: _selectedTabIndex == 0 ? Colors.white : AppColors.secondaryText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 ? AppColors.primaryBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  size: 18,
                                  color: _selectedTabIndex == 1 ? Colors.white : AppColors.secondaryText,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Driver Duty',
                                  style: TextStyle(
                                    color: _selectedTabIndex == 1 ? Colors.white : AppColors.secondaryText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // MAIN FORM CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppStyles.radiusLarge,
                    border: AppStyles.cardBorder,
                    boxShadow: const [AppColors.softShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedTabIndex == 0) ...[
                        // ================= STUDENT ACCESS (LOGIN / REGISTER) =================
                        
                        // Mode Switcher Header: Login vs Register
                       

                        const SizedBox(height: 18),

                        // MODE 1: STUDENT LOGIN (Username / Roll No & Password)
                        if (!_isRegisterMode) ...[
                          Text(
                            'Username',
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _loginUsernameController,
                            decoration: const InputDecoration(
                              hintText: 'Student or Faculty',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.secondaryBlue),
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            'Password',
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _loginPasswordController,
                            obscureText: _obscureLoginPassword,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.secondaryBlue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureLoginPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.secondaryText,
                                ),
                                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          CustomButton(
                            text: 'LOGIN TO UNIRIDE',
                            icon: Icons.login_rounded,
                            isLoading: auth.isLoading,
                            onPressed: _handleStudentLogin,
                          ),

                          const SizedBox(height: 16),

                          // Switch to Register prompt
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() {
                                _isRegisterMode = true;
                                _studentRegStep = 0;
                              }),
                              child: RichText(
                                text: const TextSpan(
                                  text: "Don't have an account? ",
                                  style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: 'Register here',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ]
                        // MODE 2: REGISTRATION (Student vs Staff)
                        else ...[
                          if (_studentRegStep == 0) ...[
                            // Role Switcher: Student vs Staff
                            Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _registrationRoleIndex = 0),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(
                                          color: _registrationRoleIndex == 0 ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                          boxShadow: _registrationRoleIndex == 0 ? const [AppColors.softShadow] : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.school_rounded,
                                              size: 16,
                                              color: _registrationRoleIndex == 0 ? AppColors.primaryBlue : AppColors.secondaryText,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Student',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                color: _registrationRoleIndex == 0 ? AppColors.primaryBlue : AppColors.secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _registrationRoleIndex = 1),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(
                                          color: _registrationRoleIndex == 1 ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(9),
                                          boxShadow: _registrationRoleIndex == 1 ? const [AppColors.softShadow] : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.work_rounded,
                                              size: 16,
                                              color: _registrationRoleIndex == 1 ? const Color(0xFF0284C7) : AppColors.secondaryText,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Staff / Faculty',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                color: _registrationRoleIndex == 1 ? const Color(0xFF0284C7) : AppColors.secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // A. STUDENT REGISTRATION FORM
                            if (_registrationRoleIndex == 0) ...[
                              Text(
                                'Full Name',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _regNameController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Ahmed Ali',
                                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.secondaryBlue),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Roll Number',
                                          style: AppStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _regRollNoController,
                                          decoration: const InputDecoration(
                                            hintText: '2022-CS-123',
                                            prefixIcon: Icon(Icons.badge_outlined, color: AppColors.secondaryBlue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Username',
                                          style: AppStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _regUsernameController,
                                          decoration: const InputDecoration(
                                            hintText: 'ahmed123',
                                            prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.secondaryBlue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'Email Address (for OTP Verification)',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _regEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'name@uet.edu.pk or 2022cs123@student.uet.edu.pk',
                                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.secondaryBlue),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Password',
                                          style: AppStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _regPasswordController,
                                          obscureText: _obscureRegPassword,
                                          decoration: InputDecoration(
                                            hintText: 'Password',
                                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.secondaryBlue),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confirm Pass',
                                          style: AppStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _regConfirmPasswordController,
                                          obscureText: _obscureRegConfirmPassword,
                                          decoration: InputDecoration(
                                            hintText: 'Confirm',
                                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.secondaryBlue),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureRegConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(() => _obscureRegConfirmPassword = !_obscureRegConfirmPassword),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              CustomButton(
                                text: 'CONTINUE & GET OTP CODE',
                                icon: Icons.send_rounded,
                                isLoading: auth.isLoading,
                                onPressed: _handleSendRegistrationOtp,
                              ),
                            ]
                            // B. STAFF / FACULTY REGISTRATION FORM (@uet.edu.pk ONLY)
                            else ...[
                              

                              Text(
                                'Staff Full Name',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _staffNameController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Dr. Muhammad Tariq ',
                                  prefixIcon: Icon(Icons.badge_outlined, color: Color(0xFF0284C7)),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'Official Email Address ',
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _staffEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                
                                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF0284C7)),
                                  suffixIcon: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '@uet.edu.pk',
                                      style: TextStyle(
                                        color: Color(0xFF0369A1),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Password',
                                          style: AppStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _staffPasswordController,
                                          obscureText: _obscureStaffPassword,
                                          decoration: InputDecoration(
                                            hintText: 'Password',
                                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF0284C7)),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureStaffPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(() => _obscureStaffPassword = !_obscureStaffPassword),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confirm Pass',
                                          style: AppStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextFormField(
                                          controller: _staffConfirmPasswordController,
                                          obscureText: _obscureStaffConfirmPassword,
                                          decoration: InputDecoration(
                                            hintText: 'Confirm',
                                            prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF0284C7)),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureStaffConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                              onPressed: () => setState(() => _obscureStaffConfirmPassword = !_obscureStaffConfirmPassword),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              CustomButton(
                                text: 'SEND OTP TO OUTLOOK EMAIL',
                                icon: Icons.mark_email_read_rounded,
                                isLoading: auth.isLoading,
                                onPressed: _handleSendStaffRegistrationOtp,
                              ),
                            ],

                            const SizedBox(height: 14),

                            Center(
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _isRegisterMode = false;
                                  _studentRegStep = 0;
                                }),
                                child: RichText(
                                  text: const TextSpan(
                                    text: 'Already have an account? ',
                                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                                    children: [
                                      TextSpan(
                                        text: 'Login here',
                                        style: TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // Step 1: 6-Digit OTP Verification
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _registrationRoleIndex == 1
                                      ? 'Verify Outlook Email (OTP)'
                                      : 'Verify Email (6-Digit OTP)',
                                  style: AppStyles.heading3.copyWith(fontSize: 15),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                  icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryBlue),
                                  label: const Text('Edit Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  onPressed: () => setState(() => _studentRegStep = 0),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _registrationRoleIndex == 1
                                  ? 'Code sent to Outlook inbox: ${EmailOtpService.maskEmail(_staffEmailController.text)} (@uet.edu.pk)'
                                  : 'Code sent to ${EmailOtpService.maskEmail(_regEmailController.text)}',
                              style: AppStyles.bodySmall.copyWith(
                                color: _registrationRoleIndex == 1 ? const Color(0xFF0284C7) : AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // 6 Digit PIN Boxes
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (i) {
                                return SizedBox(
                                  width: 44,
                                  height: 52,
                                  child: TextFormField(
                                    controller: _otpControllers[i],
                                    focusNode: _otpFocusNodes[i],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryBlue,
                                    ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(1),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    enabled: !auth.isLoading,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      if (val.isNotEmpty && i < 5) {
                                        _otpFocusNodes[i + 1].requestFocus();
                                      } else if (val.isEmpty && i > 0) {
                                        _otpFocusNodes[i - 1].requestFocus();
                                      }
                                      if (_enteredOtp.length == 6 && !auth.isLoading) {
                                        _handleVerifyAndRegister();
                                      }
                                    },
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 16),

                            // Resend OTP Counter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _resendCountdown > 0 ? 'Resend code in ${_resendCountdown}s' : 'Did not receive code?',
                                  style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                                ),
                                if (_resendCountdown == 0)
                                  auth.isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                            ),
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: _registrationRoleIndex == 1
                                              ? _handleSendStaffRegistrationOtp
                                              : _handleSendRegistrationOtp,
                                          child: const Text('Resend OTP', style: TextStyle(fontWeight: FontWeight.w700)),
                                        ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Security Banner

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF15803D)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'SHA-256 Encrypted • Single-Use • 5 Min Expiry',
                                      style: AppStyles.bodySmall.copyWith(
                                        color: const Color(0xFF166534),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            CustomButton(
                              text: _registrationRoleIndex == 1
                                  ? 'VERIFY & CREATE STAFF ACCOUNT'
                                  : 'VERIFY & CREATE ACCOUNT',
                              icon: Icons.verified_user_rounded,
                              isLoading: auth.isLoading,
                              onPressed: _handleVerifyAndRegister,
                            ),
                          ],
                        ],

                      ] else ...[
                        Text(
                          'Driver ID / Mobile Number',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _driverIdController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. drv_01 or 0300-1234567',
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: AppColors.secondaryBlue,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Assigned Bus Fleet',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: busProvider.buses.any((b) => b.id == _selectedBusId)
                              ? _selectedBusId
                              : (busProvider.buses.isNotEmpty ? busProvider.buses.first.id : _selectedBusId),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.directions_bus_rounded, color: AppColors.secondaryBlue),
                          ),
                          items: busProvider.buses.map((b) {
                            return DropdownMenuItem<String>(
                              value: b.id,
                              child: Text(
                                b.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBusId = val);
                            }
                          },
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Driver Security PIN',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _driverPinController,
                          obscureText: _obscureDriverPin,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter 4-digit security PIN',
                            prefixIcon: const Icon(
                              Icons.pin_outlined,
                              color: AppColors.secondaryBlue,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureDriverPin
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.secondaryText,
                              ),
                              onPressed: () => setState(() => _obscureDriverPin = !_obscureDriverPin),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusMedium),
                              elevation: 2,
                            ),
                            onPressed: auth.isLoading ? null : _handleDriverSignIn,
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.sensors_rounded, color: AppColors.goldAccent),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Enter Driver Console',
                                        style: AppStyles.buttonText.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Continue as Guest Student Option
                Center(
                  child: TextButton.icon(
                    onPressed: _handleGuestLogin,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border, width: 1.2),
                      ),
                      elevation: 1,
                      shadowColor: Colors.black.withOpacity(0.04),
                    ),
                    icon: const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    label: const Text(
                      'Continue as Guest',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Security footer
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.mutedText),
                      const SizedBox(width: 6),
                      Text(
                        'Authorized UET Gujranwala Campus Network',
                        style: AppStyles.bodySmall.copyWith(color: AppColors.mutedText),
                      ),
                    ],
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
