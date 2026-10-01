# Mulo

유튜브 등에서 음원을 받아 저장하고 같은 앱에서 재생하는 한국어 UI 음악 앱 (Flutter · Android / Windows / macOS / Linux).

> 개인 사용 목적(저작권법 제30조 사적 이용을 위한 복제 범위)으로 만든 앱입니다. 이 저장소에는 음원 파일이나 저작권 있는 곡 주소를 넣지 않습니다.

- 규칙: [CLAUDE.md](CLAUDE.md)
- 문서: [docs/](docs/README.md)
- 글꼴: [Pretendard](https://github.com/orioncactus/pretendard) (SIL OFL 1.1)

```bash
flutter pub get
flutter run
```

### 서버 주소 (빌드 설정)
서버는 개발자가 배포한 하나뿐이라 앱 안에서 주소를 입력하지 않는다. 빌드할 때 `--dart-define`으로 넣는다 (기본값은 빈 문자열 = 서버 미연결, `lib/core/config/app_config.dart`).
flavor(`lite`)는 아직 없지만, `lite` 빌드는 서버 모드만 있으므로 생기면 주소를 꼭 넣어야 한다.

```bash
flutter run --dart-define=MULO_API_BASE_URL=https://api.example.com
flutter build apk --dart-define=MULO_API_BASE_URL=https://api.example.com
```

주소는 저장소에 넣지 않는다 (CI · 로컬 빌드 명령에서만 지정).
