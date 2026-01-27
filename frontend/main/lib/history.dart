import 'package:flutter/material.dart';
import 'main.dart';

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
                  // 기본 레이아웃은 Column, 버튼은 Stack으로 겹쳐 배치.
                  Column(
                    children: [
                      const _HistoryAppBar(),
                      const _HistorySearch(),
                      const Expanded(child: _HistoryList()),
                      const _HistoryFooter(),
                    ],
                  ),
                  // 우측 하단 스크롤 탑 버튼.
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

/// 상단 앱 바(뒤로가기/계정 아이콘 포함).
class _HistoryAppBar extends StatelessWidget {
  const _HistoryAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      // 상단 영역은 구분선을 가진 고정 헤더 스타일.
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2F4))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            // 뒤로가기.
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
            // 프로필(향후 설정/계정 연결 가능).
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
          // 계약서 이름 검색 입력.
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
          // 기간 필터 스크롤 칩.
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

/// 기간 필터용 선택 칩.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;

  const _Chip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    // 선택 상태에 따라 색상을 바꾼다.
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

/// 스켈레톤 카드 리스트.
class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    // 각 카드의 제목 길이 느낌을 다르게 준다.
    final cards = [0.6, 0.45, 0.5, 0.8, 0.55, 0.35];

    return ListView.separated(
      // 스켈레톤 카드 리스트 구성.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemBuilder: (context, index) {
        return _HistorySkeletonCard(titleWidthFactor: cards[index]);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: cards.length,
    );
  }
}

/// 분석 기록 카드의 로딩 스켈레톤 UI.
class _HistorySkeletonCard extends StatelessWidget {
  final double titleWidthFactor;

  const _HistorySkeletonCard({required this.titleWidthFactor});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          // 카드 상단: 아이콘 + 제목 + 시간 뼈대.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FractionallySizedBox(
                            widthFactor: titleWidthFactor,
                            alignment: Alignment.centerLeft,
                            child: _SkeletonBox(height: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 60,
                          child: _SkeletonBox(height: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(width: 90, child: _SkeletonBox(height: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 카드 하단: 요약 텍스트 영역 뼈대.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF0F2F4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    SizedBox(width: 14, height: 14, child: _SkeletonBox()),
                    SizedBox(width: 8),
                    SizedBox(width: 24, height: 10, child: _SkeletonBox()),
                  ],
                ),
                SizedBox(height: 8),
                _SkeletonBox(height: 10),
                SizedBox(height: 6),
                FractionallySizedBox(
                  widthFactor: 0.75,
                  alignment: Alignment.centerLeft,
                  child: _SkeletonBox(height: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 스켈레톤 막대 기본 블록.
class _SkeletonBox extends StatelessWidget {
  final double height;

  const _SkeletonBox({this.height = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F4),
        borderRadius: BorderRadius.circular(6),
      ),
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
        // 현재는 동작이 없으므로 추후 스크롤 컨트롤러를 연결.
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

/// 하단 보안 안내 풋터.
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
