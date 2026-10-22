# 이미 받은 곡 다시 받기 확인

- 날짜: 2026-10-22
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `feature/redownload-confirm`
- 상세 기능: 받기 (중복 받기 방지)

## 한 일
- 이미 받은 곡은 체크 표시를 그대로 두되, 받기 버튼을 눌러도 막지 않고 "다시 받을까요?" 확인 대화상자를 띄운다. "다시 받기"를 고르면 받기 팝업이 열리고, 취소하면 닫힌다.
- 받는 중 · 대기 중인 곡은 이전처럼 안내 문구만 보이고 팝업을 열지 않는다.
- 재생목록 다시 가져오기의 중복 건너뛰기 동작은 바꾸지 않았다.

## 바꾼 설정
- ARB 문구 3개 추가(`downloadAgainTitle` · `downloadAgainBody` · `downloadAgainConfirm`). pubspec · Gradle 변경 없음.

## 확인
`flutter analyze` 경고 0, `flutter test` 통과 (상세 화면 위젯 테스트 추가).

## 남은 일 · 질문
- 쓰지 않게 된 `downloadAlreadyDownloaded` 문구는 남겨 두었다.
