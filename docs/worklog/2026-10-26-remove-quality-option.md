# 음질 선택 제거 (항상 최고 음질)

- 날짜: 2026-10-26
- 분류: 앱
- 상태: 진행 중 (PR 대기)
- 브랜치 · 커밋: `feature/remove-quality-option` (기반: `develop`)
- 상세 기능: 음질 선택 #6, 기본 음질·포맷 설정 #24

## 한 일
- 음질 선택을 없앴다 (D-131). 유튜브 원본이 보통 128 ~ 160 kbps라 높게 변환해도 용량만 커지기 때문이다.
- 설정의 "기본 음질" 줄, ARB `settingsQuality` · `quality*`, `Quality` 열거형, 음질 저장/읽기 유스케이스와 저장소 메서드, 곡별 `DownloadRequest.quality`를 지웠다.
- `TranscodePlan.of(format)`: mp3만 192 kbps로 변환, opus · m4a는 원본 그대로 (예전 "최고"와 같은 동작). 형식 선택은 그대로다.
- 예전 저장값(`download.quality`, 대기열 JSON의 `quality`)은 읽지 않고 무시한다. 서버 엔진 계약에는 음질 필드가 없었다.

## 바꾼 설정
- 패키지 · Gradle · Manifest 변경 없음. 화면 문구(ARB)에서 음질 4개를 뺐다.

## 확인
- `flutter analyze` 경고 0, `flutter test` 전체 통과. 변환 방법 · 대기열 테스트를 새 동작에 맞췄고, 예전 `quality` 값이 든 대기열 JSON을 읽어도 그대로 복원되는 테스트를 더했다.
- 실제 기기에서 설정 화면과 mp3 변환 결과를 직접 보지는 못했다.

## 남은 일 · 질문
- (없음)
