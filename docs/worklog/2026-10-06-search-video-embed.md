# 상세 화면의 앱 안 영상 재생 · 검색 타일 길이 제거

- 날짜: 2026-10-06
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/search-video-embed`
- 상세 기능: 키워드 검색 (#2)

## 한 일
- Android 상세 화면에서 썸네일 재생 버튼으로 유튜브 임베드를 그 자리에서 재생한다. 임베드가 막힌 영상은 앱 안 재생을 접고 유튜브로만 열게 안내한다. 유튜브로 보기 버튼은 그대로. Windows · 웹 음원은 유튜브로 연다 (D-060).
- 검색 결과 타일의 부제에서 곡 길이를 뺐다 (상세 화면 길이는 그대로).

## 바꾼 설정
- `pubspec.yaml`: `webview_flutter_android` 직접 의존성 추가 (자동 재생 설정용, 이미 쓰던 패키지의 Android 구현).
- ARB: `mediaDetailPlayInApp` · `mediaDetailEmbedBlocked` 추가.

## 확인
- `flutter analyze` 0, `flutter test` 전체 통과 (임베드 페이지 · id 검사 · 막힘 폴백을 가짜 플레이어로 테스트), `flutter build apk --debug` 성공.
- 실제 기기 WebView에서 임베드가 도는 것은 확인하지 못했다.

## 남은 일 · 질문
- 임베드 전체 화면 버튼 처리, 영상 재생 시 앱 음악 자동 일시정지 여부.
- Notion 기술 스택(Flutter)에 `url_launcher` · `webview_flutter_android` 행 추가 필요.
