import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/plugin/app_plugin.dart';

/// 등하원/등하교 안심 알림 플러그인
/// - 아이 위치 모니터링
/// - 지정된 장소 도착 시 자동 알림
/// - 시간/장소 미도착 시 지연 알림
class SafetyNotificationPlugin implements AppPlugin {
  static const String _configKey = 'safety_notification_config';

  @override
  String get id => 'safety_notification';

  @override
  String get name => '등하원 알림';

  @override
  String get description => '아이 위치 모니터링 및 안심 알림';

  @override
  String get icon => '🛡️';

  @override
  List<RequiredInfo> get requiredInfos => [
    const RequiredInfo(key: 'school_name', label: '학교/어린이집 이름'),
    const RequiredInfo(key: 'school_latitude', label: '학교 위도'),
    const RequiredInfo(key: 'school_longitude', label: '학교 경도'),
    const RequiredInfo(key: 'home_latitude', label: '집 위도'),
    const RequiredInfo(key: 'home_longitude', label: '집 경도'),
    const RequiredInfo(key: 'arrival_radius', label: '도착 감지 반경 (m)', hint: '기본: 200m'),
  ];

  @override
  bool isConfigured(Map<String, String> config) {
    return config['school_name']?.isNotEmpty == true &&
           config['school_latitude']?.isNotEmpty == true &&
           config['school_longitude']?.isNotEmpty == true;
  }

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  Widget buildFeature(BuildContext context) {
    return const SafetyNotificationScreen();
  }

  @override
  Widget? buildSettingsWidget(
    BuildContext context,
    Map<String, String> config,
    Function(Map<String, String>) onSave,
  ) {
    return SafetySettingsWidget(config: config, onSave: onSave);
  }

  static Future<void> saveConfig(Map<String, String> config) async {
    final prefs = GetIt.instance<SharedPreferences>();
    final jsonString = config.entries.map((e) => '${e.key}=${e.value}').join('&');
    await prefs.setString(_configKey, jsonString);
  }

  static Future<Map<String, String>> loadConfig() async {
    final prefs = GetIt.instance<SharedPreferences>();
    final jsonString = prefs.getString(_configKey) ?? '';
    if (jsonString.isEmpty) return {};
    
    final map = <String, String>{};
    for (final pair in jsonString.split('&')) {
      final idx = pair.indexOf('=');
      if (idx > 0) {
        map[pair.substring(0, idx)] = pair.substring(idx + 1);
      }
    }
    return map;
  }
}

/// 안심 알림 메인 화면
class SafetyNotificationScreen extends StatefulWidget {
  const SafetyNotificationScreen({super.key});

  @override
  State<SafetyNotificationScreen> createState() => _SafetyNotificationScreenState();
}

class _SafetyNotificationScreenState extends State<SafetyNotificationScreen> {
  Map<String, String> _config = {};
  bool _isMonitoring = false;
  String _currentStatus = '대기 중';
  DateTime? _lastUpdateTime;
  double? _currentLat;
  double? _currentLon;

