import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../core/plugin/app_plugin.dart';

// 2026년 복지 혜택 데이터 (매년 업데이트 필요)
// 최종 업데이트: 2026년 1월
// 데이터 출처: 보건복지부, 복지로, 지자체

class WelfareData {
  static const int currentYear = 2026;
  
  // 2026년 부모급여 (만 2세 미만 - 2024년부터 변경)
  static const Map<String, int> parentAllowance2026 = {
    '0세': 1000000,
    '1세': 500000,
  };
  
  static List<Map<String, dynamic>> get benefits2026 => [
    {
      'id': 'parent_allowance_2026',
      'name': '부모급여',
      'amount': '월 100만원 (0세) / 50만원 (1세)',
      'ageRange': '0~1세',
      'type': '정부',
      'description': '만 2세 미만 모든 아동 가정양육 지원 (2024년부터 만 2세 미만 확대)',
      'url': 'https://www.bokjiro.go.kr/front/sps/sst/sstMain.do',
      'local': false,
      'adhd': false,
      'year': 2026,
    },
    {
      'id': 'child_allowance_2026',
      'name': '양육수당',
      'amount': '월 10~20만원 (소득별 차등)',
      'ageRange': '0~5세',
      'type': '정부',
      'description': '만 0~5세 가정양육 아동 (어린이집 미이용 시)',
      'url': 'https://www.bokjiro.go.kr/front/sps/sst/sstMain.do',
      'local': false,
      'adhd': false,
      'year': 2026,
    },
    {
      'id': 'child_money_2026',
      'name': '아동수당',
      'amount': '월 10만원',
      'ageRange': '0~18세',
      'type': '정부',
      'description': '만 18세 이하 모든 아동에게 지급',
      'url': 'https://www.bokjiro.go.kr/front/sps/sst/sstMain.do',
      'local': false,
      'adhd': false,
      'year': 2026,
    },
    {
      'id': 'childcare_support_2026',
      'name': '보육료 지원',
      'amount': '월 0~77만원 (소득별 차등)',
      'ageRange': '0~5세',
      'type': '정부',
      'description': '어린이집, 유아원 이용 아동 보육료 지원',
      'url': 'https://www.bokjiro.go.kr/front/sps/sst/sstMain.do',
      'local': false,
      'adhd': false,
      'year': 2026,
    },
    {
      'id': 'single_parent_2026',
      'name': '한부모가족 아동양육비',
      'amount': '월 10~30만원',
      'ageRange': '0~18세',
      'type': '정부',
      'description': '한부모가족 아동양육비 지원',
      'url': 'https://www.gov.kr/portal/service/serviceInfo/SSI000000020',
      'local': false,
      'adhd': false,
      'year': 2026,
    },
    {
      'id': 'adhd_therapy_2026',
      'name': 'ADHD 치료비 지원',
      'amount': '연 최대 200만원 (소득별 차등)',
      'ageRange': '0~18세',
      'type': '정부',
      'description': 'ADHD 아동 치료비 지원',
      'url': 'https://www.mohw.go.kr',
      'local': false,
      'adhd': true,
      'year': 2026,
    },
    {
      'id': 'adhd_medicine_2026',
      'name': 'ADHD 약물비 지원',
      'amount': '월 최대 10만원',
      'ageRange': '0~18세',
      'type': '정부',
      'description': 'ADHD 아동 의약비 지원 (급여 대상)',
      'url': 'https://www.nhis.or.kr',
      'local': false,
      'adhd': true,
      'year': 2026,
    },
    {
      'id': 'special_child_2026',
      'name': '장애아동수당',
      'amount': '월 10~20만원',
      'ageRange': '0~18세',
      'type': '정부',
      'description': '등록 장애아동에게 추가 지원',
      'url': 'https://www.bokjiro.go.kr',
      'local': false,
      'adhd': true,
      'year': 2026,
    },
  ];
}

class WelfarePlugin implements AppPlugin {
  @override
  String get id => 'welfare_benefits';

  @override
  String get name => '복지 혜택';

