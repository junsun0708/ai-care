# Children Health & Care

 어린이를 위한 건강 관리 애플리케이션

## 프로젝트 구조

```
lib/
├── core/
│   ├── di/              # 의존성 주입
│   ├── plugin/          # 플러그인 시스템
│   └── router/         # 라우팅
├── features/
│   └── home/           # 홈 화면
├── plugins/            # 기능 플러그인
└── main.dart           # 앱 시작점
```

## 플러그인 시스템

 이 앱은 모듈식 플러그인 아키텍처를 사용합니다. 새로운 기능을 추가하려면:

1. `AppPlugin` 인터페이스를 구현하는 클래스 생성
2. `lib/plugins/` 디렉토리에 저장
3. `lib/core/di/injection.dart`에서 플러그인 등록

```dart
class MyPlugin implements AppPlugin {
  @override
  String get id => 'my_feature';
  @override
  String get name => 'My Feature';
  @override
  String get description => '기능 설명';
  @override
  String get icon => '🎯';
  
  @override
  void registerDependencies(GetIt getIt) {
    // 의존성 등록
  }
  
  @override
  Widget buildFeature(BuildContext context) {
    return MyFeatureScreen();
  }
}
```

---

## 설치된 플러그인

### 1. 똑딱 대기 알림 (⏰ Waiting Reservation)

병원 대기 순번 모니터링 및 최적 출발 시간 알림

**설정 방법:**
1. 플러그인 설정에서 다음 정보 입력:
   - 병원 이름
   - 예약/대기 번호
   - 집 좌표 (위도, 경도)
   - 병원 좌표 (위도, 경도)
   - 알림 기준 시간 (분)

**사용 방법:**
1. 똑딱앱에서 현재 대기 번호 확인
2. 앱에 현재 번호 입력 후 "모니터링 시작"
3. 순번 도달 시 알림 수신

**참고:** 똑딱앱 API가 공개되지 않아 현재 대기번호를 수동으로 입력해야 합니다.

---

### 2. 알림장 요약 (📋 Notice Summary)

키즈노트/스쿨맘톡 공지사항에서 준비물, 행사, 제출서류 자동 추출

**설정 방법:**
1. 플러그인 설정에서 자녀 유형 선택 (유치원/초등)

**사용 방법:**
1. 키즈노트 또는 스쿨맘톡에서 공지사항 텍스트 복사
2. 앱에 붙여넣고 "요약하기" 클릭
3. 추출된 항목 확인:
   - 🎒 준비물
   - 🎉 행사
   - 📄 제출 서류
   - 📅 주요 날짜
4. "캘린더에 저장" 클릭

**참고:** 키즈노트/스쿨맘톡 API가 공개되지 않아 텍스트를 수동으로 붙여넣어야 합니다.

---

### 3. 등하원 알림 (🛡️ Safety Notification)

아이 위치 모니터링 - 지정된 장소 도착 시 자동 알림 / 지연 시 경고

**설정 방법:**
1. 플러그인 설정에서 다음 입력:
   - 학교/어린이집 이름
   - 학교 좌표 (위도, 경도)
   - 집 좌표 (위도, 경도)
   - 도착 감지 반경 (기본 200m)

**사용 방법:**
1. "모니터링 시작" 버튼 클릭
2. 아이가 학교/집에 도착하면 자동 알림
3. 예상 시간에 도착하지 않으면 지연 알림 + 위치 보기

**기능:**
- 🏫 등교 알림 (예상 08:30)
- 🚌 하교 알림 (예상 14:30)
- 🏠 귀가 알림 (예상 15:00)
- ⚠️ 지연 시 위치 정보 확인

**참고:** 실제 GPS 연동은 기기 설치 필요, 현재 시뮬레이션 모드로動作

---

## 실행

```bash
flutter pub get
flutter run
```

## 빌드 (APK)

```bash
flutter build apk --debug
```

**참고**: APK 빌드에는 Android SDK가 필요합니다.