  // 예상 시간 (하드코딩 - 나중에 설정에서 변경 가능)
  final String _expectedSchoolArrival = '08:30'; // 등교
  final String _expectedSchoolDeparture = '14:30'; // 하교
  final String _expectedHomeArrival = '15:00'; // 귀가

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await SafetyNotificationPlugin.loadConfig();
    if (mounted) setState(() {});
  }

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
      _currentStatus = '모니터링 중...';
    });
    // 위치 업데이트 시뮬레이션 (실제론 geolocator 사용)
    _simulateLocationUpdate();
  }

  void _stopMonitoring() {
    setState(() {
      _isMonitoring = false;
      _currentStatus = '대기 중';
    });
  }

  void _simulateLocationUpdate() {
    if (!_isMonitoring) return;
    
    // 시뮬레이션: 시간이 갈 때마다 위치 변경
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_isMonitoring) return;
      
      // 집 -> 학교 이동 시뮬레이션
      final now = DateTime.now();
      final minutes = now.hour * 60 + now.minute;
      final schoolArrivalMinutes = 8 * 60 + 30; // 8:30
      
      if (minutes >= schoolArrivalMinutes && _currentStatus == '모니터링 중...') {
        // 학교 도착!
        setState(() {
          _currentStatus = '🏫 학교 도착!';
        });
        _showArrivalNotification('학교');
      } else if (minutes >= 14 * 60 + 30 && _currentStatus == '🏫 학교 도착!') {
        // 하교
        setState(() {
          _currentStatus = '🚌 하교 중';
        });
      } else if (minutes >= 15 * 60 && _currentStatus == '🚌 하교 중') {
        // 집 도착
        setState(() {
          _currentStatus = '🏠 집 도착!';
        });
        _showArrivalNotification('집');
      }
      
      setState(() {
        _lastUpdateTime = DateTime.now();
        // 시뮬레이션 위치 (실제론 GPS에서 가져옴)
        _currentLat = 37.5665;
        _currentLon = 126.9780;
      });
      
      _simulateLocationUpdate();
    });
  }

  void _showArrivalNotification(String place) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👶 아이가 $place에 도착했습니다!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '위치 보기',
          textColor: Colors.white,
          onPressed: _showLocationDetail,
        ),
      ),
    );
  }

  void _showLocationDetail() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📍 현재 위치 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Text('위도: ${_currentLat?.toStringAsFixed(4) ?? 'unknown'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Text('경도: ${_currentLon?.toStringAsFixed(4) ?? 'unknown'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey),
                const SizedBox(width: 8),
                Text('마지막 업데이트: ${_lastUpdateTime?.toString() ?? 'N/A'}'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('📍 목적지', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.school, color: Colors.orange),
                const SizedBox(width: 8),
                Text(_config['school_name'] ?? '학교'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = _config['school_name'] ?? '학교/어린이집';

    return Scaffold(
      appBar: AppBar(
        title: const Text('등하원 알림'),
        backgroundColor: Colors.green.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 카드
            Card(
              color: _isMonitoring ? Colors.green.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _isMonitoring ? Icons.child_care : Icons.child_care,
                      size: 48,
                      color: _isMonitoring ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentStatus,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isMonitoring ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isMonitoring 
                          ? '아이 위치를 모니터링 중입니다'
                          : '모니터링을 시작하려면 버튼을 누르세요',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 예상 일정
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📅 예상 일정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    _ScheduleRow(time: '08:30', event: '등교', icon: '🏫'),
                    _ScheduleRow(time: '14:30', event: '하교', icon: '🚌'),
                    _ScheduleRow(time: '15:00', event: '귀가', icon: '🏠'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 모니터링 버튼
            ElevatedButton.icon(
              onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMonitoring ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isMonitoring ? '모니터링 중지' : '모니터링 시작',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // 테스트 알림 버튼
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('⚠️ 지연 알림 테스트'),
                    content: const Text('지연 알림을 표시합니다. 위치 정보를 보시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showLocationDetail();
                        },
                        child: const Text('위치 보기'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.warning_amber),
              label: const Text('지연 알림 테스트'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String time;
  final String event;
  final String icon;

  const _ScheduleRow({
    required this.time,
    required this.event,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 12),
          Text(event, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// 설정 위젯
class SafetySettingsWidget extends StatefulWidget {
  final Map<String, String> config;
  final Function(Map<String, String>) onSave;

  const SafetySettingsWidget({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  State<SafetySettingsWidget> createState() => _SafetySettingsWidgetState();
}

class _SafetySettingsWidgetState extends State<SafetySettingsWidget> {
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolLatController;
  late TextEditingController _schoolLonController;
  late TextEditingController _homeLatController;
  late TextEditingController _homeLonController;
  late TextEditingController _radiusController;

  @override
  void initState() {
    super.initState();
    _schoolNameController = TextEditingController(text: widget.config['school_name'] ?? '');
    _schoolLatController = TextEditingController(text: widget.config['school_latitude'] ?? '');
    _schoolLonController = TextEditingController(text: widget.config['school_longitude'] ?? '');
    _homeLatController = TextEditingController(text: widget.config['home_latitude'] ?? '');
    _homeLonController = TextEditingController(text: widget.config['home_longitude'] ?? '');
    _radiusController = TextEditingController(text: widget.config['arrival_radius'] ?? '200');
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolLatController.dispose();
    _schoolLonController.dispose();
    _homeLatController.dispose();
    _homeLonController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏫 학교/어린이집 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _schoolNameController,
            decoration: const InputDecoration(
              labelText: '학교/어린이집 이름',
              hintText: '예: ○○초등학교',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _schoolLatController,
                  decoration: const InputDecoration(
                    labelText: '위도',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _schoolLonController,
                  decoration: const InputDecoration(
                    labelText: '경도',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text('🏠 집 위치', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _homeLatController,
                  decoration: const InputDecoration(
                    labelText: '위도',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _homeLonController,
                  decoration: const InputDecoration(
                    labelText: '경도',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text('⚙️ 감지 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _radiusController,
            decoration: const InputDecoration(
              labelText: '도착 감지 반경 (m)',
              hintText: '200m',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          const Text(
            '학교/집에서 이 반경 이내로 진입하면 도착으로 인식합니다',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave({
                  'school_name': _schoolNameController.text,
                  'school_latitude': _schoolLatController.text,
                  'school_longitude': _schoolLonController.text,
                  'home_latitude': _homeLatController.text,
                  'home_longitude': _homeLonController.text,
                  'arrival_radius': _radiusController.text,
                });
              },
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}