  @override
  String get description => '정부 및 지자체 아이 복지 혜택을 검색하세요';

  @override
  String get icon => '🏛️';

  @override
  List<RequiredInfo> get requiredInfos => [];

  @override
  bool isConfigured(Map<String, String> config) => true;

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  Widget buildFeature(BuildContext context) {
    return const WelfareScreen();
  }

  @override
  Widget? buildSettingsWidget(BuildContext context, Map<String, String> config, Function(Map<String, String>) onSave) => null;
}

class WelfareScreen extends StatefulWidget {
  const WelfareScreen({super.key});

  @override
  State<WelfareScreen> createState() => _WelfareScreenState();
}

class _WelfareScreenState extends State<WelfareScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRegion = '서울';
  int _childAge = 0;
  bool _hasAdhd = false;
  List<Map<String, dynamic>> _results = [];

  final List<Map<String, String>> _regions = [
    {'name': '서울', 'city': '서울특별시'},
    {'name': '경기', 'city': '경기도'},
    {'name': '인천', 'city': '인천광역시'},
    {'name': '부산', 'city': '부산광역시'},
    {'name': '대구', 'city': '대구광역시'},
    {'name': '대전', 'city': '대전광역시'},
    {'name': '세종', 'city': '세종특별자치시'},
    {'name': '강원', 'city': '강원특별자치도'},
    {'name': '충북', 'city': '충청북도'},
    {'name': '충남', 'city': '충청남도'},
    {'name': '전북', 'city': '전라북도'},
    {'name': '전남', 'city': '전라남도'},
    {'name': '경북', 'city': '경상북도'},
    {'name': '경남', 'city': '경상남도'},
    {'name': '제주', 'city': '제주특별자치도'},
  ];

  void _searchBenefits() {
    setState(() {
      final benefits = WelfareData.benefits2026;
      _results = benefits.where((benefit) {
        final ageRange = benefit['ageRange'] as String;
        if (ageRange.contains('~')) {
          final parts = ageRange.split('~');
          final minAge = int.tryParse(parts[0]) ?? 0;
          final maxAge = int.tryParse(parts[1].replaceAll('세', '')) ?? 100;
          if (_childAge < minAge || _childAge > maxAge) return false;
        }
        if (benefit['adhd'] == true && !_hasAdhd) return false;
        return true;
      }).toList();
      
      _results.sort((a, b) {
        final aLocal = a['local'] as bool? ?? false;
        final bLocal = b['local'] as bool? ?? false;
        if (aLocal && !bLocal) return 1;
        if (!aLocal && bLocal) return -1;
        return 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '2026년 최신 복지 혜택 정보입니다',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('지역', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRegion,
                        isExpanded: true,
                        items: _regions.map((region) {
                          return DropdownMenuItem(
                            value: region['name'],
                            child: Text(region['name']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedRegion = value!);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('아이 나이', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.cake, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _childAge.toDouble(),
                          min: 0,
                          max: 18,
                          divisions: 18,
                          label: '$_childAge세',
                          onChanged: (value) {
                            setState(() => _childAge = value.round());
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$_childAge세', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _hasAdhd,
                        onChanged: (value) => setState(() => _hasAdhd = value ?? false),
                      ),
                      const Text('ADHD 관련 (특수 혜택)'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _searchBenefits,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text('2026년 혜택 찾기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_results.isNotEmpty) ...[
            Row(
              children: [
                Text('검색 결과', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10)),
                  child: Text('${_results.length}건', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final benefit = _results[index];
                  final isLocal = benefit['local'] as bool? ?? false;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isLocal ? Colors.orange[200]! : Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (benefit['adhd'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(4)),
                                  child: Text('ADHD', style: TextStyle(fontSize: 10, color: Colors.purple[700], fontWeight: FontWeight.w600)),
                                ),
                              if (benefit['adhd'] == true) const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  benefit['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              Text(
                                benefit['ageRange'] as String,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            benefit['description'] as String,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              benefit['amount'] as String,
                              style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          if ((benefit['url'] as String).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('바로가기'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('검색을 시작하면 결과를 보여드려요', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}