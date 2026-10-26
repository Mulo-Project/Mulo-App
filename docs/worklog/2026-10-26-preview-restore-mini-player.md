# 앱을 껐다 켜도 미리 듣기 미니 플레이어 되살리기

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `fix/preview-restore-mini-player` (기반: `develop`)
- 상세 기능: 검색 · 미리 듣기

## 한 일
- 문제: 미리 듣기 중 앱을 껐다 켜면 알림은 남는데 미니 플레이어가 안 뜬다. 알림 버튼은 `PreviewCubit`이 받으므로 Cubit이 idle이면 알림의 일시정지 · 중지가 듣지 않았다. 앱이 켜질 때 네이티브 재생 상태를 읽어 와 맞추는 코드가 없던 것이 원인.
- `PreviewChannel.kt`: `remember`(듣는 곡 정보 저장) · `current`(재생 상태 · 곡 정보 읽기) 추가. 소리를 내는 플레이어가 없는데 미리 듣기 알림만 남았으면 `current`가 알림도 치운다.
- Dart: `PreviewPlayer.remember/current`, 유스케이스 `RememberPreview` · `CurrentPreview`, `PreviewSnapshot` 엔티티. `PreviewCubit.syncWithPlayer()`가 앱 시작(생성 때)과 포그라운드 복귀(`NotificationBridge`)마다 화면 상태를 플레이어에 맞춘다: 듣는 중인데 화면이 idle이면 미니 플레이어 복원, 화면만 듣는 중이면 멈춤, 일시정지 상태 불일치 보정.
- 복원한 곡은 url이 없을 수 있어(기억해 둔 정보가 없을 때) 그 경우 미니 플레이어 탭으로 상세를 열지 않는다.

## 바꾼 설정
- 패키지 · Gradle · Manifest 변경 없음. 네이티브 채널 `music_app/preview`에 `remember` · `current` 메서드 추가.

## 확인
- `flutter analyze` 경고 0, `flutter test` 전체 통과 (`preview_test.dart`에 복원 · 동기화 테스트 4개 추가), `flutter build apk --debug --flavor lite` 통과(Kotlin 컴파일 포함).
- 실제 기기에서 미리 듣기 중 앱을 밀었다 다시 켜는 흐름은 확인하지 못했다.

## 남은 일 · 질문
- 기기에서 위 흐름과 알림 버튼(일시정지 · 중지) 동작 확인.
