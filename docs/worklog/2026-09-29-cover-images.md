# 곡 · 재생목록 커버 이미지 등록

- 날짜: 2026-09-29
- 분류: 앱
- 상태: 완료 (merge 대기, 저장은 drift 연결 때)
- 브랜치: `feature/library-cover-images` (`feature/settings-theme-presets` 위 — 그다음에 합친다)
- 상세 기능: 커버 이미지 등록 (새로 추가)

## 한 일
- 사용자 요청 "재생목록, 음원에 매칭되는 이미지를 등록" → D-014.
- `features/covers/`: `CoverController`(키 → 경로, pickFor · set · clear), `CoverImagePicker`(file_picker `pickFile`, 테스트용 교체 가능), `coverImageOf()`, `showCoverSheet()`.
- 커버 이미지 시트: 미리보기 · 사진에서 고르기 · 기본 이미지로 (있을 때만).
- 연결한 곳: 보관함 곡 줄(⋮ 버튼 + 커버 표시), 재생목록 카드(이미지 버튼, 사진이 있으면 카드 배경 + 아래쪽 어둡게), 전체 화면 플레이어(커버 누르기 · 편집 버튼), 대기열 시트, 미니 플레이어.
- ARB 문구 4개 (ko/en).
- 테스트: CoverController 3개 + 위젯(재생목록 카드 → 시트 → 사진 고르기) 1개.

## 바꾼 설정
- `pubspec.yaml`: `file_picker ^13.1.0`

## 확인
- `flutter analyze` 0, `flutter test` 통과.
- 에뮬레이터: 재생목록 카드 이미지 버튼 → 시트 → 시스템 사진 선택기가 열리고 사진 선택까지 확인.
  - 발견 · 수정: 시트가 미니 플레이어 · 탭 바 뒤에 뜸 → `useRootNavigator`. 선택기가 여러 장 모드 → `pickFile`(한 장)로.
  - 선택 후 결과 화면은 같은 에뮬레이터를 다른 앱(Translation-App)이 쓰기 시작해 확인하지 못함 → 적용은 위젯 테스트로 확인.

## 남은 일
- 앱을 다시 켜도 유지: drift 연결 때 파일 복사 + DB 저장.
- 다운로드한 곡은 유튜브 썸네일을 기본 커버로 (메타데이터 태그 입력 #8).
