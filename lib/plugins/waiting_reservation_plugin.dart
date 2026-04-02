import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/plugin/app_plugin.dart';
import 'services/waiting_monitor_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';

/// 똑딱앱 대기 예약 플러그인
/// - 실시간 대기 인원 모니터링
/// - 위치 기반 최적 출발 시간 알림
class WaitingReservationPlugin implements AppPlugin {
  static const String _configKey = 'waiting_reservation_config';

  @override
  String get id => 'waiting_reservation';

  @override
  String get name => '똑딱 대기 알림';

  @override
  String get description => '병원 대기 순번 모니터링 및 최적 출발 시간 알림';

  @override
  String get icon => '⏰';

  @override
  List<RequiredInfo> get requiredInfos => [
    const RequiredInfo(
      key: 'hospital_name',
      label: '병원 이름',
      hint: '예:○○소아과',
    ),
    const RequiredInfo(
      key: 'reservation_number',
      label: '예약/대기 번호',
      hint: '내 예약 번호',
    ),
    const RequiredInfo(
      key: 'home_latitude',
      label: '집 위도',
      hint: '예: 37.5665',
    ),
    const RequiredInfo(
      key: 'home_longitude',
      label: '집 경도',
      hint: '예: 126.9780',
    ),
    const RequiredInfo(
      key: 'notify_threshold_minutes',
      label: '알림 기준 (분)',
      hint: '대기번호까지 남은 시간 (기본: 30분)',
    ),
    const RequiredInfo(
      key: 'hospital_latitude',
      label: '병원 위도',
      hint: '병원 위치 좌표',
    ),
    const RequiredInfo(
      key: 'hospital_longitude',
      label: '병원 경도',
      hint: '병원 위치 좌표',
    ),
  ];

  @override
  bool isConfigured(Map<String, String> config) {
    return config['hospital_name']?.isNotEmpty == true &&
           config['reservation_number']?.isNotEmpty == true &&
           config['home_latitude']?.isNotEmpty == true &&
           config['home_longitude']?.isNotEmpty == true;
  }

  @override
  void registerDependencies(GetIt getIt) {}

  @override
  Widget buildFeature(BuildContext context) {
    return const WaitingReservationScreen();
  }

  @override
  Widget? buildSettingsWidget(
    BuildContext context,
    Map<String, String> config,
    Function(Map<String, String>) onSave,
  ) {
    return WaitingSettingsWidget(config: config, onSave: onSave);
  }

  /// 설정 저장
  static Future<void> saveConfig(Map<String, String> config) async {
    final prefs = GetIt.instance<SharedPreferences>();
    final jsonString = config.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    await prefs.setString(_configKey, jsonString);
  }

  /// 설정 불러오기
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

/// 대기 예약 메인 화면
class WaitingReservationScreen extends StatefulWidget {
  const WaitingReservationScreen({super.key});

  @override
  State<WaitingReservationScreen> createState() => _WaitingReservationScreenState();
}

class _WaitingReservationScreenState extends State<WaitingReservationScreen> {
  late WaitingMonitorService _monitorService;
  Map<String, String> _config = {};
  int _currentNumber = 0;
  int _reservationNumber = 0;
  int _estimatedMinutes = 0;
  int _patientsAhead = 0;
  bool _isMonitoring = false;

  final TextEditingController _currentNumberController = TextEditingController();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _monitorService = WaitingMonitorService(
      onUpdate: (current, reservation, estimated) {
        if (mounted) {
          setState(() {
            _currentNumber = current;
            _reservationNumber = reservation;
            _estimatedMinutes = estimated;
            _patientsAhead = _monitorService.getPatientsAhead();
          });
        }
      },
      onNotify: _onTurnReached,
    );
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    _config = await WaitingReservationPlugin.loadConfig();
    if (_config.isNotEmpty && mounted) {
      final reservationNum = int.tryParse(_config['reservation_number'] ?? '') ?? 0;
      final currentNum = int.tryParse(_config['current_number'] ?? '') ?? 0;
      
      setState(() {
        _reservationNumber = reservationNum;
        _currentNumber = currentNum;
        _patientsAhead = reservationNum - currentNum;
        _estimatedMinutes = _patientsAhead * 10;
      });
    }
  }

  void _onTurnReached() {
    NotificationService.showTurnNotification();
    if (mounted) {
      setState(() => _isMonitoring = false);
    }
  }

  void _startMonitoring() {
    final reservationNum = int.tryParse(_currentNumberController.text) ?? 0;
    if (reservationNum <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 대기 번호를 입력해주세요')),
      );
      return;
    }

    final threshold = int.tryParse(_config['notify_threshold_minutes'] ?? '30') ?? 30;
    
    _monitorService.startMonitoring(
      reservationNumber: _reservationNumber,
      currentNumber: reservationNum,
    );

    setState(() {
      _isMonitoring = true;
      _currentNumber = reservationNum;
      _patientsAhead = _reservationNumber - _currentNumber;
      _estimatedMinutes = _patientsAhead * 10;
    });

    // 설정 저장
    _config['current_number'] = reservationNum.toString();
    WaitingReservationPlugin.saveConfig(_config);

