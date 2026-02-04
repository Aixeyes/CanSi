import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'user_session.dart';

/// 로그인 화면에서 공통으로 사용하는 색상 팔레트.
class LoginPalette {
  static const Color primary = Color(0xFF137FEC);
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF101922);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

/// 이메일/비밀번호 및 소셜 로그인 진입점을 제공하는 화면.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignupClick;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSignupClick,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// 로그인 입력 상태와 컨트롤러를 관리하는 상태 객체.
class _LoginScreenState extends State<LoginScreen> {
  bool _showPassword = false;

  // 입력 컨트롤러는 화면 생명주기에 맞춰 생성/해제한다.
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  static const String _googleLoginUrl = 'https://accounts.google.com/';
  static const String _appleLoginUrl = 'https://appleid.apple.com/';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final trimmedEmail = _email.text.trim();
    final trimmedPassword = _password.text.trim();

    if (trimmedEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일을 입력해주세요.')),
        );
      }
      return;
    }

    if (trimmedPassword.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호를 입력해주세요.')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uri = Uri.parse('http://3.38.43.65:8000/login');
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': trimmedEmail,
          'password': trimmedPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Login failed: ${response.statusCode} ${response.body}',
        );
      }

      UserSession.email = trimmedEmail;
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      widget.onLogin();
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 실패: $error')));
      }
    }
  }

  /// 소셜 로그인 URL을 외부 브라우저로 연다.
  Future<void> _openSocialLogin(String url) async {
    // Launch external login flow; app-side OAuth is out of scope here.
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 페이지를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginPalette.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // 스크롤 가능한 중앙 카드 형태 레이아웃.
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 로고 + 타이틀.
                      const _LogoMark(),
                      const SizedBox(height: 18),
                      const Text(
                        'CanSi',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: LoginPalette.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'AI를 활용한 계약서 분석.\n계속하려면 로그인을 하세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: LoginPalette.textMuted,
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      // 이메일 입력.
                      _InputGroup(
                        label: '이메일',
                        child: _InputField(
                          controller: _email,
                          hintText: 'name@gmail.com',
                          prefixIcon: Icons.mail_outline_rounded,
                          obscureText: false,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 비밀번호 입력과 보기 토글.
                      _InputGroup(
                        label: '비밀번호',
                        child: _InputField(
                          controller: _password,
                          hintText: '••••••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: !_showPassword,
                          suffixIcon: _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          onSuffixTap: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 비밀번호 찾기.
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: LoginPalette.primary,
                          ),
                          child: const Text(
                            '비밀번호를 잊으셨나요?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 기본 로그인 버튼.
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LoginPalette.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                            shadowColor: LoginPalette.primary.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '로그인',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 20,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 소셜 로그인 구분선 및 버튼.
                      const _DividerLabel(label: '소셜 계정으로 로그인'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialCircleButton(
                            tooltip: 'Login with Google',
                            backgroundColor: Colors.white,
                            icon: _GoogleIcon(),
                            onTap: () => _openSocialLogin(_googleLoginUrl),
                          ),
                          const SizedBox(width: 16),
                          _SocialCircleButton(
                            tooltip: 'Login with Apple',
                            backgroundColor: Colors.black,
                            icon: const Icon(Icons.apple, color: Colors.white),
                            onTap: () => _openSocialLogin(_appleLoginUrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 회원가입 링크.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "게정이 없으신가요?",
                            style: TextStyle(
                              color: LoginPalette.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: widget.onSignupClick,
                            child: const Text(
                              '회원가입',
                              style: TextStyle(
                                color: LoginPalette.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상단 브랜드 로고 블록.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      // 로고 배경 카드 스타일.
      decoration: BoxDecoration(
        color: LoginPalette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LoginPalette.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        // 로고 아이콘.
        child: Icon(Icons.gavel_rounded, color: LoginPalette.primary, size: 40),
      ),
    );
  }
}

/// 라벨과 입력 필드를 묶어 보여주는 구성요소.
class _InputGroup extends StatelessWidget {
  final String label;
  final Widget child;

  const _InputGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: LoginPalette.textDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// 보조 아이콘 동작을 지원하는 입력 필드.
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.obscureText,
    this.suffixIcon,
    this.onSuffixTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: LoginPalette.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
      ),
      decoration: InputDecoration(
        // 힌트와 아이콘을 포함한 공통 입력 스타일.
        hintText: hintText,
        hintStyle: TextStyle(
          color: LoginPalette.textMuted.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        prefixIcon: Icon(prefixIcon, color: LoginPalette.textMuted),
        suffixIcon: suffixIcon == null
            ? null
            : IconButton(
                icon: Icon(suffixIcon, color: LoginPalette.textMuted),
                onPressed: onSuffixTap,
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LoginPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LoginPalette.primary, width: 1.2),
        ),
      ),
    );
  }
}

/// 가운데 라벨이 있는 구분선.
class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: LoginPalette.border, height: 1)),
        const SizedBox(width: 10),
        Text(
          label,
          // 구분선 중앙 라벨.
          style: const TextStyle(
            color: LoginPalette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: LoginPalette.border, height: 1)),
      ],
    );
  }
}

/// 소셜 로그인에 사용하는 원형 아이콘 버튼.
class _SocialCircleButton extends StatelessWidget {
  final String tooltip;
  final Color backgroundColor;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialCircleButton({
    required this.tooltip,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          // 각 소셜 로그인에 맞는 콜백을 위에서 주입.
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 55, height: 55, child: Center(child: icon)),
        ),
      ),
    );
  }
}

/// 인라인 SVG로 그린 구글 로고 아이콘.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _googleLogoSvg,
      width: 25,
      height: 25,
      fit: BoxFit.contain,
    );
  }
}

/// 소셜 버튼에서 사용하는 구글 로고 SVG.
const String _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" aria-hidden="true">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>
''';
