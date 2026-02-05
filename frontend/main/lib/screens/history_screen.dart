import 'package:flutter/material.dart';

import '../result.dart';
import '../shared/dashboard_palette.dart';
import '../shared/history_repository.dart';

/// 분석 기록 화면.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
              child: Stack(
                children: [
                  // 기본 레이아웃은 Column, 버튼은 Stack으로 배치.
                  Column(
                    children: [
                      const _HistoryAppBar(),
                      const _HistorySearch(),
                      const Expanded(child: _HistoryList()),
                      const _HistoryFooter(),
                    ],
                  ),
                  // 우측 하단 스크롤 버튼.
                  const Positioned(
                    right: 24,
                    bottom: 80,
                    child: _ScrollTopButton(),
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

/// 상단 앱바(뒤로가기/계정 아이콘 포함).
class _HistoryAppBar extends StatelessWidget {
  const _HistoryAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      // 상단 영역 구분용 보더.
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2F4))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            // 뒤로가기
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            color: DashboardPalette.textDark,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              '분석 기록',
              style: TextStyle(
                color: DashboardPalette.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            // 추후 계정 화면 연결 가능.
            onPressed: () {},
            icon: const Icon(Icons.account_circle),
            color: DashboardPalette.textDark,
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 검색 입력과 기간 필터 칩 영역.
class _HistorySearch extends StatelessWidget {
  const _HistorySearch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // 계약서/파일명 검색.
          TextField(
            decoration: InputDecoration(
              hintText: '계약서 이름 검색',
              hintStyle: const TextStyle(
                color: DashboardPalette.textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: DashboardPalette.textMuted,
              ),
              filled: true,
              fillColor: const Color(0xFFF0F2F4),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: DashboardPalette.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 기간 필터 칩.
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _Chip(label: '전체', selected: true),
                _Chip(label: '오늘'),
                _Chip(label: '1주일'),
                _Chip(label: '1개월'),
                _Chip(label: '3개월'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 기간 필터 선택 칩.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;

  const _Chip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    // 선택 상태에 따라 색상을 변경.
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111418) : const Color(0xFFF0F2F4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : DashboardPalette.textDark,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 분석 기록 카드 리스트.
class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityEntry>>(
      valueListenable: HistoryRepository.instance.entries,
      builder: (context, entries, _) {
        if (entries.isEmpty) {
          return const _EmptyHistoryState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemBuilder: (context, index) {
            return _HistoryEntryCard(entry: entries[index]);
          },
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemCount: entries.length,
        );
      },
    );
  }
}

/// 기록이 없을 때 보여주는 빈 상태.
class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          '아직 기록이 없습니다.',
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

/// 기록 카드.
class _HistoryEntryCard extends StatelessWidget {
  final ActivityEntry entry;

  const _HistoryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openHistoryDetail(context, entry),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DashboardPalette.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: entry.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(entry.icon, color: entry.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DashboardPalette.textDark,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.time,
                        style: const TextStyle(
                          color: DashboardPalette.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: entry.badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.statusLabel,
                      style: TextStyle(
                        color: entry.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openHistoryDetail(
  BuildContext context,
  ActivityEntry entry,
) async {
  final analysisId = entry.analysisId;
  if (analysisId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상세 데이터를 찾을 수 없습니다.')),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final data =
        await HistoryRepository.instance.fetchAnalysisDetail(analysisId);
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    final viewModel = ResultViewModel.fromApi(
      data,
      filename: data['original_name']?.toString() ??
          data['filename']?.toString() ??
          entry.title,
      fallbackSummary: data['summary']?.toString(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(viewModel: viewModel)),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('상세 로드 실패: $error')),
    );
  }
}

/// 상단 이동 버튼(동작은 추후 연결).
class _ScrollTopButton extends StatelessWidget {
  const _ScrollTopButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardPalette.primary,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        // 현재 동작은 없음. 추후 스크롤 컨트롤러 연결.
        onTap: () {},
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.arrow_upward, color: Colors.white),
        ),
      ),
    );
  }
}

/// 하단 보안 안내 푸터.
class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF0F2F4))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 14, color: DashboardPalette.textMuted),
          SizedBox(width: 6),
          Text(
            '종단간 암호화 적용',
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
