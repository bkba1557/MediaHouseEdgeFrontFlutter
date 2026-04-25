import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';

enum _LoginMethod { password, emailOtp }

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
  _LoginMethod _loginMethod = _LoginMethod.password;

  bool get _showsPasswordField =>
      !_isAwaitingOtp && (!_isLogin || _loginMethod == _LoginMethod.password);

  bool get _supportsGoogle =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  bool get _supportsApple =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String _localizedPair(
    BuildContext context, {
    required String ar,
    required String en,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'ar' ? ar : en;
  }

  void _submitFromKeyboard() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;
    _submit();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isAwaitingOtp) {
      await _verifyOtp();
      return;
    }

    if (_isLogin) {
      if (_loginMethod == _LoginMethod.password) {
        await _loginWithPassword();
      } else {
        await _requestLoginOtp();
      }
      return;
    }

    await _requestRegisterOtp();
  }

  Future<void> _loginWithPassword() async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.loginWithPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

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

  Future<void> _requestLoginOtp() async {
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.requestLoginOtp(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _isAwaitingOtp = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _localizedPair(
              context,
              ar: 'تم إرسال رمز الدخول إلى بريدك الإلكتروني',
              en: 'A login code was sent to your email',
            ),
          ),
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_otpFocus);
        }
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _requestRegisterOtp() async {
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isAwaitingOtp = true);
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('تم إرسال رمز التحقق إلى البريد'))),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_otpFocus);
        }
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _verifyOtp() async {
    final authProvider = context.read<AuthProvider>();
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

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.signInWithGoogle();
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

  Future<void> _signInWithApple() async {
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.signInWithApple();
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
    final authProvider = context.read<AuthProvider>();
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
      _resetOtpState();
    });
  }

  void _editEmail() {
    setState(_resetOtpState);
  }

  void _selectLoginMethod(_LoginMethod method) {
    if (_loginMethod == method) return;
    setState(() {
      _loginMethod = method;
      _resetOtpState();
    });
  }

  void _resetOtpState() {
    _isAwaitingOtp = false;
    _otpController.clear();
  }

  String _subtitleText(BuildContext context) {
    if (_isAwaitingOtp) {
      return context.tr(
        'أرسلنا كود مكون من 6 أرقام إلى {email}',
        params: {'email': _emailController.text.trim()},
      );
    }

    if (!_isLogin) {
      return context.tr('استخدم البريد وكلمة المرور، ثم أكد الرمز من الإيميل');
    }

    if (_loginMethod == _LoginMethod.password) {
      return _localizedPair(
        context,
        ar: 'استخدم البريد الإلكتروني وكلمة المرور للدخول مباشرة بدون رمز تحقق.',
        en: 'Use your email and password to sign in directly without a verification code.',
      );
    }

    return _localizedPair(
      context,
      ar: 'اكتب بريدك الإلكتروني فقط وسنرسل لك رمز دخول مكونًا من 6 أرقام.',
      en: 'Enter your email only and we will send you a 6-digit login code.',
    );
  }

  String _submitLabel(BuildContext context) {
    if (_isAwaitingOtp) {
      return context.tr('تأكيد الرمز');
    }

    if (!_isLogin) {
      return context.tr('إرسال رمز التسجيل');
    }

    if (_loginMethod == _LoginMethod.password) {
      return _localizedPair(
        context,
        ar: 'الدخول بكلمة المرور',
        en: 'Sign In with Password',
      );
    }

    return context.tr('إرسال رمز الدخول');
  }

  String _socialDividerLabel(BuildContext context) {
    return _localizedPair(
      context,
      ar: 'أو أكمل بواسطة',
      en: 'Or continue with',
    );
  }

  String _socialHintLabel(BuildContext context) {
    if (_isLogin) {
      return _localizedPair(
        context,
        ar: 'دخول سريع باستخدام حسابك المرتبط',
        en: 'Fast access using your linked account',
      );
    }

    return _localizedPair(
      context,
      ar: 'يمكنك إنشاء الحساب والمتابعة مباشرة',
      en: 'Create your account and continue instantly',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 600;
    final horizontalPadding = isMobile ? 16.0 : 32.0;

    return Scaffold(
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
                        size: isMobile ? 140 : 180,
                        contentPadding: isMobile ? 5 : 7,
                        logoScale: isMobile ? 1.35 : 1.42,
                        child: Image.asset(
                          'assets/images/media_house_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isAwaitingOtp
                            ? context.tr('أدخل رمز التحقق')
                            : _isLogin
                            ? context.tr('تسجيل الدخول')
                            : context.tr('إنشاء حساب'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitleText(context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      if (_isLogin && !_isAwaitingOtp) ...[
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _LoginMethodButton(
                                  icon: Icons.lock_outline,
                                  label: _localizedPair(
                                    context,
                                    ar: 'كلمة المرور',
                                    en: 'Password',
                                  ),
                                  isSelected:
                                      _loginMethod == _LoginMethod.password,
                                  onPressed: () =>
                                      _selectLoginMethod(_LoginMethod.password),
                                ),
                              ),
                              Expanded(
                                child: _LoginMethodButton(
                                  icon: Icons.email_outlined,
                                  label: _localizedPair(
                                    context,
                                    ar: 'رمز عبر البريد',
                                    en: 'Email Code',
                                  ),
                                  isSelected:
                                      _loginMethod == _LoginMethod.emailOtp,
                                  onPressed: () =>
                                      _selectLoginMethod(_LoginMethod.emailOtp),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin && !_isAwaitingOtp) ...[
                              _AuthTextField(
                                controller: _usernameController,
                                label: context.tr('اسم المستخدم'),
                                icon: Icons.person_outline,
                                focusNode: _usernameFocus,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_emailFocus),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 3) {
                                    return context.tr(
                                      'اسم المستخدم لا يقل عن 3 أحرف',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (!_isAwaitingOtp) ...[
                              _AuthTextField(
                                controller: _emailController,
                                label: context.tr('البريد الإلكتروني'),
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                focusNode: _emailFocus,
                                textInputAction: _showsPasswordField
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onSubmitted: (_) {
                                  if (_showsPasswordField) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_passwordFocus);
                                  } else {
                                    _submitFromKeyboard();
                                  }
                                },
                                validator: (value) {
                                  if (value == null || !value.contains('@')) {
                                    return context.tr('اكتب بريد صحيح');
                                  }
                                  return null;
                                },
                              ),
                              if (_showsPasswordField) ...[
                                const SizedBox(height: 14),
                                _AuthTextField(
                                  controller: _passwordController,
                                  label: context.tr('كلمة المرور'),
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  focusNode: _passwordFocus,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submitFromKeyboard(),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return context.tr(
                                        'كلمة المرور لا تقل عن 6 أحرف',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ] else ...[
                              _AuthTextField(
                                controller: _otpController,
                                label: context.tr('رمز التحقق'),
                                icon: Icons.verified_user_outlined,
                                keyboardType: TextInputType.number,
                                focusNode: _otpFocus,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submitFromKeyboard(),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length != 6) {
                                    return context.tr(
                                      'اكتب رمز مكون من 6 أرقام',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _editEmail,
                                  child: Text(context.tr('تعديل البيانات')),
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
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : _submit,
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
                                      : Text(_submitLabel(context)),
                                ),
                              ),
                              if (!_isAwaitingOtp) ...[
                                const SizedBox(height: 18),
                                _AuthDivider(
                                  label: _socialDividerLabel(context),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _socialHintLabel(context),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    if (_supportsGoogle)
                                      SizedBox(
                                        width: isMobile ? double.infinity : 220,
                                        child: _SocialAuthButton(
                                          assetPath:
                                              'assets/images/login_google.png',
                                          label: _localizedPair(
                                            context,
                                            ar: 'المتابعة عبر Google',
                                            en: 'Continue with Google',
                                          ),
                                          onPressed: authProvider.isLoading
                                              ? null
                                              : _signInWithGoogle,
                                        ),
                                      ),
                                    if (_supportsApple)
                                      SizedBox(
                                        width: isMobile ? double.infinity : 220,
                                        child: _SocialAuthButton(
                                          assetPath:
                                              'assets/images/login_apple.png',
                                          label: _localizedPair(
                                            context,
                                            ar: 'المتابعة عبر Apple',
                                            en: 'Continue with Apple',
                                          ),
                                          onPressed: authProvider.isLoading
                                              ? null
                                              : _signInWithApple,
                                        ),
                                      ),
                                  ],
                                ),
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
                                    child: Text(context.tr('الدخول كزائر')),
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
                              ? context.tr('ليس لديك حساب؟ إنشاء حساب')
                              : context.tr('لديك حساب بالفعل؟ تسجيل الدخول'),
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

class _LoginMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _LoginMethodButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        backgroundColor: isSelected
            ? const Color(0xFFE50914)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  final String label;

  const _AuthDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.16),
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(alpha: 0.16),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback? onPressed;

  const _SocialAuthButton({
    required this.assetPath,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isApple = assetPath.contains('apple');

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  assetPath,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _SocialIconFallback(isApple: isApple);
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIconFallback extends StatelessWidget {
  final bool isApple;

  const _SocialIconFallback({required this.isApple});

  @override
  Widget build(BuildContext context) {
    if (isApple) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.apple, color: Colors.black, size: 18),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
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
    final ringPadding = math.max(6.0, size * 0.05).toDouble();
    final outerShadowBlur = math.max(18.0, size * 0.11).toDouble();
    final outerShadowOffset = math.max(6.0, size * 0.04).toDouble();

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringPadding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: outerShadowBlur,
            offset: Offset(0, outerShadowOffset),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(contentPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF3F3F3),
          border: Border.all(
            color: const Color(0xFFB8B8B8).withValues(alpha: 0.95),
            width: math.max(1.4, size * 0.012).toDouble(),
          ),
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
