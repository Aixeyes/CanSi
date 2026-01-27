import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 로그인 전 환영 화면에서 사용하는 색상 팔레트.
class WelcomePalette {
  static const Color primary = Color(0xFF137FEC);
  static const Color brandDeep = Color(0xFF1A365D);
  static const Color brandCyan = Color(0xFF06B6D4);
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF101922);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
}

/// 로그인 전에 보여주는 앱 시작 화면.
class WelcomeScreen extends StatelessWidget {
  final void Function(BuildContext) onLoginTap;
  final void Function(BuildContext) onSignupTap;

  const WelcomeScreen({
    super.key,
    required this.onLoginTap,
    required this.onSignupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WelcomePalette.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -60,
                    child: _GlowOrb(
                      size: 260,
                      color: WelcomePalette.brandCyan.withValues(alpha: 0.08),
                    ),
                  ),
                  Positioned(
                    bottom: 160,
                    left: -80,
                    child: _GlowOrb(
                      size: 240,
                      color: WelcomePalette.primary.withValues(alpha: 0.06),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      const Spacer(),
                      const _WelcomeLogo(),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: const [
                            Text(
                              'AI로 계약서 독소 조항을\n한눈에 확인하세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: WelcomePalette.textDark,
                                fontSize: 28,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Upstage OCR과 OpenAI로\n더 정밀하고 안전하게 분석합니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: WelcomePalette.textMuted,
                                fontSize: 15.5,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: ElevatedButton(
                                onPressed: () => onLoginTap(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WelcomePalette.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  elevation: 6,
                                  shadowColor: WelcomePalette.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                                child: const Text(
                                  '로그인 후 시작',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '계정이 없으신가요?',
                                  style: TextStyle(
                                    color: WelcomePalette.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  onPressed: () => onSignupTap(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: WelcomePalette.primary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '회원가입',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationThickness: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
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

/// 로고와 배경 글로우를 포함한 중앙 배지.
class _WelcomeLogo extends StatelessWidget {
  const _WelcomeLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WelcomePalette.brandCyan.withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: WelcomePalette.brandCyan.withValues(alpha: 0.25),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    WelcomePalette.brandCyan,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: WelcomePalette.brandDeep.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
            ),
          ),
          const _WelcomeLogoIconStack(),
        ],
      ),
    );
  }
}

class _WelcomeLogoIconStack extends StatelessWidget {
  const _WelcomeLogoIconStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const Icon(Icons.edit_note, size: 50, color: Colors.white),
          Positioned(
            top: 10,
            right: 16,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: WelcomePalette.brandCyan,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 배경 장식용 글로우 원.
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
          ),
        ],
      ),
    );
  }
}
