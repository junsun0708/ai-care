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