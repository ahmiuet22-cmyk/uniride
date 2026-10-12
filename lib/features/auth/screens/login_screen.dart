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
    _obscureLoginPassword = true;
    _obscureRegPassword = true;
    _obscureRegConfirmPassword = true;
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
      _showToast(res['message'] ?? 'Login failed. Please try again.', isError: true);
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

    if (!fullEmail.endsWith('@student.uet.edu.pk')) {
      _showToast('Please enter a valid UET student email (...@student.uet.edu.pk).', isError: true);
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


  /// Step 2 of Registration: Verify OTP and create Student Account
  void _handleVerifyAndRegister() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      _showToast('Please enter the full 6-digit OTP code.', isError: true);
      return;
    }

    final fullName = _regNameController.text.trim();
    final rollNo = _regRollNoController.text.trim();
    final username = _regUsernameController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text.trim();
    final auth = Provider.of<AuthProvider>(context, listen: false);

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

    final success = await auth.signInAsDriver(
      driverIdOrPhone: driverId,
      pin: pin,
      busId: _selectedBusId,
      driverName: bus?.driver.name,
    );

    if (success && mounted) {
      _showToast('Driver Duty Activated: ${auth.driver?.name} (${bus?.name})', isError: false);
      Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
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
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _isRegisterMode = false;
                                    _studentRegStep = 0;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: !_isRegisterMode ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: !_isRegisterMode ? const [AppColors.softShadow] : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Student Login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                          color: !_isRegisterMode ? AppColors.primaryBlue : AppColors.secondaryText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                            ],
                          ),
                        ),

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
                              hintText: 'username',
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
                        // MODE 2: STUDENT REGISTRATION (Roll No + Username + Password + Email OTP)
                        else ...[
                          if (_studentRegStep == 0) ...[
                            // Step 0: Fill Registration Details
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
                                hintText: '2022-cs-123@student.uet.edu.pk',
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
                                  'Verify Email (6-Digit OTP)',
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
                              'Code sent to ${EmailOtpService.maskEmail(_regEmailController.text)}',
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.primaryBlue,
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
                                      if (_enteredOtp.length == 6) {
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
                                  TextButton(
                                    onPressed: _handleSendRegistrationOtp,
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
                              text: 'VERIFY & CREATE ACCOUNT',
                              icon: Icons.verified_user_rounded,
                              isLoading: auth.isLoading,
                              onPressed: _handleVerifyAndRegister,
                            ),
                          ],
                        ],

                      ] else ...[
                        // ================= DRIVER LOGIN FORM =================
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
