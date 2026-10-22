# 유튜브 오디오 언어 선택

- 날짜: 2026-10-22
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/youtube-audio-language`
- 상세 기능: 다운로드 · 미리 듣기 (여러 오디오 언어 트랙)

## 한 일
- 엔진에 오디오 언어 목록 조회(`fetchAudioLanguages`)와 언어 지정 스트림 조회를 더했다: `YoutubeExplodeEngine`(오디오 트랙 id), `LocalEngine`(yt-dlp 형식의 `language`, 선택자 `bestaudio[language=…]`), 덮개 엔진(언어별 캐시), 서버(없음).
- 영상 정보 화면과 받기 페이지에 "오디오 언어" 줄 + 고르면 바로 적용되는 시트(`audio_language_sheet.dart`). 듣는 중에 바꾸면 새 언어로 다시 듣고, 고른 언어가 받기로 이어진다.
- `DownloadRequest.audioLanguage`를 대기열 저장 · 받기에 연결했다.
- 결정: D-110.

## 바꾼 설정
- ARB 문구 4개 추가(`audioLanguage*`). pubspec · Gradle · Manifest 변경 없음.

## 확인
`flutter analyze` 경고 0, `flutter test` 통과(엔진 · 캐시 · 큐 저장 · 시트 테스트 추가). 실제 유튜브 다국어 영상으로 목록이 뜨는지는 아직 기기에서 확인하지 못했다.

## 남은 일 · 질문
- 서버 모드는 서버 명세에 오디오 트랙 조회가 없어 언어를 고를 수 없다.
- 검색 결과 줄의 미리 듣기와 구독 새 영상 자동 받기는 기본 음성이다.
