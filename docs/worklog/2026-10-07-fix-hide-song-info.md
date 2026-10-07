# 알림 곡 정보 숨기기 적용 안 됨 수정

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `fix/hide-song-info-notification`
- 상세 기능: 알림 곡 정보 숨기기 (#32)

## 한 일
- 원인: audio_service `MediaItem`의 `==`는 `id`만 비교한다. 핸들러가 id를 늘 `mulo.now_playing`으로 쓰므로 `mediaItem.value != item` 검사가 항상 같다고 보고, 첫 알림 뒤로는 제목 · 아티스트 · 커버가 갱신되지 않았다 (숨김 토글도 반영 안 됨).
- `MuloAudioHandler.show`에서 보이는 값(제목 · 아티스트 · 앨범 · 길이 · 커버)을 직접 비교하도록 바꿨다.

## 바꾼 설정
없음.

## 확인
- `flutter analyze`: 이 변경과 무관한 기존 info만 남음.
- 실기기 확인은 사용자에게 요청.
