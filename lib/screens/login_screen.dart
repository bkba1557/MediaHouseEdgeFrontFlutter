import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _otpFocus = FocusNode();

  bool _isLogin = true;
  bool _isAwaitingOtp = false;

  void _submitFromKeyboard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoading) return;
    _submit();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isAwaitingOtp) {
      await _verifyOtp();
    } else {
      await _requestOtp();
    }
  }

  Future<void> _requestOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_isLogin) {
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authProvider.register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;
      setState(() => _isAwaitingOtp = true);
      messenger.showSnackBar(
        const SnackBar(content: Text('تم إرسال رمز التحقق إلى البريد')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _verifyOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_isLogin) {
        await authProvider.verifyLoginOtp(
          _emailController.text.trim(),
          _otpController.text.trim(),
        );
      } else {
        await authProvider.verifyRegisterOtp(
          _emailController.text.trim(),
          _otpController.text.trim(),
        );
      }

      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _guestLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.guestLogin();
      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _isAwaitingOtp = false;
      _otpController.clear();
    });
  }

  void _editEmail() {
    setState(() {
      _isAwaitingOtp = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 600;
    final horizontalPadding = isMobile ? 16.0 : 32.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF050505), Color(0xFF2A0306), Color(0xFFE50914)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 18 : 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1919).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 18 : 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GlowingLogoCircle(
                          size: isMobile ? 120 : 148,
                          logoScale: isMobile ? 3.0 : 2.8,
                          child: Image.asset(
                            'assets/images/media_house_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _isAwaitingOtp
                              ? 'أدخل رمز التحقق'
                              : _isLogin
                                  ? 'تسجيل الدخول'
                                  : 'إنشاء حساب',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAwaitingOtp
                              ? 'أرسلنا كود مكون من 6 أرقام إلى ${_emailController.text.trim()}'
                              : 'استخدم البريد وكلمة المرور، ثم أكد الرمز من الإيميل',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (!_isLogin && !_isAwaitingOtp) ...[
                                _AuthTextField(
                                  controller: _usernameController,
                                  label: 'اسم المستخدم',
                                  icon: Icons.person_outline,
                                  focusNode: _usernameFocus,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      FocusScope.of(context).requestFocus(_emailFocus),
                                  validator: (value) {
                                    if (value == null || value.trim().length < 3) {
                                      return 'اسم المستخدم لا يقل عن 3 أحرف';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                              if (!_isAwaitingOtp) ...[
                                _AuthTextField(
                                  controller: _emailController,
                                  label: 'البريد الإلكتروني',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  focusNode: _emailFocus,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) =>
                                      FocusScope.of(context).requestFocus(_passwordFocus),
                                  validator: (value) {
                                    if (value == null || !value.contains('@')) {
                                      return 'اكتب بريد صحيح';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _AuthTextField(
                                  controller: _passwordController,
                                  label: 'كلمة المرور',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  focusNode: _passwordFocus,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submitFromKeyboard(),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'كلمة المرور لا تقل عن 6 أحرف';
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                _AuthTextField(
                                  controller: _otpController,
                                  label: 'رمز التحقق',
                                  icon: Icons.verified_user_outlined,
                                  keyboardType: TextInputType.number,
                                  focusNode: _otpFocus,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submitFromKeyboard(),
                                  validator: (value) {
                                    if (value == null || value.trim().length != 6) {
                                      return 'اكتب رمز مكون من 6 أرقام';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _editEmail,
                                    child: const Text('تعديل البيانات'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE50914),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: authProvider.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            _isAwaitingOtp
                                                ? 'تأكيد الرمز'
                                                : _isLogin
                                                    ? 'إرسال رمز الدخول'
                                                    : 'إرسال رمز التسجيل',
                                          ),
                                  ),
                                ),
                                if (!_isAwaitingOtp) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: authProvider.isLoading
                                          ? null
                                          : _guestLogin,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Color(0xFFE50914),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('الدخول كزائر'),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(
                            _isLogin
                                ? 'ليس لديك حساب؟ إنشاء حساب'
                                : 'لديك حساب بالفعل؟ تسجيل الدخول',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.focusNode,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE50914)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE50914), width: 1.4),
        ),
      ),
    );
  }
}

class _GlowingLogoCircle extends StatelessWidget {
  final double size;
  final double contentPadding;
  final double logoScale;
  final Widget child;

  const _GlowingLogoCircle({
    required this.size,
    this.contentPadding = 0,
    this.logoScale = 1.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ringPadding = math.max(2.8, size * 0.03);
    final ringWidth = math.max(2.6, size * 0.028);
    // Ensure BoxShadow receives double values (math.max returns num).
    final glowBlur = math.max(22, size * 0.24).toDouble();
    final glowSpread = math.max(2.6, size * 0.03).toDouble();

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringPadding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: ringWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: glowBlur,
            spreadRadius: glowSpread,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(contentPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: ClipOval(
          child: SizedBox.expand(
            child: Center(
              child: Transform.scale(
                scale: logoScale,
                child: FittedBox(fit: BoxFit.contain, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
