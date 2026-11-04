# 대기열 편집을 네이티브 명령으로 (재생 상태 일원화 2단계)

- 날짜: 2026-11-04
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `refactor/native-queue-edit-commands`
- 상세 기능: 재생 상태 네이티브 일원화 계획 (D-153)

## 한 일
- 네이티브 `playNext` · `addToQueue` · `removeFromQueue` · `moveInQueue` 추가, 편집 뒤 `queue` 이벤트로 알림.
- `NowPlayingCubit`의 편집은 화면에 먼저 반영하고 엔진에는 명령만 보낸다 (통째 `setQueue` 푸시 제거).
- 가짜 엔진이 편집을 흉내 내도록 고치고 테스트를 새 약속에 맞췄다.

## 바꾼 설정
- 없음.

## 확인
- 클라우드 환경이라 빌드 · analyze · test 못 돌림. PC에서 `flutter analyze` → `flutter test` → `flutter build apk --debug --flavor full`.
- 기기: 재생 중 다음에 재생 / 맨 뒤 추가 / 순서 이동 때 소리가 안 끊기는지, 듣던 곡 삭제(중간 · 마지막 곡), 셔플 중 편집, 알림 이전/다음, 앱 종료 후 복원.

## 남은 일 · 질문
- 3단계: Cubit이 편집을 계산하지 않고 `queue` 이벤트만 비추게.
