import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'main.dart';

// 결과 화면에서 사용하는 색상 팔레트.
class ResultPalette {
  static const Color primary = Color(0xFF2563EB);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color navyPanel = Color(0xFF0F172A);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0B1220);
  static const Color cardDark = Color(0xFF111827);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textHeader = Color(0xFF1E293B);
  static const Color textBody = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color riskRed = Color(0xFFEF4444);
  static const Color riskYellow = Color(0xFFF59E0B);
  static const Color riskBlue = Color(0xFF3B82F6);
}

// 조항 위험도를 표현하는 등급.
enum RiskLevel { high, medium, low, info }

// 하이라이트로 표시할 텍스트 구간(시작/끝 인덱스).
class _HighlightRange {
  final int start;
  final int end;

  const _HighlightRange(this.start, this.end);
}

// API 조항 데이터를 화면 모델로 변환한 구조.
class ContractClause {
  final String title;
  final String body;
  final String? highlight;
  final List<String> highlights;
  final RiskLevel? risk;

  const ContractClause({
    required this.title,
    required this.body,
    this.highlight,
    this.highlights = const [],
    this.risk,
  });
}

// 요약 텍스트를 스타일별로 나누기 위한 스팬 모델.
class ResultSummarySpan {
  final String text;
  final bool isBold;
  final Color? underlineColor;
  final Color? textColor;

  const ResultSummarySpan(
    this.text, {
    this.isBold = false,
    this.underlineColor,
    this.textColor,
  });
}

// 결과 화면에 필요한 집계/목록/요약 데이터 컨테이너.
class ResultData {
  final int foundClauseCount;
  final int riskyClauseCount;
  final List<ContractClause> clauses;
  final List<ResultSummarySpan> summarySpans;

  const ResultData({
    required this.foundClauseCount,
    required this.riskyClauseCount,
    required this.clauses,
    required this.summarySpans,
  });
}

// API 응답을 화면 모델로 변환하고 상태를 관리하는 뷰모델.
class ResultViewModel extends ChangeNotifier {
  ResultData data;
  bool showSummary;
  final String? filename;

  ResultViewModel({
    required this.data,
    this.showSummary = false,
    this.filename,
  });

  void toggleSummary() {
    showSummary = !showSummary;
    notifyListeners();
  }

  void closeSummary() {
    if (!showSummary) {
      return;
    }
    showSummary = false;
    notifyListeners();
  }

  void openSummary() {
    if (showSummary || data.summarySpans.isEmpty) {
      return;
    }
    showSummary = true;
    notifyListeners();
  }

  // API 응답을 화면 모델로 변환한다.
  static ResultViewModel fromApi(
    Map<String, dynamic> data, {
    String? filename,
    String? fallbackSummary,
  }) {
    final riskySnippets = _extractRiskSnippets(data);
    final clauses = _parseClauses(data, riskySnippets: riskySnippets);
    final riskyClauses = data['risky_clauses'] as List?;
    final riskyCount =
        riskyClauses?.length ??
        clauses
            .where(
              (clause) =>
                  clause.risk == RiskLevel.high ||
                  clause.risk == RiskLevel.medium,
            )
            .length;
    final foundCount =
        (data['total_clauses'] as int?) ??
        (data['clauses'] as List?)?.length ??
        clauses.length;
    final summaryText = _cleanText(
      (data['llm_summary'] as String?)?.trim() ?? fallbackSummary?.trim(),
    );
    final summarySpans = _buildSummarySpans(summaryText);

    final resolvedClauses = clauses.isNotEmpty
        ? clauses
        : _fallbackClausesFromRisky(riskyClauses);
    final resolvedFoundCount = foundCount > 0
        ? foundCount
        : resolvedClauses.length;

    return ResultViewModel(
      filename: filename,
      data: ResultData(
        foundClauseCount: resolvedFoundCount,
        riskyClauseCount: riskyCount,
        clauses: resolvedClauses,
        summarySpans: summarySpans,
      ),
      showSummary: false,
    );
  }

  // risky_clauses에서 위험 문구 후보를 추출한다.
  static List<String> _extractRiskSnippets(Map<String, dynamic> data) {
    final raw = data['risky_clauses'];
    if (raw is! List) {
      return [];
    }
    final snippets = <String>[];
    for (final item in raw) {
      if (item is String && item.trim().isNotEmpty) {
        snippets.add(_cleanText(item) ?? item.trim());
        continue;
      }
      if (item is Map<String, dynamic>) {
        final text = _stringFrom(item, [
          'risk_text',
          'highlight',
          'text',
          'body',
          'content',
          'clause',
        ]);
        if (text != null) {
          snippets.add(_cleanText(text) ?? text);
        }
      }
    }
    return snippets;
  }

