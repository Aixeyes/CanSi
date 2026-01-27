import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'history.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';
import 'profile_screen.dart';

void main() => runApp(const App());

/// 앱 진입점과 테마/라우팅을 구성하는 루트 위젯.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Builder(
        // 로그인 전 환영 화면에서 로그인/회원가입으로 이동한다.
        builder: (context) => WelcomeScreen(
          onLoginTap: (context) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LoginScreen(
                  onLogin: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const UploadScreen()),
                    );
                  },
                  onSignupClick: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SignupScreen(
                          onSignup: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const UploadScreen(),
                              ),
                            );
                          },
                          onBackToLogin: () => Navigator.of(context).pop(),
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const UploadScreen()),
                    );
                  },
                  onBackToLogin: () => Navigator.of(context).pop(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 대시보드 화면에서 공통으로 쓰는 색상 팔레트.
class DashboardPalette {
  static const Color primary = Color(0xFF137FEC);
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF1A222B);
  static const Color textDark = Color(0xFF111418);
  static const Color textMuted = Color(0xFF617589);
  static const Color borderLight = Color(0xFFDBE0E6);
}

/// 문서 업로드/촬영 및 분석 결과를 보여주는 화면.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

/// 업로드/촬영 흐름과 활동 목록을 관리하는 상태 객체.
class _UploadScreenState extends State<UploadScreen> {
  final List<_ActivityEntry> _activities = [];
  final ImagePicker _imagePicker = ImagePicker();

