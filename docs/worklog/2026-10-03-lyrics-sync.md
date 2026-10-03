# 가사 싱크 맞추기 화면

- 날짜: 2026-10-03
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `feature/lyrics-sync` · develop에 merge
- 상세 기능: 가사 (로컬 가사)

## 한 일
- `SyncDraft`(domain): 줄마다 시간 찍기 · 조정 · 되돌리기 · LRC 변환.
- `LyricsSyncCubit` · `LyricsSyncScreen`: 곡 재생 + "지금" 버튼, 줄 탭, 줄별 ±0.1/±0.5초, 다시 듣기, 되돌리기, 저장.
- 가사 설정 창에 "싱크 맞추기" 버튼. 저장하면 그 LRC로 바로 저장하고 창을 닫는다 ([D-048](../decisions.md)).
- 문구 ARB(ko · en) 추가.

## 바꾼 설정
- 없음 (패키지 · 매니페스트 변경 없음).

## 확인
- `flutter analyze` 경고 0, `flutter test` 174개 통과 (싱크 모델 · 화면 흐름 테스트 추가).

## 남은 일 · 질문
- 재생 엔진(just_audio)이 붙기 전에는 재생 위치가 움직이지 않는다. 연결하면 그대로 동작한다.
