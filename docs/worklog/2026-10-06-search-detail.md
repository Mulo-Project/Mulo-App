# 검색 결과 상세 보기 (영상 · 채널)

- 날짜: 2026-10-06
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/search-detail`
- 상세 기능: 키워드 검색 (#2) · URL로 곡 정보 불러오기 (#1)

## 한 일
- 검색 결과 줄에 ⋮ 옵션 메뉴를 더하고 "상세 보기"를 넣었다. 누르면 상세 화면이 열린다: 큰 썸네일, 제목, 채널(+ 채널 보기), 길이 · 조회수 · 올린 날 · 분류, 설명, 아래 고정 "유튜브에서 보기" · "받기" 버튼. 결정은 D-058.
- 영상 · 채널 보기는 기기의 유튜브 앱(없으면 브라우저)으로 연다. 열 앱이 없으면 안내 문구를 보여 준다.
- `MediaHit`에 채널 주소 · 조회수 · 올린 날 · 설명을 더하고 로컬 · 서버 엔진이 읽는다. 상세 화면이 곡 정보를 한 번 더 읽어 목록에 없던 값을 채운다.

## 바꾼 설정
- `pubspec.yaml`: `url_launcher` 추가 (영상 · 채널 열기). `windows/flutter/generated_plugin*`의 `url_launcher_windows` 등록분 포함.
- `AppIcons`에 `info` · `openInNew` 추가 (번들한 Phosphor 폰트에 있는 글리프). ARB에 `searchHit*` · `mediaDetail*` 문구 추가.

## 확인
- `flutter analyze` 0, `flutter test` 전체 통과 (엔진 파싱 · 병합 · cubit · 메뉴에서 상세 열기 · 주소 열기 · 열기 실패 안내).
- 화면은 테스트 렌더링 스크린샷으로 모양을 확인했다. 실제 기기에서 유튜브 앱이 열리는 것은 확인하지 못했다.

## 남은 일 · 질문
- 서버가 `channelUrl` · `viewCount` · `uploadDate` · `description`을 내려 줘야 서버 모드에서도 채워진다 (없으면 해당 줄이 숨겨진다).
- 앱 안에서 영상을 바로 재생하려면 Android WebView · 데스크톱 별도 구현이 필요하다. 지금은 외부 앱으로 연다.
- Notion 기술 스택(Flutter)에 `url_launcher` 행 추가 필요.
