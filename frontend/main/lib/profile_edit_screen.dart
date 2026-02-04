import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'user_session.dart';

/// 프로필 수정 화면.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Controllers hold the editable profile fields.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final email = UserSession.email?.trim();
    if (email == null || email.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No email in session. Please login again.';
      });
      return;
    }

    try {
      final uri = Uri.parse(
        'http://3.38.43.65:8000/profile?email=${Uri.encodeQueryComponent(email)}',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          'Profile API error: ${response.statusCode} ${response.body}',
        );
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = _unwrapProfileMap(data);
      final name =
          _pickString(profile, const [
            'name',
            'username',
            'user_name',
            'full_name',
            'fullName',
            'nickname',
            'display_name',
            'displayName',
          ]) ??
          _pickString(data, const [
            'name',
            'username',
            'user_name',
            'full_name',
            'fullName',
            'nickname',
            'display_name',
            'displayName',
          ]);
      final emailValue =
          _pickString(profile, const [
            'email',
            'email_address',
            'emailAddress',
            'mail',
          ]) ??
          _pickString(data, const [
            'email',
            'email_address',
            'emailAddress',
            'mail',
          ]);

      if (!mounted) {
        return;
      }
      setState(() {
        _nameController.text = (name == null || name.isEmpty) ? '' : name;
        _emailController.text = (emailValue == null || emailValue.isEmpty)
            ? email
            : emailValue;
        _passwordController.text = '';
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
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

  Future<void> _saveProfile() async {
    if (_saving) {
      return;
    }
    final email = UserSession.email?.trim();
    if (email == null || email.isEmpty) {
      setState(() {
        _error = 'No email in session. Please login again.';
      });
      return;
    }

    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty && password.isEmpty) {
      setState(() {
        _error = '변경할 값이 없습니다.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('http://3.38.43.65:8000/profile');
      final payload = <String, dynamic>{'email': email};
      if (name.isNotEmpty) {
        payload['name'] = name;
      }
      if (password.isNotEmpty) {
        payload['password'] = password;
      }

      final response = await http.put(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Profile update error: ${response.statusCode} ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = _unwrapProfileMap(data);
      final updatedName =
          _pickString(profile, const [
            'name',
            'username',
            'user_name',
            'full_name',
            'fullName',
            'nickname',
            'display_name',
            'displayName',
          ]) ??
          _pickString(data, const [
            'name',
            'username',
            'user_name',
            'full_name',
            'fullName',
            'nickname',
            'display_name',
            'displayName',
          ]);
      final updatedEmail =
          _pickString(profile, const [
            'email',
            'email_address',
            'emailAddress',
            'mail',
          ]) ??
          _pickString(data, const [
            'email',
            'email_address',
            'emailAddress',
            'mail',
          ]);

      if (!mounted) {
        return;
      }
      setState(() {
        _nameController.text = (updatedName == null || updatedName.isEmpty)
            ? name
            : updatedName;
        _emailController.text = (updatedEmail == null || updatedEmail.isEmpty)
            ? email
            : updatedEmail;
        _passwordController.text = '';
        _saving = false;
      });

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              child: Column(
                children: [
                  _EditAppBar(onCancel: () => Navigator.of(context).pop()),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                            children: [
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              _ProfilePhoto(onTap: () {}),
                              const SizedBox(height: 24),
                              _InputGroup(
                                label: '이름',
                                child: _TextInput(
                                  controller: _nameController,
                                  hintText: '이름을 입력하세요.',
                                ),
                              ),
                              const SizedBox(height: 20),
                              _InputGroup(
                                label: '이메일',
                                child: _TextInput(
                                  controller: _emailController,
                                  hintText: '이메일을 입력하세요.',
                                  keyboardType: TextInputType.emailAddress,
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _InputGroup(
                                label: '비밀번호',
                                child: _PasswordInput(
                                  controller: _passwordController,
                                  hintText: '새 비밀번호',
                                  obscureText: _hidePassword,
                                  onToggle: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '보안을 위해 정기적인 비밀번호 변경을 권장합니다.',
                                style: TextStyle(
                                  color: DashboardPalette.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  _SaveBar(onSave: _saveProfile, isSaving: _saving),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditAppBar extends StatelessWidget {
  final VoidCallback onCancel;

  const _EditAppBar({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: DashboardPalette.primary,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              '취소',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Text(
            '프로필 수정',
            style: TextStyle(
              color: DashboardPalette.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfilePhoto({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            // Placeholder avatar container.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.account_circle,
                size: 50,
                color: Color(0xFF9CA3AF),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                // Camera badge for future image picker.
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
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
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '프로필 사진 변경',
          style: TextStyle(
            color: DashboardPalette.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

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
            color: DashboardPalette.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool readOnly;

  const _TextInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(
        color: DashboardPalette.textDark,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: DashboardPalette.textMuted.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDBE0E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardPalette.primary),
        ),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggle;

  const _PasswordInput({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: DashboardPalette.textDark,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: DashboardPalette.textMuted.withValues(alpha: 0.7),
          fontSize: 13,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDBE0E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DashboardPalette.primary),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF9CA3AF),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  final VoidCallback onSave;
  final bool isSaving;

  const _SaveBar({required this.onSave, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        color: Colors.white,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: isSaving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F5AB2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 6,
            shadowColor: const Color(0xFF0F5AB2).withValues(alpha: 0.2),
          ),
          child: const Text(
            '변경사항 저장',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
