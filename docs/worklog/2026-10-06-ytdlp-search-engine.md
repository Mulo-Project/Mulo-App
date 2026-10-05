# yt-dlp 엔진 연결: URL · 키워드 검색, 곡 정보

- 날짜: 2026-10-06
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/download-ytdlp-search`
- 상세 기능: URL로 곡 정보 불러오기 (#1), 키워드 검색 (#2), 재생목록 URL 불러오기 (#3, 정보 읽기까지)

## 한 일
- `DownloaderEngine`(domain) 인터페이스: `search` · `fetchInfo`. 받기는 다음 작업.
- `ServerEngine`: Notion API 명세의 `GET /api/v1/search` · `GET /api/v1/info`를 부른다 (`dart:io` HttpClient, 새 패키지 없음). 서버 오류 형식 `{code, message}`와 상태 코드를 `EngineFailure`로 옮긴다.
- `LocalEngine`: 데스크톱에서 `yt-dlp` 실행 파일을 직접 돌린다 (`ytsearch` · `scsearch`, `--dump-json`, `--dump-single-json`). 쪽 번호는 `(page+1)*size`개를 받아 잘라 낸다.
- `RoutingDownloaderEngine`: 데스크톱은 로컬 yt-dlp가 있으면 로컬, 없으면 서버, 둘 다 없으면 "엔진 없음". Android는 서버만 (로컬 Android = full 빌드는 아직 없음).
- `SearchCubit`: 입력이 http(s) 주소면 곡 정보, 아니면 키워드 검색. "더 보기"로 쪽 이어 붙이기, 늦게 온 옛 응답은 버림.
- 설정 > 다운로드에 "다운로드 엔진" 줄(데스크톱): yt-dlp 설치 여부 · 버전 표시와 설치 · 업데이트 버튼 (공식 릴리스를 앱 데이터 폴더에 내려받음, D-055).
- 검색 화면: 확인을 누르면 찾는다. 결과 줄(썸네일 · 올린 사람 · 길이 · 이미 받음 표시)을 누르면 받기 팝업. 오류 · 빈 결과 · 엔진 없음 안내와 다시 시도.

## 바꾼 설정
- pubspec · Gradle · Manifest 변경 없음. 새 패키지 없음 (Notion 기술 스택 변경 없음).
- ARB 문구 추가(`searchErrorTitle` 등)와 `searchNotReady*` 문구 수정, 생성 l10n 갱신.

## 확인
- `flutter analyze` 0, `flutter test` 전체 통과 (`test/features/search/search_test.dart` 11개).
- 실제 서버 · 실제 yt-dlp에는 붙여 보지 못했다 (서버 저장소가 따로고 이 PC에 확인용 서버가 없음). 요청 · 응답 해석은 가짜 HTTP · 가짜 프로세스로만 확인했다.

## 남은 일 · 질문
- 서버에 `source=web`(SoundCloud 등) 쿼리와 항목의 `url` 필드를 지원해 달라고 서버 저장소에 알려야 한다. 명세에는 없는 추가다. 서버가 모르면 `source`는 무시돼 유튜브 결과가 나온다.
- 서버 JWT 로그인 화면이 없어 `ServerEngine.tokenProvider`는 비어 있다. 서버가 401을 주면 "로그인을 요구해요" 안내가 나온다.
- 설정에서 서버 / 로컬 모드를 고르는 화면은 아직 없다 (자동 선택). 자동 설치는 이 PC(Windows)에서 실제 내려받기까지는 돌려 보지 못했다 (릴리스 주소 응답만 확인).
- `downloaded`(중복 표시)는 서버 모드에서만 채워진다. 로컬 모드의 중복 확인은 받기 작업에서.
- 실제 받기 · 대기열 · 보관함 등록은 다음 작업 (#3), 최신 버전 비교 · 재생목록 가져오기는 그 다음.
