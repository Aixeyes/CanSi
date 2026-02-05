import 'dart:convert';

import 'package:flutter/material.dart';

class DetailPalette {
  static const Color primary = Color(0xFF137FEC);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color backgroundLight = Color(0xFFF6F7F8);
  static const Color backgroundDark = Color(0xFF101922);
  static const Color textDark = Color(0xFF111418);
  static const Color textMuted = Color(0xFF617589);
  static const Color borderLight = Color(0xFFE5E7EB);
}

class DetailScreen extends StatelessWidget {
  final String clauseText;
  final String tenantArgument;
  final String landlordArgument;
  final List<String> tenantTags;
  final List<String> landlordTags;
  final List<String> negotiationPoints;
  final String compromiseQuote;

  const DetailScreen({
    super.key,
    required this.clauseText,
    required this.tenantArgument,
    required this.landlordArgument,
    required this.tenantTags,
    required this.landlordTags,
    required this.negotiationPoints,
    required this.compromiseQuote,
  });

  factory DetailScreen.sample() {
    return const DetailScreen(
      clauseText:
          '임차인은 계약 기간 중이라도 1개월 전에 통지함으로써 계약을 해지할 수 있다. 단, 이 경우 임차인은 차순위 임차인이 입주할 때까지...',
      tenantArgument:
          '갑작스러운 이직이나 가계 상황 변화에 유연하게 대처하기 위해 1개월 통보 기간이 반드시 필요합니다. 이는 주거 이전의 자유를 보장하는 장치입니다.',
      landlordArgument:
          '1개월은 새로운 세입자를 구하기에 너무 짧은 시간입니다. 공실 발생 시 이자 비용 등 막대한 손실이 우려되므로 최소 3개월은 보장되어야 합니다.',
      tenantTags: ['유연성 확보', '권리 보호'],
      landlordTags: ['손실 방지', '공실 리스크'],
      negotiationPoints: [
        '통보 기간을 2개월로 설정하여 양측의 공실 및 이전 리스크를 분담',
        '해지 사유(질병, 발령 등)에 따른 통보 기간 단축 예외 조항을 추가',
      ],
      compromiseQuote:
          '통보 기간은 원칙적으로 2개월로 하되, 임차인이 다음 임차인을 확보할 경우 기간에 상관없이 해지할 수 있도록 명시하십시오.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeTenantArgument = _sanitizeArgumentText(tenantArgument);
    final safeLandlordArgument = _sanitizeArgumentText(landlordArgument);
    final safeCompromiseQuote = _sanitizeArgumentText(compromiseQuote);
    final safeNegotiationPoints =
        negotiationPoints.map(_sanitizeArgumentText).toList(growable: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? DetailPalette.backgroundDark : DetailPalette.backgroundLight;
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _DetailAppBar(isDark: isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _ClauseCard(
                            isDark: isDark,
                            text: clauseText,
                          ),
                        ),
                        const _SectionDivider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: _ArgumentBubble(
                            isDark: isDark,
                            title: '임차인 측 논리 (Tenant)',
                            text: safeTenantArgument,
                            tags: tenantTags,
                            icon: Icons.person,
                            color: DetailPalette.primary,
                            alignRight: false,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _ArgumentBubble(
                            isDark: isDark,
                            title: '임대인 측 논리 (Landlord)',
                            text: safeLandlordArgument,
                            tags: landlordTags,
                            icon: Icons.real_estate_agent,
                            color: DetailPalette.accentOrange,
                            alignRight: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: _SummaryCard(
                            isDark: isDark,
                            negotiationPoints: safeNegotiationPoints,
                            compromiseQuote: safeCompromiseQuote,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomActionBar(isDark: isDark),
            ),
          ],
        ),
      ),
    );
  }
}


String _sanitizeArgumentText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return value;
  }
  final jsonCandidate = _extractJsonObject(trimmed);
  if (jsonCandidate != null) {
    try {
      final decoded = jsonDecode(jsonCandidate);
      if (decoded is Map<String, dynamic>) {
        final rationale = _stringFromMap(decoded['rationale']);
        if (rationale != null && rationale.isNotEmpty) {
          return rationale;
        }
        final text = _stringFromMap(decoded['text']);
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
    } catch (_) {
      // Fall through to raw text.
    }
  }
  return value;
}

String? _stringFromMap(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  final converted = value.toString().trim();
  return converted.isEmpty ? null : converted;
}

String? _extractJsonObject(String value) {
  final start = value.indexOf('{');
  final end = value.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    return null;
  }
  return value.substring(start, end + 1);
}

class _DetailAppBar extends StatelessWidget {
  final bool isDark;

  const _DetailAppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color:
            (isDark
                    ? DetailPalette.backgroundDark
                    : Colors.white)
                .withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : DetailPalette.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new),
            color: isDark ? Colors.white : DetailPalette.textDark,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '예상 논리 전개 토론 시뮬레이션',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : DetailPalette.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '(협상 시 참고할 수 있는 논점 정리 자료)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: DetailPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _ClauseCard extends StatelessWidget {
  final bool isDark;
  final String text;

  const _ClauseCard({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1B33)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFDBEAFE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DetailPalette.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info,
                  size: 18,
                  color: DetailPalette.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '검토 조항 전문',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: DetailPalette.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$text"',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? Colors.white70 : DetailPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 8),
          Text(
            '협상 시뮬레이션',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: DetailPalette.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _ArgumentBubble extends StatelessWidget {
  final bool isDark;
  final String title;
  final String text;
  final List<String> tags;
  final IconData icon;
  final Color color;
  final bool alignRight;

  const _ArgumentBubble({
    required this.isDark,
    required this.title,
    required this.text,
    required this.tags,
    required this.icon,
    required this.color,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    final align = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment:
              alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!alignRight)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            if (!alignRight) const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            if (alignRight) const SizedBox(width: 8),
            if (alignRight)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: alignRight
                  ? const Radius.circular(16)
                  : Radius.zero,
              bottomRight: alignRight
                  ? Radius.zero
                  : const Radius.circular(16),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : color.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(
                text,
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white : DetailPalette.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment:
                    alignRight ? WrapAlignment.end : WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            alignRight ? Icons.timer : Icons.gavel,
                            size: 12,
                            color: color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final List<String> negotiationPoints;
  final String compromiseQuote;

  const _SummaryCard({
    required this.isDark,
    required this.negotiationPoints,
    required this.compromiseQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : DetailPalette.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: DetailPalette.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '조율 포인트 요약',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'AI가 분석한 합리적 타협안',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.trending_up, size: 16, color: DetailPalette.textMuted),
                    SizedBox(width: 6),
                    Text(
                      '일반적인 협상 패턴',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DetailPalette.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final point in negotiationPoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: DetailPalette.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            point,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DetailPalette.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DetailPalette.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lightbulb, size: 16, color: DetailPalette.primary),
                          SizedBox(width: 6),
                          Text(
                            '반복/공통 쟁점 및 해석 포인트',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: DetailPalette.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"$compromiseQuote"',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.white : DetailPalette.textDark,
                        ),
                      ),
                    ],
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

class _BottomActionBar extends StatelessWidget {
  final bool isDark;

  const _BottomActionBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color:
            (isDark
                    ? DetailPalette.backgroundDark
                    : Colors.white)
                .withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : DetailPalette.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text(
          '질문 & 질문 초안 생성',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: DetailPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: DetailPalette.primary.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}
