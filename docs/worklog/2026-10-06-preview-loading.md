# 미리 듣기 진행도 · 멈춤 방지

- 날짜: 2026-10-06
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `fix/preview-loading-progress`
- 상세 기능: 검색 결과 미리 듣기 (D-061 후속)

## 한 일
- 미리 듣기를 누르면 주소를 알아내고 불러오는 동안(몇 초 걸린다) 검색 줄 버튼과 상세 화면 버튼에 돌아가는 표시를 보인다. 소리가 나면 멈춤 표시로 바뀐다. `RowIconButton` · `PillButton`에 `busy` 인자.
- **재생 진행도**: 듣는 동안 검색 줄 아래에 막대(`ProgressLine`), 상세 화면에 막대 + `0:30 / 2:00`. 도메인 `PreviewProgress` · `PreviewPlayer.watchProgress` · 유스케이스 `WatchPreviewProgress`, `PreviewState.progress`/`fraction`.
- **"준비 중"에 멈추는 문제**: 미리 듣기가 `EngineException` 말고 다른 오류(플랫폼 오류 등)를 던지면 상태가 loading에 남고 소리도 안 났다. 이제 모든 오류를 실패로 돌려 안내를 띄우고, 주소 찾기 60초 · 불러오기 30초가 넘어도 실패로 돌린다.
- **스트림 주소는 `youtube_explode_dart`로 먼저 읽는다** (D-062). yt-dlp는 JS 실행기가 없으면 오디오 형식을 못 줄 수 있다. Android 네이티브 yt-dlp 호출도 옵션을 값과 짝으로 넘기게 고쳤다.
- 시작하지 못했을 때 안내를 까닭별로: 네트워크 · 찾을 수 없음 · 이 기기에서 못 씀 · 그 밖.

## 바꾼 설정
- `pubspec.yaml`에 `youtube_explode_dart: ^3.1.0` 추가. Notion 기술 스택 행은 아직 못 더했다.

## 확인
- `flutter analyze` 0, `flutter test` 전체 통과.
- "미리 듣기가 안 된다"는 실제 기기에서 재현하지 못했다 (이 PC에 yt-dlp · Android 기기 없음). 코드상 Android lite(서버 전용) 빌드는 서버에 스트림 조회가 없어 처음부터 못 쓴다 (D-061). full 빌드에서 안 되면 안내 문구가 이제 까닭별로 나온다.

## 남은 일 · 질문
- 어느 빌드(lite · full · 데스크톱)에서 어떤 안내가 뜨는지 알려 주면 원인을 좁힐 수 있다.
