import 'package:flutter/material.dart';
import 'main.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'profile_edit_screen.dart';
import 'welcome_screen.dart';

/// 사용자 프로필 화면.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardPalette.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  _ProfileAppBar(onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        const _ProfileHeader(),
                        const _ProfileInfoSection(),
                        const _ProfileEditButton(),
                        const _SettingsSection(),
                        const SizedBox(height: 12),
                        _LogoutButton(
                          onLogout: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => WelcomeScreen(
                                  onLoginTap: (context) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => LoginScreen(
                                          onLogin: () {
                                            Navigator.of(context)
                                                .pushReplacement(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const UploadScreen(),
                                              ),
                                            );
                                          },
                                          onSignupClick: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => SignupScreen(
                                                  onSignup: () {
                                                    Navigator.of(context)
                                                        .pushReplacement(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            const UploadScreen(),
                                                      ),
                                                    );
                                                  },
                                                  onBackToLogin: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  onSignupTap: (context) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SignupScreen(
                                          onSignup: () {
                                            Navigator.of(context)
                                                .pushReplacement(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const UploadScreen(),
                                              ),
                                            );
                                          },
                                          onBackToLogin: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              (_) => false,
                            );
                          },
                        ),
                        const _AppVersionFooter(),
                      ],
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

class _ProfileAppBar extends StatelessWidget {
  final VoidCallback onBack;

  const _ProfileAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new),
            color: DashboardPalette.textDark,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '프로필',
                style: TextStyle(
                  color: DashboardPalette.textDark,
                  fontSize: 18,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DashboardPalette.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: DashboardPalette.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: DashboardPalette.primary,
                ),
              ),
              Positioned(
                bottom: 6,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DashboardPalette.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '조나단 스털링',
            style: TextStyle(
              color: DashboardPalette.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'j.sterling@counsel-law.com',
            style: TextStyle(
              color: DashboardPalette.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoSection extends StatelessWidget {
  const _ProfileInfoSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사용자 정보',
            style: TextStyle(
              color: DashboardPalette.textDark.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          const _InfoCard(icon: Icons.badge, label: '이름', value: '조나단 스털링'),
          const SizedBox(height: 10),
          const _InfoCard(
            icon: Icons.mail,
            label: '이메일 주소',
            value: 'j.sterling@counsel-law.com',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F2F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DashboardPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DashboardPalette.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: DashboardPalette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: DashboardPalette.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditButton extends StatelessWidget {
  const _ProfileEditButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DashboardPalette.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 6,
            shadowColor: DashboardPalette.primary.withValues(alpha: 0.2),
          ),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text(
            '프로필 수정하기',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: const [
          Divider(color: Color(0xFFF0F2F4), height: 1),
          SizedBox(height: 8),
          _SettingRow(icon: Icons.shield, title: '보안 및 개인정보'),
          _SettingRow(icon: Icons.notifications, title: '알림 설정'),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SettingRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: DashboardPalette.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: DashboardPalette.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onLogout,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFFEE2E2),
            foregroundColor: const Color(0xFFDC2626),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text(
            '로그아웃',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        children: [
          Text(
            '계약서 AI v1.0.4',
            style: TextStyle(
              color: DashboardPalette.textMuted.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '안전한 법률 분석 환경',
            style: TextStyle(
              color: DashboardPalette.textMuted.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
