# 앱 이름 Mulo · 패키지 com.mulo.app

- 날짜: 2026-10-01
- 분류: 설정 · 문서
- 상태: 완료 (PR 대기)
- 브랜치: `chore/rename-mulo` (`feature/download-popup`에서 땀, PR #13에 의존)
- 상세 기능: 없음 (공통 작업)

## 한 일
- 표시 이름을 Mulo로: Android `android:label`, iOS `CFBundleDisplayName` · `CFBundleName`, Windows 창 제목(`main.cpp`) · `Runner.rc`의 제품 정보.
- `applicationId` · `namespace`를 `com.mulo.app`으로, Kotlin 소스를 `kotlin/com/mulo/app/`로 옮기고 `package` 수정 (`git mv`). iOS 번들 ID도 `com.mulo.app`.
- README · CLAUDE.md · docs 제목과 원격 저장소 주소를 새 이름으로. 결정은 D-024.

## 바꾼 설정
- `android/app/build.gradle.kts`(namespace · applicationId), `AndroidManifest.xml`(label), `ios/Runner/Info.plist` · `project.pbxproj`, `windows/runner/main.cpp` · `Runner.rc`.
- pubspec `name` · `BINARY_NAME` · 채널 이름 · DB 이름은 그대로 (D-024).

## 확인
- `flutter analyze`, `flutter test`, `flutter build apk --debug` (결과는 PR 본문).

## 남은 일 · 질문
- 기존 `com.example.music_download_play_app` 앱이 설치된 기기는 예전 앱을 지워야 한다.