  /// 파일 확장자에 따라 아이콘을 선택한다.
  IconData _pickIconForFile(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  /// 활동 로그에 표시할 시간 문자열을 만든다.
  String _formatTimestamp(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return 'Today, $hour12:$minute $suffix';
  }

  /// 파일 선택기를 열고 선택된 파일을 분석 API로 전송한다.
  Future<void> _handleUpload(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // 파일 선택기는 PDF/이미지 확장자만 허용한다.
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (pickerResult == null) {
      messenger.showSnackBar(const SnackBar(content: Text('파일 선택이 취소되었습니다.')));
      return;
    }

    final pickedFile = pickerResult.files.single;
    final path = pickedFile.path;
    if (path == null) {
      // 경로를 확인할 수 없으면 업로드를 진행할 수 없다.
      messenger.showSnackBar(
        const SnackBar(content: Text('파일 경로를 확인할 수 없습니다.')),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    await _analyzeFile(context, path, displayName: pickedFile.name);
  }

  /// 기기 카메라로 촬영한 이미지를 분석 API로 전송한다.
  Future<void> _handleCameraTap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // 카메라 앱을 호출해 사진을 촬영한다.
    final captured = await _imagePicker.pickImage(source: ImageSource.camera);
    if (captured == null) {
      messenger.showSnackBar(const SnackBar(content: Text('촬영이 취소되었습니다.')));
      return;
    }
    if (!context.mounted) {
      return;
    }

    final displayName = captured.name.isNotEmpty ? captured.name : 'camera.jpg';
    await _analyzeFile(context, captured.path, displayName: displayName);
  }

  /// 파일 경로를 받아 분석 API 호출과 결과 UI 갱신을 수행한다.
  Future<void> _analyzeFile(
    BuildContext context,
    String path, {
    required String displayName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    // 분석 진행 중에는 로딩 다이얼로그를 띄운다.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 로컬 API 엔드포인트로 파일을 전송한다.
      final uri = Uri.parse('http://10.0.2.2:8000/analyze/file');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        // 상태 코드가 200이 아니면 실패로 처리한다.
        throw Exception('API 오류: ${response.statusCode} $body');
      }

      // 응답 JSON을 파싱해 위험 조항 수와 요약을 추출한다.
      final data = jsonDecode(body) as Map<String, dynamic>;
      final riskyClauses = (data['risky_clauses'] as List?)?.length ?? 0;
      final summary = data['llm_summary']?.toString().trim();

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      // 활동 내역 카드에 표시할 데이터 구성.
      final activity = _ActivityEntry(
        title: displayName,
        time: _formatTimestamp(DateTime.now()),
        statusLabel: riskyClauses > 0 ? '$riskyClauses Risks Found' : 'Safe',
        statusColor: riskyClauses > 0
            ? const Color(0xFFDC2626)
            : const Color(0xFF15803D),
        badgeColor: riskyClauses > 0
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFDCFCE7),
        icon: _pickIconForFile(displayName),
        iconBg: riskyClauses > 0
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFDCFCE7),
        iconColor: riskyClauses > 0
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        showPulse: false,
      );

      setState(() {
        _activities.insert(0, activity);
      });

      // 분석 결과를 모달로 보여준다.
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('분석 완료'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('위험 조항 수: $riskyClauses'),
                const SizedBox(height: 12),
                Text(summary?.isNotEmpty == true ? summary! : '요약이 없습니다.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (context.mounted) {
        // 실패 시 로딩을 닫고 메시지를 표시한다.
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(SnackBar(content: Text('분석 실패: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardPalette.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              color: Colors.white,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 높이를 채우기 위해 IntrinsicHeight로 감싼다.
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _TopAppBar(),
                            const _GreetingSection(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _HeroCard(
                                onCameraTap: () => _handleCameraTap(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 업로드/기록 액션 카드 2열.
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ActionCard(
                                      title: '파일 업로드',
                                      subtitle: 'PDF 또는 사진',
                                      icon: Icons.upload_file,
                                      onTap: () => _handleUpload(context),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ActionCard(
                                      title: '기록',
                                      subtitle: '과거 기록 보기',
                                      icon: Icons.history,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const HistoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: _SectionHeader(
                                title: '최근 활동',
                                actionLabel: '모든 보기',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                // 활동 내역이 없으면 빈 상태를 보여준다.
                                child: _activities.isEmpty
                                    ? const _EmptyActivityState()
                                    : ListView.separated(
                                        itemCount: _activities.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) =>
                                            _ActivityItem.fromEntry(
                                              _activities[index],
                                            ),
                                      ),
                              ),
                            ),
                            const _TrustFooter(),
                          ],
                        ),
                      ),
                    ),
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

/// 상단 앱 바.
class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'CanSi',
              style: TextStyle(
                color: DashboardPalette.textDark,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            // 추후 계정/설정으로 연결 가능.
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            icon: const Icon(Icons.account_circle),
            color: DashboardPalette.textDark,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 인사말과 안내 문구 섹션.
class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '반갑습니다.',
            style: TextStyle(
              color: DashboardPalette.textDark,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '문서를 분석할 준비가 되어 있습니까?',
            style: TextStyle(
              color: DashboardPalette.textMuted,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 촬영 안내가 들어있는 히어로 카드.
class _HeroCard extends StatelessWidget {
  final VoidCallback onCameraTap;

  const _HeroCard({required this.onCameraTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
        ),
      ),
      child: Stack(
        children: [
          // 배경 장식 아이콘.
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.network_check_rounded,
                  size: 160,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          // 하단으로 갈수록 어두워지는 오버레이.
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(0, 19, 127, 236),
                  Color.fromARGB(220, 15, 23, 42),
                ],
              ),
            ),
          ),
          // 우측 상단 스캐너 아이콘 배지.
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.document_scanner,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          // 하단에 텍스트와 촬영 버튼 배치.
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '촬영하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '카메라로 독소 조항을 즉시 감지합니다.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: DashboardPalette.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    // 촬영 버튼 클릭 시 카메라 실행.
                    onTap: onCameraTap,
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.photo_camera, color: Colors.white),
                    ),
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

/// 기능 진입용 카드(파일 업로드/기록 등).
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        // 카드 전체가 탭 영역.
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: DashboardPalette.borderLight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DashboardPalette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: DashboardPalette.primary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: DashboardPalette.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DashboardPalette.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 섹션 제목과 액션 레이블 영역.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;

  const _SectionHeader({required this.title, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: DashboardPalette.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            color: DashboardPalette.primary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 활동 내역이 없을 때 보여주는 빈 상태 화면.
class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '아직 기록 없음',
          style: const TextStyle(
            color: DashboardPalette.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 활동 내역에 표시할 데이터 모델.
class _ActivityEntry {
  final String title;
  final String time;
  final String statusLabel;
  final Color statusColor;
  final Color badgeColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool showPulse;

  const _ActivityEntry({
    required this.title,
    required this.time,
    required this.statusLabel,
    required this.statusColor,
    required this.badgeColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.showPulse = false,
  });
}

/// 활동 내역 항목 UI.
class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final String statusLabel;
  final Color statusColor;
  final Color badgeColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool showPulse;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.statusLabel,
    required this.statusColor,
    required this.badgeColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.showPulse = false,
  });

  factory _ActivityItem.fromEntry(_ActivityEntry entry) {
    return _ActivityItem(
      title: entry.title,
      time: entry.time,
      statusLabel: entry.statusLabel,
      statusColor: entry.statusColor,
      badgeColor: entry.badgeColor,
      icon: entry.icon,
      iconBg: entry.iconBg,
      iconColor: entry.iconColor,
      showPulse: entry.showPulse,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F2F4)),
      ),
      child: Row(
        children: [
          // 파일 유형 아이콘.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          // 제목과 시간 정보.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashboardPalette.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    color: DashboardPalette.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // 위험 여부 배지.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                if (showPulse)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: DashboardPalette.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
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

/// 하단 보안 안내 풋터.
class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.lock, size: 14, color: DashboardPalette.textMuted),
          SizedBox(width: 6),
          Text(
            'End-to-end Encrypted',
            style: TextStyle(
              color: DashboardPalette.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
