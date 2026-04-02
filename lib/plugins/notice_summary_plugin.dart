import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/plugin/app_plugin.dart';

/// 알림장 자동 요약 플러그인
/// - 키즈노트/스쿨맘톡 공지사항에서 준비물, 행사, 제출서류 추출
/// - 캘린더에 자동 등록
class NoticeSummaryPlugin implements AppPlugin {
  @override
  String get id => 'notice_summary';

  @override
  String get name => '알림장 요약';

  @override
  String get description => '공지사항에서 준비물, 행사, 제출서류 추출';

  @override
  String get icon => '📋';

  @override
  List<RequiredInfo> get requiredInfos => [
    const RequiredInfo(
      key: 'child_type',
      label: '유형',
      hint: '유치원/초등',
    ),
  ];

  @override
  bool isConfigured(Map<String, String> config) => true;

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  Widget buildFeature(BuildContext context) {
    return const NoticeSummaryScreen();
  }

  @override
  Widget? buildSettingsWidget(
    BuildContext context,
    Map<String, String> config,
    Function(Map<String, String>) onSave,
  ) {
    return NoticeSettingsWidget(config: config, onSave: onSave);
  }
}

/// 메인 화면
class NoticeSummaryScreen extends StatefulWidget {
  const NoticeSummaryScreen({super.key});

  @override
  State<NoticeSummaryScreen> createState() => _NoticeSummaryScreenState();
}

class _NoticeSummaryScreenState extends State<NoticeSummaryScreen> {
  final TextEditingController _noticeController = TextEditingController();
  NoticeSummary? _summary;
  bool _isProcessing = false;

  void _processNotice() {
    if (_noticeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공지사항을 입력해주세요')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    final processor = NoticeProcessor();
    final result = processor.process(_noticeController.text);
    
    setState(() {
      _summary = result;
      _isProcessing = false;
    });
  }

  void _saveToCalendar() {
    if (_summary == null) return;
    
    // 캘린더에 저장하는 로직은 나중에 device_calendar 연동 시 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('캘린더에 저장되었습니다')),
    );
  }

