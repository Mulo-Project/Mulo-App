# 알림을 지운 뒤에도 이어폰 버튼으로 이어 재생 (기본 켬)

- 날짜: 2026-10-28
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `fix/media-button-resume-default` (기반: `develop`)
- 상세 기능: 공통 작업 (알림 · 블루투스 미디어 버튼, [media-button-resume](2026-10-28-media-button-resume.md)에 이어)

## 한 일
- 재생 알림을 밀어 지우거나 X로 닫은 뒤 이어폰 · 블루투스 버튼이 무시되던 것이 버그로 보고돼, 설정 '알림이 없어도 블루투스로 재생'의 기본값을 꺼짐 → **켬**으로 바꿨다 (D-135). 설정으로 끌 수는 있다.
- 기본값을 Dart(`OutputBehavior` · `PrefsOutputBehaviorRepository`)와 Kotlin(`PlaybackStore` · `PlaybackHub` · `PlaybackChannel`)에서 같게 맞췄다.

## 바꾼 설정
- 없음 (코드 기본값만).

## 확인
- `flutter analyze` 경고 0, `flutter test test/features/player` 통과.
- 기기에서 확인하지 못했다. 이미 설정을 한 번이라도 바꿔 저장값(false)이 있는 기기는 기본값이 적용되지 않으니 설정에서 직접 켜야 한다.