  // clauses 배열을 파싱해 ContractClause 목록으로 변환한다.
  static List<ContractClause> _parseClauses(
    Map<String, dynamic> data, {
    List<String> riskySnippets = const [],
  }) {
    final rawClauses = data['clauses'];
    if (rawClauses is! List) {
      return [];
    }

    final clauses = <ContractClause>[];
    for (final item in rawClauses) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final title = _cleanText(_stringFrom(item, ['title', 'name']));
      final body = _cleanText(_stringFrom(item, ['body', 'content', 'text']));
      if (title == null || body == null) {
        continue;
      }
      final highlight =
          _cleanText(_stringFrom(item, ['highlight', 'risk_text']));
      final risk = _riskFromString(_stringFrom(item, ['risk', 'level']));
      final highlights = _collectHighlights(body, highlight, riskySnippets);
      clauses.add(
        ContractClause(
          title: title,
          body: body,
          highlight: highlight,
          highlights: highlights,
          risk: risk,
        ),
      );
    }
    return clauses;
  }

  static List<ContractClause> _fallbackClausesFromRisky(List? riskyClauses) {
    if (riskyClauses == null || riskyClauses.isEmpty) {
      return const [];
    }
    final clauses = <ContractClause>[];
    var index = 1;
    for (final item in riskyClauses) {
      String? body;
      RiskLevel? risk;
      if (item is String && item.trim().isNotEmpty) {
        body = _cleanText(item) ?? item.trim();
      } else if (item is Map<String, dynamic>) {
        body = _cleanText(_stringFrom(item, [
          'risk_text',
          'highlight',
          'text',
          'body',
          'content',
          'clause',
        ]));
        risk = _riskFromString(_stringFrom(item, ['risk', 'level']));
      }
      if (body == null || body.isEmpty) {
        continue;
      }
      clauses.add(
        ContractClause(
          title: '독소 조항 $index',
          body: body,
          highlight: body,
          highlights: [body],
          risk: risk ?? RiskLevel.high,
        ),
      );
      index += 1;
    }
    return clauses;
  }

  // 여러 키 후보 중 유효한 문자열 값을 찾는다.
  static String? _stringFrom(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static String? _cleanText(String? value) {
    if (value == null) {
      return null;
    }
    final originalTrimmed = value.trim();
    if (originalTrimmed.isEmpty) {
      return null;
    }
    final cleaned = value
        // Remove zero-width and non-breaking spaces.
        .replaceAll(RegExp(r'[\u00A0\u200B\u200C\u200D\uFEFF]'), '')
        // Normalize ideographic space to a regular space.
        .replaceAll('\u3000', ' ')
        // Remove bidi/formatting/control marks that can shift alignment.
        .replaceAll(
          RegExp(r'[\u0000-\u001F\u007F-\u009F\u200E\u200F\u202A-\u202E\u2066-\u2069]'),
          '',
        )
        // Collapse whitespace runs.
        .replaceAll(RegExp(r'\s+'), ' ')
        // Trim including any remaining leading/trailing spaces.
        .trim();
    return cleaned.isEmpty ? originalTrimmed : cleaned;
  }

  // 위험도 문자열을 enum으로 매핑한다.
  static RiskLevel? _riskFromString(String? value) {
    if (value == null) {
      return null;
    }
    switch (value.toLowerCase()) {
      case 'high':
      case 'danger':
      case 'red':
        return RiskLevel.high;
      case 'medium':
      case 'warning':
      case 'yellow':
        return RiskLevel.medium;
      case 'low':
      case 'info':
      case 'blue':
        return RiskLevel.low;
    }
    return null;
  }

  // 본문에 실제 존재하는 하이라이트만 수집한다.
  static List<String> _collectHighlights(
    String body,
    String? primaryHighlight,
    List<String> riskySnippets,
  ) {
    final matches = <String>[];
    if (primaryHighlight != null && primaryHighlight.trim().isNotEmpty) {
      matches.add(primaryHighlight.trim());
    }
    for (final snippet in riskySnippets) {
      final trimmed = snippet.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (_findHighlightRange(body, trimmed) != null) {
        matches.add(trimmed);
      }
    }
    if (matches.isEmpty) {
      return const [];
    }
    final seen = <String>{};
    final unique = <String>[];
    for (final item in matches) {
      final key = item.replaceAll(RegExp(r'\s+'), '');
      if (seen.add(key)) {
        unique.add(item);
      }
    }
    return unique;
  }

  // 하이라이트 구간을 찾고 공백 차이를 보정한다.
  static _HighlightRange? _findHighlightRange(String body, String highlight) {
    final index = body.indexOf(highlight);
    if (index >= 0) {
      return _HighlightRange(index, index + highlight.length);
    }

    final normalizedBody = _normalizeText(body);
    final normalizedHighlight = _normalizeText(highlight);
    if (normalizedHighlight.isEmpty ||
        normalizedHighlight.length > normalizedBody.length) {
      return null;
    }

    final normalizedIndex = normalizedBody.indexOf(normalizedHighlight);
    if (normalizedIndex < 0) {
      return null;
    }

    final mapping = _buildNormalizedIndexMap(body);
    if (normalizedIndex >= mapping.length) {
      return null;
    }
    final endIndex = normalizedIndex + normalizedHighlight.length - 1;
    if (endIndex >= mapping.length) {
      return null;
    }
    final start = mapping[normalizedIndex];
    final end = mapping[endIndex] + 1;
    if (start >= 0 && end > start && end <= body.length) {
      return _HighlightRange(start, end);
    }
    return null;
  }

  // 공백/개행을 제거한 문자열로 정규화한다.
  static String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }

  // 정규화 인덱스를 원문 인덱스로 매핑하는 테이블.
  static List<int> _buildNormalizedIndexMap(String value) {
    final mapping = <int>[];
    for (var i = 0; i < value.length; i++) {
      if (!RegExp(r'\s').hasMatch(value[i])) {
        mapping.add(i);
      }
    }
    return mapping;
  }

  // 요약 텍스트를 스팬 목록으로 변환한다.
  static List<ResultSummarySpan> _buildSummarySpans(String? summaryText) {
    if (summaryText != null && summaryText.isNotEmpty) {
      return [ResultSummarySpan(summaryText)];
    }

    return const [];
  }
}

