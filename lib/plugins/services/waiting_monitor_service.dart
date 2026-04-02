import 'dart:async';

/// 대기 순번 및 예상 시간 모니터링 서비스
class WaitingMonitorService {
  Timer? _monitorTimer;
  final Function(int currentNumber, int reservationNumber, int estimatedMinutes)? onUpdate;
  final Function()? onNotify;
  
  int _currentNumber = 0;
  int _reservationNumber = 0;
  int _patientsAhead = 0;
  int _averageMinutesPerPatient = 10; // 1명당 평균 대기 시간
  bool _hasNotified = false;

  WaitingMonitorService({this.onUpdate, this.onNotify});

  /// 모니터링 시작
  void startMonitoring({
    required int reservationNumber,
    int currentNumber = 0,
    int averageMinutesPerPatient = 10,
  }) {
    _reservationNumber = reservationNumber;
    _currentNumber = currentNumber;
    _averageMinutesPerPatient = averageMinutesPerPatient;
    _hasNotified = false;
    _calculatePatientsAhead();

    // 1분마다 업데이트 체크
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndNotify();
    });
  }

  /// 현재 대기 순번 업데이트 (사용자가 수동으로 입력)
  void updateCurrentNumber(int newCurrentNumber) {
    _currentNumber = newCurrentNumber;
    _calculatePatientsAhead();
    onUpdate?.call(_currentNumber, _reservationNumber, getEstimatedMinutes());
    _checkAndNotify();
  }

  /// 예약 번호 업데이트
  void updateReservationNumber(int newReservationNumber) {
    _reservationNumber = newReservationNumber;
    _calculatePatientsAhead();
    onUpdate?.call(_currentNumber, _reservationNumber, getEstimatedMinutes());
    _checkAndNotify();
  }

  /// 내 앞의 환자 수 계산
  void _calculatePatientsAhead() {
    if (_currentNumber >= _reservationNumber) {
      _patientsAhead = 0;
    } else {
      _patientsAhead = _reservationNumber - _currentNumber;
    }
  }

  /// 예상 대기 시간 (분)
  int getEstimatedMinutes() {
    return _patientsAhead * _averageMinutesPerPatient;
  }

  /// 내 순번까지 남은 환자 수
  int getPatientsAhead() => _patientsAhead;

  /// 순번 도달 체크 및 알림
  void _checkAndNotify() {
    if (_patientsAhead <= 0 && !_hasNotified) {
      _hasNotified = true;
      onNotify?.call();
    }
  }

  /// 모니터링 중지
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// 상태 확인
  bool get isMonitoring => _monitorTimer?.isActive ?? false;

  void dispose() {
    stopMonitoring();
  }
}