    // 1분마다 갱신
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // 자동 갱신 로직 (사용자가 수동으로 현재 번호 업데이트)
    });

    // 알림 권한 요청
    NotificationService.requestPermission();
  }

  void _stopMonitoring() {
    _monitorService.stopMonitoring();
    _refreshTimer?.cancel();
    setState(() => _isMonitoring = false);
  }

  void _updateCurrentNumber() {
    final newNumber = int.tryParse(_currentNumberController.text) ?? 0;
    if (newNumber > 0) {
      _monitorService.updateCurrentNumber(newNumber);
      _config['current_number'] = newNumber.toString();
      WaitingReservationPlugin.saveConfig(_config);
    }
  }

  String get _travelInfo {
    final homeLat = double.tryParse(_config['home_latitude'] ?? '') ?? 0;
    final homeLon = double.tryParse(_config['home_longitude'] ?? '') ?? 0;
    final hospLat = double.tryParse(_config['hospital_latitude'] ?? '') ?? 0;
    final hospLon = double.tryParse(_config['hospital_longitude'] ?? '') ?? 0;
    
    if (homeLat == 0 || hospLat == 0) return '위치 정보 없음';
    
    return LocationService.getTravelInfo(
      fromLat: homeLat,
      fromLon: homeLon,
      toLat: hospLat,
      toLon: hospLon,
    );
  }

  @override
  void dispose() {
    _monitorService.dispose();
    _refreshTimer?.cancel();
    _currentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hospitalName = _config['hospital_name'] ?? '병원';
    final threshold = int.tryParse(_config['notify_threshold_minutes'] ?? '30') ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: Text('$hospitalName 대기'),
        backgroundColor: Colors.blue.shade600,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 카드
            Card(
              color: _isMonitoring ? Colors.blue.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMonitoring ? Icons.monitor : Icons.monitor_outlined,
                          color: _isMonitoring ? Colors.blue : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isMonitoring ? '모니터링 중' : '대기 중',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isMonitoring ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 대기 정보
            if (_reservationNumber > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('내 예약 번호', style: TextStyle(color: Colors.grey.shade600)),
                      Text(
                        '$_reservationNumber',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoColumn(
                            label: '현재 번호',
                            value: '$_currentNumber',
                          ),
                          _InfoColumn(
                            label: '앞에 있는 사람',
                            value: '$_patientsAhead명',
                          ),
                          _InfoColumn(
                            label: '예상 대기',
                            value: '$_estimatedMinutes분',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 현재 번호 입력
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 대기 번호 업데이트',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '똑딱앱에서 현재 대기 번호를 확인하고 아래에 입력하세요',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _currentNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '현재 번호',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _updateCurrentNumber,
                          child: const Text('更新'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 이동 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏠 집 → 병원 이동 정보',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_travelInfo),
                    const SizedBox(height: 8),
                    Text(
                      ' threshold: ${threshold}분 전 알림',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 시작/중지 버튼
            ElevatedButton.icon(
              onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMonitoring ? Colors.red : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isMonitoring ? '모니터링 중지' : '모니터링 시작',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;

  const _InfoColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

/// 설정 위젯
class WaitingSettingsWidget extends StatefulWidget {
  final Map<String, String> config;
  final Function(Map<String, String>) onSave;

  const WaitingSettingsWidget({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  State<WaitingSettingsWidget> createState() => _WaitingSettingsWidgetState();
}

class _WaitingSettingsWidgetState extends State<WaitingSettingsWidget> {
  late TextEditingController _hospitalNameController;
  late TextEditingController _reservationNumberController;
  late TextEditingController _homeLatController;
  late TextEditingController _homeLonController;
  late TextEditingController _hospLatController;
  late TextEditingController _hospLonController;
  late TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    _hospitalNameController = TextEditingController(text: widget.config['hospital_name'] ?? '');
    _reservationNumberController = TextEditingController(text: widget.config['reservation_number'] ?? '');
    _homeLatController = TextEditingController(text: widget.config['home_latitude'] ?? '');
    _homeLonController = TextEditingController(text: widget.config['home_longitude'] ?? '');
    _hospLatController = TextEditingController(text: widget.config['hospital_latitude'] ?? '');
    _hospLonController = TextEditingController(text: widget.config['hospital_longitude'] ?? '');
    _thresholdController = TextEditingController(text: widget.config['notify_threshold_minutes'] ?? '30');
  }

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _reservationNumberController.dispose();
    _homeLatController.dispose();
    _homeLonController.dispose();
    _hospLatController.dispose();
    _hospLonController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('병원 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _hospitalNameController,
            decoration: const InputDecoration(
              labelText: '병원 이름',
              hintText: '예: ○○소아과',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reservationNumberController,
            decoration: const InputDecoration(
              labelText: '예약/대기 번호',
              hintText: '똑딱앱에서 확인한 내 번호',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          const Text('🏠 출발 위치 (집)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _homeLatController,
                  decoration: const InputDecoration(
                    labelText: '위도',
                    hintText: '예: 37.5665',
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
                    hintText: '예: 126.9780',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('🏥 병원 위치', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hospLatController,
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
                  controller: _hospLonController,
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
          const Text('🔔 알림 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(
              labelText: '알림 기준 (분)',
              hintText: '대기번호까지 남은 시간',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          const Text(
            '예: 30분으로 설정하면, 대기번호가 30분 남았을 때 알림을 보냅니다',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave({
                  'hospital_name': _hospitalNameController.text,
                  'reservation_number': _reservationNumberController.text,
                  'home_latitude': _homeLatController.text,
                  'home_longitude': _homeLonController.text,
                  'hospital_latitude': _hospLatController.text,
                  'hospital_longitude': _hospLonController.text,
                  'notify_threshold_minutes': _thresholdController.text,
                  'current_number': widget.config['current_number'] ?? '',
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