# 곡 정보 편집: 태그 먼저 쓰고 DB 저장

- 날짜: 2026-10-22
- 분류: 앱
- 상태: 완료 (브랜치까지, PR은 성능 개선과 합쳐 올린다)
- 브랜치 · 커밋: `feature/write-tags-before-db`
- 상세 기능: 곡 정보 편집 (D-120)

## 한 일
- `UpdateTrackInfo`: 태그 쓰기 → 성공하면 DB. 실패하면 DB 그대로 + 스낵바 안내. 결과는 `UpdateInfoResult`.
- `TrackTagSource`/`TrackTagRepository.write`: `TagWriteResult`(written · unsupported · denied · failed)로 "쓸 수 없는 곡"과 "쓰려다 실패"를 가른다. `FfmpegTagWriter.available()` 추가.
- `renameAlbum`은 `(changed, failed)`를 돌려주고 앨범 화면이 실패를 안내한다. 문구 `trackEditTagFailed`(ko · en).
- 테스트: `embed_tags_test.dart`(성공 · 실패 · 쓰기 불가 · 권한 없음 · 빈 제목), `FakeTrackTagRepository`.

## 바꾼 설정
- 없음 (패키지 · Gradle · Manifest 변경 없음).

## 확인
- `flutter analyze` 경고 0, `dart format`. `flutter test`는 이 변경 범위 전부 통과. 같은 폴더의 다른 작업(`library_screen.dart` 미커밋 변경) 때문에 앨범 · 아티스트 · 장르 탭 테스트 4개가 실패하며, 그 변경을 빼면 모두 통과한다.
- 실제 기기의 ffmpeg 쓰기 · 덮어쓰기는 확인하지 못했다.

## 남은 일 · 질문
- 태그를 못 쓰는 기기 곡(권한 없음)은 DB만 고쳐서, 나중에 태그 복원이 다시 도는 경우 옛 값으로 돌아갈 수 있다.