// 결과 화면 루트 위젯.
class ResultScreen extends StatefulWidget {
  final ResultViewModel viewModel;

  const ResultScreen({super.key, required this.viewModel});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

// 결과 화면의 상태 및 렌더링 로직.
class _ResultScreenState extends State<ResultScreen> {
  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final background = isDark
            ? ResultPalette.backgroundDark
            : ResultPalette.backgroundLight;
        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  color: background,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          ResultTopAppBar(
                            isDark: isDark,
                            onBack: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const UploadScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            onMenu: () {},
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 240),
                              child: Column(
                                children: [
                                  ResultStatsRow(
                                    isDark: isDark,
                                    foundCount:
                                        widget.viewModel.data.foundClauseCount,
                                    riskyCount:
                                        widget.viewModel.data.riskyClauseCount,
                                  ),
                                  ResultClauseList(
                                    isDark: isDark,
                                    clauses: widget.viewModel.data.clauses,
                                    onHighlightTap:
                                        widget.viewModel.openSummary,
                                  ),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 24,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child:
                              widget.viewModel.showSummary &&
                                  widget.viewModel.data.summarySpans.isNotEmpty
                              ? ResultSummaryCard(
                                  isDark: isDark,
                                  spans: widget.viewModel.data.summarySpans,
                                  onClose: widget.viewModel.closeSummary,
                                  onAction: () {},
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 상단 앱바(뒤로가기/타이틀/더보기).
class ResultTopAppBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  const ResultTopAppBar({
    super.key,
    required this.isDark,
    required this.onBack,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color:
            (isDark
                    ? ResultPalette.backgroundDark
                    : ResultPalette.backgroundLight)
                .withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : ResultPalette.cardBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new),
            color: isDark ? Colors.white : ResultPalette.textHeader,
          ),
          Expanded(
            child: Text(
              '분석 결과 리포트',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : ResultPalette.textHeader,
              ),
            ),
          ),
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.more_horiz),
            color: isDark ? Colors.white : ResultPalette.textHeader,
          ),
        ],
      ),
    );
  }
}

// 상단 통계 카드(발견 조항/독소 가능성).
class ResultStatsRow extends StatelessWidget {
  final bool isDark;
  final int foundCount;
  final int riskyCount;

  const ResultStatsRow({
    super.key,
    required this.isDark,
    required this.foundCount,
    required this.riskyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: '발견된 조항',
              value: '${foundCount}건',
              titleColor:
                  isDark ? Colors.white70 : ResultPalette.textMuted,
              valueColor: isDark ? Colors.white : ResultPalette.textHeader,
              background: isDark ? ResultPalette.cardDark : Colors.white,
              borderColor:
                  isDark ? Colors.white12 : ResultPalette.cardBorder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: '독소 가능성',
              value: '${riskyCount}건',
              titleColor:
                  isDark ? Colors.white70 : ResultPalette.textMuted,
              valueColor:
                  isDark ? ResultPalette.riskRed : ResultPalette.riskRed,
              background: isDark ? ResultPalette.cardDark : Colors.white,
              borderColor:
                  isDark ? Colors.white12 : ResultPalette.cardBorder,
            ),
          ),
        ],
      ),
    );
  }
}

