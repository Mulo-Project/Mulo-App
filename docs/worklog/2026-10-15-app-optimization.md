# 앱 최적화 · 알림 셔플 버튼

- 날짜: 2026-10-15
- 분류: 앱
- 상태: 완료 (PR 대기)
- 브랜치 · 커밋: `chore/app-optimization`
- 상세 기능: 공통 작업

## 측정 (release APK)
| 구성 | 크기 |
|---|---|
| lite | 39MB |
| full arm64-v8a | 71MB |
| full armeabi-v7a | 65MB |
| full x86_64 | 75MB |
| full 통합(모든 ABI) | 188MB |

full의 큰 몫: `libffmpeg.zip.so` 36MB, `libpython.zip.so` 14MB, `libflutter.so` 12MB, `libapp.so` 10MB. 폰트 4.5MB(Pretendard 4종 1.6MB씩).
앱 데이터: youtubedl-android가 첫 실행에 ffmpeg · python을 풀어 쓰고(yt-dlp 업데이트 포함), 웹 커버 사본과 내장 커버 임시 파일이 캐시에 쌓였다.
→ 400MB는 통합 APK 설치(188MB + 푼 라이브러리) + 풀린 파이썬 · ffmpeg 데이터 + 캐시의 합으로 보인다. 실제 기기의 앱 정보(앱 · 데이터 · 캐시)로 확인이 필요하다.

## 한 일
- 상세 화면(앨범 · 아티스트 · 장르 · 재생목록)을 `LazyTrackList`로 바꿔 보이는 곡 줄만 만든다.
- 플로팅 재생 버튼은 진행도가 눈에 띄게 변할 때만 다시 그리고, 미니 플레이어 띠는 `RepaintBoundary`로 감쌌다.
- `CacheCleaner`: 시작할 때 웹 커버 사본 64MB 초과분과 내장 커버 임시 파일을 정리한다.
- 알림 셔플 버튼: 앱이 없을 때도 알림에 셔플을 둔다. 네이티브가 `extras`를 고쳐 켜고 끈다 (`PlaybackHub.toggleShuffle`). D-108.

## 바꾼 설정
- 없음 (배포 시 `flutter build apk --release --flavor full --split-per-abi` 권장).

## 확인
- `flutter analyze` 경고 0, `flutter test` 전체 통과, Kotlin 컴파일 확인. 기기에서 알림 셔플은 직접 확인 필요.

## 남은 일 · 질문
- 기기 앱 정보로 400MB 내역 확인, 프로파일링(`flutter run --profile`).
- 검색 · 최상위 곡 화면 lazy 렌더링, 행마다 `context.select` 정리.
