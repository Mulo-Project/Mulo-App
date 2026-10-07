# 구글 계정 로그인 · 내 유튜브 재생목록

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (merge 대기, #70 위에 쌓음 · 기기 로그인 확인 대기)
- 브랜치 · 커밋: `feature/playlist-search`
- 상세 기능: 유튜브 재생목록 가져오기 (#22)

## 한 일
- 설정에 "계정" 묶음: 구글 계정 로그인 · 로그아웃 (로그인하면 이름 · 이메일 표시).
- 가져오기 화면에 "내 재생목록" 버튼: 로그인 확인 → 내 유튜브 재생목록(이미지 · 이름 · 채널 · 곡 수) → 하나를 고르면 기존 곡 고르기. 로그인이 풀리면 다시 로그인 안내.
- `features/account/` 새 기능, `AppConfig.googleServerClientId`.
- 데스크톱(Windows · macOS · Linux)도 로그인: 브라우저 로그인 + 로컬 임시 포트 + PKCE (`LoopbackGoogleAuth`), 새로고침 토큰은 보안 저장소. 테스트는 가짜 브라우저로 전체 흐름을 확인한다.
- 결정: D-073.

## 바꾼 설정
- `pubspec.yaml`: `google_sign_in ^7.2.0` 추가. 새 패키지라 Notion 기술 스택(Flutter)에 행을 더해야 한다.
- 빌드 값: Android `MULO_GOOGLE_SERVER_CLIENT_ID`, 데스크톱 `MULO_GOOGLE_DESKTOP_CLIENT_ID` · `MULO_GOOGLE_DESKTOP_CLIENT_SECRET` (없으면 로그인 꺼짐). Gradle · Manifest 변경 없음.
- 문구는 ARB(ko · en)에 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` 성공.
- 실제 구글 로그인 · YouTube API 응답은 확인하지 못했다 (Google Cloud 설정이 필요).

## 남은 일 · 질문
- Google Cloud 설정 (D-073 목록)과 기기에서 로그인 확인.
- 좋아요 표시한 동영상 · 나중에 볼 영상 같은 기본 목록은 불러오지 않는다 (`playlists?mine=true`에는 안 나온다).