// 통계 카드 단일 항목 UI.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;
  final Color background;
  final Color borderColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
    required this.background,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// 조항 리스트 섹션.
class ResultClauseList extends StatelessWidget {
  final bool isDark;
  final List<ContractClause> clauses;
  final VoidCallback onHighlightTap;

  const ResultClauseList({
    super.key,
    required this.isDark,
    required this.clauses,
    required this.onHighlightTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final clause in clauses)
            _ClauseSection(
              isDark: isDark,
              clause: clause,
              onHighlightTap: onHighlightTap,
            ),
        ],
      ),
    );
  }
}

// 단일 조항 섹션(제목 + 본문 하이라이트).
class _ClauseSection extends StatefulWidget {
  final bool isDark;
  final ContractClause clause;
  final VoidCallback onHighlightTap;

  const _ClauseSection({
    required this.isDark,
    required this.clause,
    required this.onHighlightTap,
  });

  @override
  State<_ClauseSection> createState() => _ClauseSectionState();
}

class _ClauseSectionState extends State<_ClauseSection> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTextColor = widget.isDark
        ? Colors.grey.shade300
        : ResultPalette.textBody;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.clause.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: widget.isDark ? Colors.white : ResultPalette.textHeader,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: baseTextColor,
              ),
              children: _buildHighlightSpans(
                widget.clause.body,
                widget.clause.highlights.isNotEmpty
                    ? widget.clause.highlights
                    : (widget.clause.highlight != null
                          ? [widget.clause.highlight!]
                          : const []),
                _riskColor(widget.clause.risk),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildHighlightSpans(
    String body,
    List<String> highlights,
    Color? color,
  ) {
    if (highlights.isEmpty || color == null) {
      return [TextSpan(text: body)];
    }

    final ranges = <_HighlightRange>[];
    for (final highlight in highlights) {
      final range = ResultViewModel._findHighlightRange(body, highlight);
      if (range != null) {
        ranges.add(range);
      }
    }
    if (ranges.isEmpty) {
      return [TextSpan(text: body)];
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_HighlightRange>[];
    for (final range in ranges) {
      if (merged.isEmpty || range.start > merged.last.end) {
        merged.add(range);
      } else if (range.end > merged.last.end) {
        merged[merged.length - 1] = _HighlightRange(
          merged.last.start,
          range.end,
        );
      }
    }

    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in merged) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: body.substring(cursor, range.start)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = widget.onHighlightTap;
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: body.substring(range.start, range.end),
          style: TextStyle(
            backgroundColor: color.withOpacity(0.2),
            decoration: TextDecoration.underline,
            decorationColor: color.withOpacity(0.5),
            decorationThickness: 2,
          ),
          recognizer: recognizer,
        ),
      );
      cursor = range.end;
    }
    if (cursor < body.length) {
      spans.add(TextSpan(text: body.substring(cursor)));
    }
    return spans;
  }

  Color? _riskColor(RiskLevel? risk) {
    switch (risk) {
      case RiskLevel.high:
        return ResultPalette.riskRed;
      case RiskLevel.medium:
        return ResultPalette.riskYellow;
      case RiskLevel.low:
        return ResultPalette.riskBlue;
      case RiskLevel.info:
        return ResultPalette.primary;
      case null:
        return null;
    }
  }
}

// 요약 카드(옵션 표시).
class ResultSummaryCard extends StatelessWidget {
  final bool isDark;
  final List<ResultSummarySpan> spans;
  final VoidCallback onClose;
  final VoidCallback onAction;

  const ResultSummaryCard({
    super.key,
    required this.isDark,
    required this.spans,
    required this.onClose,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? ResultPalette.cardDark : ResultPalette.navyPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.white10,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ResultPalette.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 20,
                  color: ResultPalette.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI 분석 요약',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                color: Colors.white54,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.grey.shade300 : Colors.white70,
              ),
              children: [
                for (final span in spans)
                  TextSpan(
                    text: span.text,
                    style: TextStyle(
                      fontWeight: span.isBold
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: span.textColor ?? Colors.white,
                      decoration: span.underlineColor != null
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: span.underlineColor,
                      decorationThickness: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text(
                '자세히 보기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ResultPalette.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                elevation: 6,
                shadowColor: ResultPalette.primary.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


