# 장르 상세 화면 · 재생 옆 셔플 버튼 · 재생목록 셔플 메뉴

- 날짜: 2026-10-04
- 분류: 앱
- 상태: 완료
- 브랜치 · 커밋: `feature/genre-detail-shuffle`
- 상세 기능: 공통 (보관함 · 재생목록)

## 한 일
- 장르: 보관함 장르 탭 안에서 목록이 바뀌던 방식을 없애고, 앨범 · 아티스트처럼 별도 상세 화면(`/library/genre?name=`, `GenreScreen`)으로 연다. 보관함의 `_genre` 상태와 `_GenreHeader`를 지움.
- 재생 + 셔플 한 줄: 공통 위젯 `PlayShuffleRow`를 만들어 앨범 · 아티스트 · 장르 · 재생목록 상세에서 쓴다.
- 재생목록 ⋮ 메뉴(카드 · 상세 공통)에 "셔플 재생" 항목 추가.
- `NowPlayingCubit.playShuffled`: 처음부터 재생하고 셔플을 켠다 (보관함 히어로의 셔플도 이걸 쓴다).

## 바꾼 설정
- 없음. ARB: `genreBack` 삭제, `genreNotFound` · `playlistMenuShuffle` 추가.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (장르 화면 · playShuffled 테스트 추가, 옛 장르 목록 테스트 수정).

## 남은 일 · 질문
- 없음.
