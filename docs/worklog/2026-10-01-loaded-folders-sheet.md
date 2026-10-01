# 불러오는 폴더 목록 (바텀 시트)

- 날짜: 2026-10-01
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치: `feature/loaded-folders-sheet` (`feature/theme-nav-home` 위, PR #19 다음)
- 상세 기능: 불러오는 폴더 목록 (FD-44)

## 한 일
- 설정 › 다운로드의 저장 위치 아래에 **불러오는 폴더** 줄. 부제는 "n개 폴더", 누르면 바텀 시트.
- 바텀 시트: 폴더 경로 · 폴더별 곡 수(하위 폴더 포함) · 삭제 버튼, 아래에 "폴더 추가". 기본 저장 위치는 맨 위에 항상 있고 삭제 버튼이 없다 (D-028).
- 폴더를 더하거나 빼면 보관함을 다시 스캔하고(`LoadedFoldersCubit` → `ImportDeviceMusic`) 곡 수를 새로 센다. 시트는 스캔 중 안내 문구를 보여 주고 버튼을 잠근다.
- 스캔이 폴더 목록을 따른다: Android는 MediaStore 결과를 폴더 기준으로 거르고, 데스크톱은 목록의 폴더를 직접 스캔한다 (겹치는 폴더의 같은 파일은 한 번만). 데스크톱의 보관함 "불러오기" 버튼은 이제 폴더 고르기 대신 이 목록을 스캔한다 (폴더 고르기는 "폴더 추가"로 옮김).
- `Track.folder`, drift `tracks.folder`(스키마 5). 폴더 칸이 생기기 전에 넣은 곡은 다시 찾을 때 폴더를 채운다.
- 구조: `LoadedFolderRepository`(domain) / `PrefsLoadedFolderRepository`(shared_preferences + 폴더 고르기), 유스케이스 `LoadLoadedFolders` · `AddLoadedFolder` · `RemoveLoadedFolder`, `ImportDeviceMusic`은 폴더 목록을 `scan(folders)`에 넘김.
- 테스트(8): 경로 정규화 · 하위 폴더 판정, 목록 · 곡 수, 추가(취소 · 중복), 삭제(기본 위치 불가), 변경 시 재스캔, 데스크톱 스캔, DB 폴더 채우기, 설정 → 시트 위젯.

## 바꾼 설정
- 새 패키지 없음 (file_picker · shared_preferences는 이미 사용 중).
- drift 스키마 4 → 5 (`tracks.folder`), `build_runner`로 `app_database.g.dart` 재생성.
- Kotlin `MediaStoreChannel.kt`: 조회 열에 `DATA`를 더해 `folder`(파일의 상위 폴더)를 함께 보냄.
- 문구(ko · en) 7개 추가, `SampleData.savePath`를 `.../Music/Mulo`로 (기본 저장 위치와 맞춤).

## 확인
- `flutter analyze` 0, `flutter test` 통과, `flutter build apk --debug` 성공.
- 에뮬레이터 · 실기기에서의 직접 확인은 하지 않았다 (Android 실제 MediaStore 폴더 거르기 미확인).

## 남은 일 · 질문
- Notion 상세 기능에 같은 이름이 두 개 있다 (FD-44 동작 상세 있음, FD-75 비어 있음). FD-44 기준으로 구현. 하나로 합쳐야 한다.
- 폴더를 빼도 이미 보관함에 들어온 곡은 지우지 않는다 (곡 삭제는 #13). 곡 수 목록에서만 빠진다.
- 저장 위치 설정(#23)이 아직 자리 표시라 기본 저장 위치는 고정값(Android `/storage/emulated/0/Music/Mulo`, 데스크톱 `<홈>/Music/Mulo`)이다. #23 구현 때 연결.
- Android 폴더 고르기(file_picker)가 SD 카드 · 앱 전용 경로에서 돌려주는 경로 형식은 확인 필요.
