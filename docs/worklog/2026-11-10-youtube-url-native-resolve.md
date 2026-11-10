# 유튜브 주소 읽기를 네이티브로 옮기기

- 바꾼 것: `YoutubeResolver.kt` · `YoutubeFormats.kt` · `YoutubeResolveChannel.kt`(새 채널 `music_app/youtube_resolve`, `MuloEngine`에 등록) · Dart `NativeYoutubeResolver` → `di.dart`에서 Android일 때 `YoutubeExplodeEngine`의 소리 · 영상 · 언어 읽기 함수로 연결. 결정은 D-160.
- 옮긴 것: 소리 주소(언어 트랙 고르기 포함) · 영상 주소(소리 든 형식 vs 영상 전용 mp4, 15초 제한은 Dart에서 그대로) · 오디오 언어 목록 · 구간 403 확인(probe).
- 안 바꾼 것: 읽기 실패 시 yt-dlp(기본 → android_vr) 넘어가기, 검색 · 곡 정보 · 채널(yt-dlp), 데스크톱(Dart 라이브러리). pubspec · Gradle 변경 없음.
- 확인 필요(기기, 이 환경은 유튜브에 닿지 않아 실제 요청은 못 해 봤다): 소리 · 영상 읽기 시간(전: 소리 약 2초, 영상 2~3초) 비교, 언어 목록, 홈 버튼으로 나간 뒤 읽기 이어지는지, 로그 `adb logcat -s MuloNative`. 실패하면 yt-dlp로 넘어가므로 재생은 막히지 않는다.
- 사용자 확인: PC에서 `flutter analyze` · `flutter test` · `./gradlew testFullDebugUnitTest`.
