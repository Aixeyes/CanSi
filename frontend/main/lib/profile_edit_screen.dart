import 'package:flutter/material.dart';
import 'main.dart';

/// 프로필 수정 화면.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: '김철수');
  final TextEditingController _emailController =
      TextEditingController(text: 'counsel@contractai.com');
  final TextEditingController _passwordController =
      TextEditingController(text: '********');
  bool _hidePassword = true;

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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: [
                        _ProfilePhoto(
                          onTap: () {},
                        ),
                        const SizedBox(height: 24),
                        _InputGroup(
                          label: '이름',
                          child: _TextInput(
                            controller: _nameController,
                            hintText: '이름을 입력하세요',
                          ),
                        ),
                        const SizedBox(height: 20),
                        _InputGroup(
                          label: '이메일',
                          child: _TextInput(
                            controller: _emailController,
                            hintText: '이메일을 입력하세요',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _InputGroup(
                          label: '비밀번호',
                          child: _PasswordInput(
                            controller: _passwordController,
                            hintText: '새 비밀번호',
                            obscureText: _hidePassword,
                            onToggle: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '보안을 위해 주기적인 비밀번호 변경을 권장합니다.',
                          style: TextStyle(
                            color: DashboardPalette.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SaveBar(onSave: () {}),
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

  const _TextInput({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

  const _SaveBar({required this.onSave});

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
          onPressed: onSave,
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