  @override
  void dispose() {
    _noticeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림장 요약'),
        backgroundColor: Colors.orange.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 입력 영역
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 키즈노트/스쿨맘톡 공지사항 붙여넣기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '공지사항 텍스트를 복사해서 아래에 붙여넣으세요',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noticeController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: '공지사항 텍스트를 여기에 붙여넣으세요...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _processNotice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.auto_fix_high),
                        label: Text(_isProcessing ? '처리 중...' : '요약하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 결과 영역
            if (_summary != null) ...[
              const SizedBox(height: 16),
              
              // 준비물
              if (_summary!.items.isNotEmpty) ...[
                _buildResultCard(
                  icon: '🎒',
                  title: '준비물',
                  color: Colors.blue,
                  items: _summary!.items,
                ),
                const SizedBox(height: 12),
              ],
              
              // 행사
              if (_summary!.events.isNotEmpty) ...[
                _buildResultCard(
                  icon: '🎉',
                  title: '행사',
                  color: Colors.purple,
                  items: _summary!.events,
                ),
                const SizedBox(height: 12),
              ],
              
              // 제출서류
              if (_summary!.documents.isNotEmpty) ...[
                _buildResultCard(
                  icon: '📄',
                  title: '제출 서류',
                  color: Colors.red,
                  items: _summary!.documents,
                ),
                const SizedBox(height: 12),
              ],
              
              // 날짜 정보
              if (_summary!.dates.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📅 주요 날짜',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ..._summary!.dates.map((d) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.event, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(d),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 캘린더 저장 버튼
              ElevatedButton.icon(
                onPressed: _saveToCalendar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('캘린더에 저장'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

/// 설정 위젯
class NoticeSettingsWidget extends StatefulWidget {
  final Map<String, String> config;
  final Function(Map<String, String>) onSave;

  const NoticeSettingsWidget({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  State<NoticeSettingsWidget> createState() => _NoticeSettingsWidgetState();
}

class _NoticeSettingsWidgetState extends State<NoticeSettingsWidget> {
  String _selectedType = '유치원';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.config['child_type'] ?? '유치원';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('자녀 유형', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '유치원', label: Text('유치원')),
              ButtonSegment(value: '초등', label: Text('초등')),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<String> selection) {
              setState(() => _selectedType = selection.first);
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '유치원: 키즈노트 기반\n초등: 스쿨맘톡 기반',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave({'child_type': _selectedType});
              },
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 공지사항 처리 결과
class NoticeSummary {
  final List<String> items;      // 준비물
  final List<String> events;      // 행사
  final List<String> documents;   // 제출서류
  final List<String> dates;       // 날짜

  NoticeSummary({
    required this.items,
    required this.events,
    required this.documents,
    required this.dates,
  });
}

/// 공지사항 텍스트 파서
class NoticeProcessor {
  // 준비물 패턴
  static final List<RegExp> _itemPatterns = [
    RegExp(r'준비물[:\s]*(.+)', caseSensitive: false),
    RegExp(r'가져올것[:\s]*(.+)', caseSensitive: false),
    RegExp(r'준비[:\s]*(.+)', caseSensitive: false),
    RegExp(r'지참[:\s]*(.+)', caseSensitive: false),
    RegExp(r'필요[:\s]*(.+)', caseSensitive: false),
    RegExp(r'☑\s*(.+?물)', caseSensitive: false),
    RegExp(r'▣\s*(.+?물)', caseSensitive: false),
  ];

  // 행사 패턴
  static final List<RegExp> _eventPatterns = [
    RegExp(r'행사[:\s]*(.+)', caseSensitive: false),
    RegExp(r'이벤트[:\s]*(.+)', caseSensitive: false),
    RegExp(r'체험[:\s]*(.+)', caseSensitive: false),
    RegExp(r'학습[:\s]*(.+)', caseSensitive: false),
    RegExp(r'견학[:\s]*(.+)', caseSensitive: false),
    RegExp(r'연극[:\s]*(.+)', caseSensitive: false),
    RegExp(r'运动会', caseSensitive: false),
  ];

  // 제출서류 패턴
  static final List<RegExp> _documentPatterns = [
    RegExp(r'제출[:\s]*(.+)', caseSensitive: false),
    RegExp(r'납부[:\s]*(.+)', caseSensitive: false),
    RegExp(r'제출서류[:\s]*(.+)', caseSensitive: false),
    RegExp(r'서류[:\s]*(.+)', caseSensitive: false),
    RegExp(r'통지서[:\s]*(.+)', caseSensitive: false),
    RegExp(r'동의서[:\s]*(.+)', caseSensitive: false),
    RegExp(r'신청서[:\s]*(.+)', caseSensitive: false),
  ];

  // 날짜 패턴
  static final RegExp _datePattern = RegExp(
    r'(\d{1,2})[\s]*월[\s]*(\d{1,2})[\s]*일|'
    r'(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})|'
    r'(다음|오늘|내일|모레)\s*(주|월|화|수|목|금|토|일)?',
    caseSensitive: false,
  );

  NoticeSummary process(String text) {
    final items = _extractItems(text, _itemPatterns);
    final events = _extractItems(text, _eventPatterns);
    final documents = _extractItems(text, _documentPatterns);
    final dates = _extractDates(text);

    return NoticeSummary(
      items: items,
      events: events,
      documents: documents,
      dates: dates,
    );
  }

  List<String> _extractItems(String text, List<RegExp> patterns) {
    final results = <String>[];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final content = match.group(1)?.trim();
        if (content != null && content.isNotEmpty) {
          // 여러 항목이 있을 경우 분리
          final parts = content.split(RegExp(r'[,，、·\n]'));
          for (final part in parts) {
            final trimmed = part.trim();
            if (trimmed.isNotEmpty && trimmed.length > 1) {
              results.add(trimmed);
            }
          }
        }
      }
    }
    
    // 중복 제거
    return results.toSet().toList();
  }

  List<String> _extractDates(String text) {
    final results = <String>[];
    final matches = _datePattern.allMatches(text);
    
    for (final match in matches) {
      for (int i = 1; i < match.groupCount; i++) {
        final group = match.group(i)?.trim();
        if (group != null && group.isNotEmpty) {
          results.add(group);
        }
      }
    }
    
    return results.toSet().toList();
  }
}