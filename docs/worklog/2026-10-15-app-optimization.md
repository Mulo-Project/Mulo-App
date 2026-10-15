# 앱 용량 줄이기 · 수면 타이머 휠 · 받기 줄 정리

- 날짜: 2026-10-15
- 분류: 앱
- 상태: 진행 중
- 브랜치 · 커밋: `chore/app-optimization`
- 상세 기능: 공통 작업

## 한 일
- 릴리스 R8 코드 · 리소스 축소 + 유지 규칙 (D-108). ABI 분할 빌드로 full arm64 71MB (기존 한 덩어리 188MB).
- 수면 타이머를 시간 · 분 휠 대화상자로 (`WheelPicker` 신규).
- 받기 줄: 손잡이 · 펼치기 줄 정리, 펼침 애니메이션, 미니 플레이어와 선 · 썸네일 맞춤. "받는 곡 숨기기" 제거.

## 바꾼 설정
- `android/app/build.gradle.kts` 릴리스 `isMinifyEnabled` · `isShrinkResources`, `android/app/proguard-rules.pro` 추가.

## 확인
- `flutter analyze` 경고 0, 관련 테스트 통과. `flutter build apk --release --flavor full --split-per-abi` 성공. R8 적용 앱의 실기기 동작(받기 · 변환)은 아직 못 확인.

## 남은 일 · 질문
- 설치 후 크기(앱 데이터에 풀리는 python · ffmpeg)는 실기기에서 측정.
