# 재생 알림 디자인 개선

- 날짜: 2026-10-07
- 분류: 앱
- 상태: 완료 (merge 대기)
- 브랜치 · 커밋: `feature/playback-notification-design`
- 상세 기능: 재생 알림 (D-077)

## 한 일
- 웹 커버를 앱 캐시 사본(file 주소)으로 바꿔 알림에 넘김. 늦거나 못 받으면 원래 주소.
- 펼친 알림에 닫기 버튼 추가 (접힌 알림은 이전 · 재생 · 다음 그대로).
- 이동 막대(seek) 시스템 동작 유지, 정지 동작 추가.
- 알림 갱신이 겹칠 때 오래된 요청은 버림.

## 바꾼 설정
- 없음 (pubspec · Gradle · Manifest 변경 없음). 코드: `cached_web_image.dart`, `audio_service_media_session.dart`, `mulo_audio_handler.dart`, `media_session_info.dart`.

## 확인
- `flutter analyze` 경고 0, `flutter test` 통과, `flutter build apk --debug --flavor lite` 성공.
- 실기기에서 알림 모양은 아직 못 봄.

## 남은 일 · 질문
- 실기기 확인 (커버 · 펼친 알림 · 이동 막대).
