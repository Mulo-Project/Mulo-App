# 가짜 데이터 제거

- 날짜: 2026-10-04
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `chore/remove-sample-data`
- 상세 기능: 공통

## 한 일
- 가짜 데이터 목록을 조사했다: `SampleData`(곡 12 · 재생목록 이름 · 엔진/앱 버전), 디버그 시드(`seedSampleData`), `SampleDownloadQueueRepository`, 검색 화면의 가짜 결과 · URL 카드 · 재생목록 선택, 설정의 가짜 엔진 버전. 재생도 화면 상태만 움직인다 (엔진 없음).
- 위 파일 · 코드를 지웠다. 보관함 · 재생목록 · 홈은 원래 실제 DB라 빈 상태 화면이 나온다.
- 다운로드 대기열은 빈 `MemoryDownloadQueueRepository`. 검색은 입력 시 "준비 중" 안내. 설정의 yt-dlp 카드는 뺐다.
- 테스트용 곡은 `test/helpers/test_data.dart`로 옮겼다. 받기 팝업 테스트는 검색 결과 대신 팝업을 직접 연다.

## 바꾼 설정
- 없음 (패키지 · 매니페스트 변경 없음). ARB: `searchNotReadyTitle` · `searchNotReadyBody` 추가.

## 확인
- `flutter analyze` 0, `flutter test` 통과.

## 남은 일 · 질문
- 실제 기능: 재생(just_audio), yt-dlp 검색 · 다운로드, 엔진 업데이트.
