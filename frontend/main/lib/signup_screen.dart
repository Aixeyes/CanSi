import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'user_session.dart';

/// 회원가입 화면에서 공통으로 사용하는 색상 팔레트.
class SignupPalette {
  static const Color primary = Color(0xFF137FEC);
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF101922);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color fieldFill = Color(0xFFF8FAFC);
}

/// 회원가입 화면.
class SignupScreen extends StatefulWidget {
  final VoidCallback onSignup;
  final VoidCallback onBackToLogin;

  const SignupScreen({
    super.key,
    required this.onSignup,
    required this.onBackToLogin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

/// 회원가입 입력 상태 및 유효성 검사를 관리하는 상태 객체.
class _SignupScreenState extends State<SignupScreen> {
  bool _showPassword = false;
  int _strengthScore = 0;
  String _strengthLabel = 'Weak';
  Color _strengthColor = const Color(0xFFF87171);
  bool _isEmailValid = false;

  // 입력 컨트롤러는 화면 생명주기에 맞춰 관리한다.
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// 회원가입 완료 콜백을 실행한다.
  Future<void> _handleSignup() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요.')));
      return;
    }
    if (!_isEmailValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 형식을 확인해주세요.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uri = Uri.parse('http://3.35.210.200:8000/signup');
      debugPrint('[signup] POST $uri name=$name email=$email');
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      debugPrint(
        '[signup] status=${response.statusCode} body=${response.body}',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Signup failed: ${response.statusCode}');
      }

      UserSession.email = email;
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      widget.onSignup();
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('회원가입 실패: $error')));
      }
    }
  }

  /// 이메일 유효성 상태를 갱신한다.
  void _updateEmail(String value) {
    // Lightweight email format check to drive UI state.
    // 간단한 정규식으로 이메일 형식을 확인한다.
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    setState(() {
      _isEmailValid = emailPattern.hasMatch(value);
    });
  }

  /// 비밀번호 강도 점수를 계산하고 UI 상태를 갱신한다.
  void _updateStrength(String value) {
    // 문자 조합 조건을 점수로 환산한다.
    final hasLower = value.contains(RegExp(r'[a-z]'));
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    final hasSymbol = value.contains(RegExp(r'[^A-Za-z0-9]'));
    int score = 0;

    if (value.length >= 8) score++;
    if (hasLower && hasUpper) score++;
    if (hasDigit) score++;
    if (hasSymbol) score++;

    String label;
    Color color;

    if (score <= 1) {
      label = 'Weak';
      color = const Color(0xFFF87171);
    } else if (score == 2) {
      label = 'Medium';
      color = const Color(0xFFFACC15);
    } else if (score == 3) {
      label = 'Strong';
      color = const Color(0xFF22C55E);
    } else {
      label = 'Very Strong';
      color = const Color(0xFF16A34A);
    }

    setState(() {
      // Keep computed strength values for the meter UI.
      _strengthScore = score;
      _strengthLabel = label;
      _strengthColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SignupPalette.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // 상단 헤더 영역.
                  _Header(onBack: widget.onBackToLogin),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _IntroSection(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                // 이름 입력.
                                _InputGroup(
                                  label: '이름',
                                  child: _InputField(
                                    controller: _name,
                                    hintText: '예) 장예슬',
                                    suffixIcon: Icons.person_outline_rounded,
                                    borderColor: SignupPalette.border,
                                    fillColor: SignupPalette.fieldFill,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // 이메일 입력과 유효성 표시.
                                _InputGroup(
                                  label: '이메일',
                                  child: _InputField(
                                    controller: _email,
                                    hintText: 'name@google.com',
                                    keyboardType: TextInputType.emailAddress,
                                    onChanged: _updateEmail,
                                    suffixIcon: _email.text.isEmpty
                                        ? null
                                        : (_isEmailValid
                                              ? Icons.check_circle
                                              : Icons.warning_amber_rounded),
                                    suffixColor: _isEmailValid
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                    borderColor: SignupPalette.border,
                                    fillColor: SignupPalette.fieldFill,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                // 비밀번호 입력과 강도 계산.
                                _InputGroup(
                                  label: '비밀번호',
                                  child: _PasswordField(
                                    controller: _password,
                                    hintText: '최소 8자 이상',
                                    showPassword: _showPassword,
                                    onToggle: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    onChanged: _updateStrength,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // 비밀번호 강도 표시.
                                _StrengthIndicator(
                                  score: _strengthScore,
                                  label: _strengthLabel,
                                  labelColor: _strengthColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                            child: Column(
                              children: [
                                // 보안 안내 문구.
                                const _SecurityRow(),
                                const SizedBox(height: 16),
                                // 가입 버튼.
                                _PrimaryButton(
                                  label: '계정생성',
                                  onPressed: _handleSignup,
                                ),
                                // 소셜 로그인 영역 시작.
                                const SizedBox(height: 20),
                                const _DividerLabel(label: '소셜 계정으로 가입'),
                                const SizedBox(height: 16),
                                // 로그인 화면으로 돌아가기.
                                Row(
                                  children: const [
                                    Expanded(
                                      child: _SocialButton(
                                        label: 'Apple',
                                        icon: _AppleIcon(),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: _SocialButton(
                                        label: 'Google',
                                        icon: _GoogleIcon(),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '이미 계정이 있으신가요? ',
                                      style: TextStyle(
                                        color: SignupPalette.textMuted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: widget.onBackToLogin,
                                      child: const Text(
                                        '로그인',
                                        style: TextStyle(
                                          color: SignupPalette.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 상단 헤더(뒤로가기/타이틀).
class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white.withValues(alpha: 0.95),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: SignupPalette.textDark,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: const CircleBorder(),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '가입하기',
                style: TextStyle(
                  color: SignupPalette.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// 회원가입 안내 문구 영역.
class _IntroSection extends StatelessWidget {
  const _IntroSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계정을 생성하세요',
            style: TextStyle(
              color: SignupPalette.textDark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AI를 활용한 계약서 분석을 시작하세요.',
            style: TextStyle(
              color: SignupPalette.textMuted,
              fontSize: 14.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            color: SignupPalette.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// 일반 텍스트 입력 필드.
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final IconData? suffixIcon;
  final Color? suffixColor;
  final Color borderColor;
  final Color fillColor;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.suffixIcon,
    this.suffixColor,
    required this.borderColor,
    required this.fillColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        color: SignupPalette.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
      ),
      // 입력 필드 공통 스타일.
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: SignupPalette.textMuted.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        filled: true,
        fillColor: fillColor,
        suffixIcon: suffixIcon == null
            ? null
            : Icon(suffixIcon, color: suffixColor ?? SignupPalette.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1.2),
        ),
      ),
    );
  }
}

/// 비밀번호 입력 필드(표시 토글 포함).
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool showPassword;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;

  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.showPassword,
    required this.onToggle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      onChanged: onChanged,
      style: const TextStyle(
        color: SignupPalette.textDark,
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
      ),
      // 비밀번호 필드 스타일 및 토글 아이콘 정의.
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: SignupPalette.textMuted.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        filled: true,
        fillColor: SignupPalette.fieldFill,
        suffixIcon: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: SignupPalette.textMuted,
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SignupPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: SignupPalette.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

/// 비밀번호 강도 표시 바와 라벨.
class _StrengthIndicator extends StatelessWidget {
  final int score;
  final String label;
  final Color labelColor;

  const _StrengthIndicator({
    required this.score,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    // 단계별 색상 팔레트.
    final colors = [
      const Color(0xFFF87171),
      const Color(0xFFFACC15),
      const Color(0xFF22C55E),
      const Color(0xFF16A34A),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final barColor = index < score
                ? colors[index]
                : const Color(0xFFE2E8F0);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 6),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: 'Strength: ',
            style: const TextStyle(
              color: SignupPalette.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: label,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 보안 안내 문구 라인.
class _SecurityRow extends StatelessWidget {
  const _SecurityRow();

  @override
  Widget build(BuildContext context) {
    // 보안 메시지 한 줄 구성.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.lock_outline, size: 16, color: Color(0xFF94A3B8)),
        SizedBox(width: 6),
        Text(
          '비밀번호 보안 암호화 및 보호',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 회원가입 기본 액션 버튼.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // 화면 폭을 채우는 기본 액션 버튼.
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SignupPalette.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          shadowColor: SignupPalette.primary.withValues(alpha: 0.2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
          ),
        ),
      ),
    );
  }
}

/// 소셜 로그인 구분선 라벨.
class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    // 라벨을 가운데 두고 좌우로 구분선 표시.
    return Row(
      children: [
        const Expanded(child: Divider(color: SignupPalette.border, height: 1)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: SignupPalette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: SignupPalette.border, height: 1)),
      ],
    );
  }
}

/// 소셜 로그인 버튼.
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;

  const _SocialButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      // 실제 소셜 로그인 연결은 추후 추가.
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: SignupPalette.border),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: SignupPalette.textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 애플 로고 아이콘.
class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.apple, size: 18, color: Colors.black);
  }
}

/// 구글 로고 아이콘(SVG).
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_googleLogoSvg, width: 18, height: 18);
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
