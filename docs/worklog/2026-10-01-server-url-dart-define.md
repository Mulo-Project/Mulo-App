# 서버 주소 설정 제거 · dart-define 전환

- 날짜: 2026-10-01
- 분류: 앱 · 설정 · 문서
- 상태: 완료 (PR 대기)
- 브랜치: `chore/server-url-dart-define` (`feature/loaded-folders-sheet` 위, PR #20 다음)
- 상세 기능: 서버 연결 · 모드 선택 (#31) 일부

## 한 일
- 설정 › 서버의 "서버 주소" 줄을 없앴다. 서버는 개발자가 배포한 하나라 사용자가 주소를 입력하지 않는다 (D-029).
- 주소는 빌드 때 `--dart-define=MULO_API_BASE_URL=...`로 넣고 `AppConfig.apiBaseUrl`로 읽는다. 기본값은 빈 문자열.
- README에 사용법 추가, `docs/decisions.md`에 D-029.
- 저장하던 주소 값은 원래 없었다 (줄이 자리 표시였음) — 지울 저장값 없음.

## 바꾼 설정
- 새 패키지 없음. 문구(ko · en) `settingsServerAddress` · `settingsServerNotSet` 삭제, `flutter gen-l10n` 재생성.

## 확인
- `flutter analyze` 0, `flutter test` 94개 통과, `flutter build apk --debug`(dart-define 포함) 성공. flavor는 아직 없어 `lite` 빌드는 확인하지 못했다.

## 남은 일 · 질문
- `ServerEngine`이 생길 때 `AppConfig.apiBaseUrl`을 쓰고, 비어 있으면 서버 모드를 막는 처리가 필요하다.
- 설정의 "연결 상태" 줄은 아직 자리 표시.
