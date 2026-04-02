import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 알림 서비스
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  /// 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  /// 권한 요청
  static Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// 대기순번 알림
  static Future<void> showWaitingNotification({
    required int currentNumber,
    required int reservationNumber,
    required int estimatedMinutes,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'waiting_channel',
      '대기순번 알림',
      channelDescription: '병원 대기순번 모니터링 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String body;
    if (estimatedMinutes <= 0) {
      body = '내 순번이 되었습니다! 이제 병원に向하시면 됩니다.';
    } else {
      body = '현재 $currentNumber번, 내 순번까지 약 $estimatedMinutes분 남았습니다.';
    }

    await _notifications.show(
      1,
      '🏥 병원 대기 알림',
      body,
      details,
    );
  }

  /// 출발 알림 (이동 시간 계산 후)
  static Future<void> showDepartureNotification({
    required int travelMinutes,
    required int patientsAhead,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'departure_channel',
      '출발 알림',
      channelDescription: '병원으로 출발 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final message = '$patientsAhead명 남았으니 이제 출발하세요! '
        '병원까지 약 $travelMinutes분 소요됩니다.';

    await _notifications.show(
      2,
      '⏰ 이제 출발하세요!',
      message,
      details,
    );
  }

  /// 순번 도달 알림
  static Future<void> showTurnNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'turn_channel',
      '순번 알림',
      channelDescription: '내 순번 도달 알림',
      importance: Importance.max,
      priority: Priority.max,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3,
      '🏥 차례입니다!',
      '내 순번이 되었습니다. 병원ضور por favor.',
      details,
    );
  }

  /// 모든 알림 취소
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}