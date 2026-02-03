import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'profile_edit_screen.dart';
import 'welcome_screen.dart';
import 'user_session.dart';

class _ProfileData {
  final String name;
  final String email;

  const _ProfileData({required this.name, required this.email});
}

/// 사용자 프로필 화면.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final String? _email;
  late Future<_ProfileData?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Email is cached in memory after login/signup.
    _email = UserSession.email;
    final email = _email;
    if (email == null || email.isEmpty) {
      // No identity available; show placeholder values.
      _profileFuture = Future.value(null);
    } else {
      _profileFuture = _fetchProfile(email);
    }
  }

  Future<_ProfileData> _fetchProfile(String email) async {
    // Pull profile data using the email-based lookup endpoint.
    final uri = Uri.parse(
      'http://3.38.43.65:8000/profile?email=${Uri.encodeQueryComponent(email)}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      final body = response.body.trim();
      final snippet = body.length > 300 ? body.substring(0, 300) : body;
      throw Exception(
        'Profile API error: ${response.statusCode} ${snippet.isEmpty ? '(empty body)' : snippet}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = _unwrapProfileMap(data);
    final name =
        _pickString(profile, const ['name', 'username', 'user_name', 'full_name', 'fullName', 'nickname', 'display_name', 'displayName']) ??
        _pickString(data, const ['name', 'username', 'user_name', 'full_name', 'fullName', 'nickname', 'display_name', 'displayName']);
    final emailValue =
        _pickString(profile, const ['email', 'email_address', 'emailAddress', 'mail']) ??
        _pickString(data, const ['email', 'email_address', 'emailAddress', 'mail']);
    return _ProfileData(
      name: (name == null || name.isEmpty) ? email : name,
      email: (emailValue == null || emailValue.isEmpty) ? email : emailValue,
    );
  }

  Map<String, dynamic> _unwrapProfileMap(Map<String, dynamic> data) {
    final nestedKeys = ['data', 'profile', 'user', 'result'];
    for (final key in nestedKeys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return data;
  }

  String? _pickString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (!data.containsKey(key)) {
        continue;
      }
      final value = data[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

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
              child: FutureBuilder<_ProfileData?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  // Fall back to cached email if API data is missing.
                  final profile = snapshot.data;
                  final displayName = profile?.name ?? 'User';
                  final displayEmail = profile?.email ?? (_email ?? '');
                  return Column(
                    children: [
                      _ProfileAppBar(onBack: () => Navigator.of(context).pop()),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            // Inline error hint while keeping layout intact.
                            if (snapshot.hasError)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  0,
                                ),
                                child: Text(
                                  'Failed to load profile: ${snapshot.error}',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            _ProfileHeader(
                              name: displayName,
                              email: displayEmail,
                            ),
                            _ProfileInfoSection(
                              name: displayName,
                              email: displayEmail,
                            ),
                            _ProfileEditButton(
                              onEdit: () async {
                                final updated = await Navigator.of(context)
                                    .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileEditScreen(),
                                  ),
                                );
                                if (updated == true && mounted) {
                                  setState(() {
                                    final email = _email;
                                    if (email != null && email.isNotEmpty) {
                                      _profileFuture = _fetchProfile(email);
                                    }
                                  });
                                }
                              },
                            ),
                            const _SettingsSection(),
                            const SizedBox(height: 12),
                            _LogoutButton(
                              onLogout: () {
                                // Clear session cache and return to welcome flow.
                                UserSession.email = null;
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
                                                    builder: (_) =>
                                                        SignupScreen(
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
                  );
                },
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
  final String name;
  final String email;

  const _ProfileHeader({required this.name, required this.email});

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
          Text(
            name,
            style: TextStyle(
              color: DashboardPalette.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
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
  final String name;
  final String email;

  const _ProfileInfoSection({required this.name, required this.email});

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
          _InfoCard(icon: Icons.badge, label: '이름', value: name),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.mail,
            label: '이메일 주소',
            value: email,
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
  final Future<void> Function() onEdit;

  const _ProfileEditButton({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            onEdit();
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
