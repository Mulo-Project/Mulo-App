# release 빌드 실기기 전체 테스트 · 수정

- 날짜: 2026-11-17
- 분류: 앱 · 설정
- 상태: 진행 중
- 브랜치 · 커밋: `fix/release-device-test`
- 상세 기능: 공통 (release 빌드 점검)

## 한 일
- #176(받기 엔진 네이티브 이전 + release R8 keep)을 develop에 합친 뒤, release 빌드로 전체 기능을 시험한다.
- 시험 목록은 `release-device-test-checklist.md`(프로젝트 공유 폴더 notes) 14개 섹션. 실패한 항목과 로그가 오면 이 PR 하나에서만 고친다 (PR을 쪼개지 않는다).
- 로그나 오류로 원인이 확인된 것만 고친다. 수정마다 건드린 곳과 안 건드린 곳을 남긴다.

- 섹션 1 · 2 통과 (release 앱 켜짐 · 엔진 업데이트 · 받기 · 알림 · 앱 잠금).
- 사용자 요청으로 앱 DB를 Dart(drift)에서 네이티브(Kotlin)로 옮겼다 (D-168). 이 PR 하나에 담는다.
  - 새: `MuloDb.kt` · `LibraryDb.kt` · `DbChannel.kt`(`music_app/db`), Dart `lib/core/database/native_db.dart` · `Native*Repository`.
  - 바꿈: `FavoriteStore.kt`(LibraryDb 사용) · `DownloadEngine.kt`(곡을 DB에 직접 등록, `registered`/`ack` 제거) · `MuloEngine.kt`(채널 등록) · DI · pubspec(drift 제거) · 문서.
  - 안 건드림: 도메인 인터페이스 · 유스케이스 · 화면 · 재생 · 태그 · 받기 큐 동작.

- 폴더 빼기: 곡을 200개씩 묶어 숨긴다 (곡마다 목록을 다시 읽던 것을 고침).
- 폴더 더하기 취소: 찾은 곡을 끝날 때까지 "불러오는 중"(`hidden = 2`)으로 두었다가 한 번에 보이게 하고, 취소하면 흔적 없이 지운다 (D-169).

### 이 PR에서 추가로 고친 것 (2026-11-19 기준)
- 대기열: 여러 곡 일괄 제거, 곡 정보 수정이 대기열 · 알림에 반영, 셔플 한 바퀴에서 처음 곡이 고정되던 것 수정.
- 미리 듣기: 즉시 로딩 표시, 네트워크 끊김 복구, 영상 로딩 표시. 알림 seek 제한.
- 자막 · 가사: 자막 네이티브 우선 읽기, 자막 기본 선택 제거 + 상세 화면 "적용 취소", 영상 하단 가사 표시(로컬 · 미리 듣기), 받기 창 가사 선택 유지, 자막 상세로 이동할 때 끊김 완화(읽기 · 채우기를 화면이 열린 뒤로).
- 받기: 새 재생목록 이름만 적고 완료해도 생성, 다운로드 알림 이어받기 버튼 갱신. 웹 이미지 검색 지역 고정.
- 가사 화면: 커버 배경 가장자리를 배경색으로 희미하게 번지게. 가사 편집 메모 카드 디자인 변경 · 머리와 구분선 · 글 사이 간격 12.
- 재생목록 가져오기: 공통 받기 설정(저장 유형 · 형식 · 폴더 · 아티스트 · 앨범 · 장르 · 영상)과 곡별 받기 설정(곡 받기 창 재사용, 공통값이 기본값). 공통 설정을 다시 열면 칸을 채운다. 영상 설정으로 연 받기 창에서 음원으로 바꾸면 폴더를 채운다.
- 보관함: 다중 선택에서 곡 한 번에 삭제, 여러 곡 삭제 동의 창을 한 번에 띄운다(Android 11+ `createDeleteRequest` 목록).
- l10n: 생성 파일(`app_localizations*.dart`)을 gen-l10n 출력 기준으로 정리 (빌드할 때마다 수정 상태가 되어 pull이 막히던 것 해결).
- 테스트 정비: 전체 통과(+657, skip 41).

### 안 쓰는 패키지 정리 (2026-11-24)
- `audio_metadata_reader` · `cupertino_icons`를 pubspec에서 뺐다. `lib` · `test` · 네이티브 어디에서도 가져다 쓰지 않는다 (태그 읽기 · 쓰기는 네이티브로 옮겨졌고, 아이콘은 `AppIcons`). `pubspec.lock`은 `flutter pub get`으로 갱신한다.
- docs의 예전 결정 · 작업 기록에 남은 `audio_metadata_reader` 언급은 당시 기록이라 그대로 둔다.

## 확인
섹션 1(release 전용)부터:
- 빌드: `flutter build apk --release --flavor full --split-per-abi --dart-define-from-file=dart_defines.local.json`
- 설치: `adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-full-release.apk` (기기 ABI에 맞는 파일)
- 로그: `adb logcat -c` 뒤 `adb logcat -s MuloPlayback MuloNative MuloTag flutter AndroidRuntime`
- 볼 것: 앱이 켜진다 · `ClassNotFoundException` / `NoSuchMethodError` / `NoSuchMethodException` / `JsonMappingException` / `FATAL EXCEPTION` 없음 · 검색 · 설정 탭이 열린다 · 받기 한 곡이 된다 · 알림 · 잠금화면 컨트롤이 뜬다.

- 섹션 1~10, 12(이퀄라이저) 실기기 확인 완료 (2026-11-20).
- 섹션 11(구독) · 13(설정) 실기기 확인 완료 (2026-11-24, 사용자 확인). 구독은 라이브 · 예정 영상 거르기, 받은 곡 길이, 기기 언어 음성, 새 영상 안내 줄 디자인을 고친 뒤 확인했다. 설정은 접기/펼치기 · 검색, 임시 저장 무제한, 정보 > 오픈소스 라이선스를 더한 뒤 확인했다.
- 체크리스트 8번 "가사 LRU 캐시 동작"은 오프라인 대비가 아니라 속도용 메모리 캐시다 (한 번 읽은 곡의 가사를 DB · 파일 · 태그에서 다시 읽지 않는다. 가사 자체는 기기에 저장돼 있어 오프라인에서도 보인다).

## 남은 일 · 질문
- 체크리스트 0번(debug 키 서명, 어댑티브 아이콘, 공유 메뉴 intent, network_security_config, Google 로그인 dart-define)은 시험하면서 필요한 것만 고친다.
- 체크리스트 14번 이후 실기기 확인.
