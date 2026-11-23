# 릴리스 · CI/CD

배포는 Play 스토어가 아니라 **GitHub Release의 APK**다 (Play는 유튜브 받기 앱을 받지 않는다). Android만.

## 흐름
| 언제 | 무엇 | 파일 |
|---|---|---|
| PR · `develop`/`main` push | `flutter analyze` · `flutter test` · debug APK 빌드 · 네이티브 단위 테스트 | `.github/workflows/ci.yml` |
| `v*` 태그 push | 위 검사 → 서명된 release APK(arm64 · armv7 · x86_64) → GitHub Release | `.github/workflows/release.yml` |

## 릴리스 내기
1. `pubspec.yaml`의 `version`을 올린다 (예: `1.0.1+2`). `+` 뒤 숫자(versionCode)는 매번 올려야 업데이트 설치가 된다.
2. `main`에 합친 뒤 태그를 만든다: `git tag v1.0.1 && git push origin v1.0.1`
3. Actions의 **Release**가 끝나면 Releases에 `Mulo-v1.0.1-arm64-v8a.apk` 등이 올라온다. 휴대폰은 거의 `arm64-v8a`.
- 태그(`v1.0.1`)와 pubspec 이름 부분(`1.0.1`)이 다르면 실패한다. `v1.0.1-beta1`처럼 `-`가 있으면 pre-release.

## Flutter 버전
CI는 `3.47.x`로 고정했다 (`ci.yml` · `release.yml`의 `flutter-version`). 최신 stable(3.50)은 `package:flutter/material.dart` 사용을 deprecated로 보고해 `flutter analyze`가 실패했다. PC의 Flutter를 올리면 두 파일의 값도 같이 올린다.

## GitHub Secrets (Settings → Secrets and variables → Actions)
| 이름 | 내용 |
|---|---|
| `MULO_KEYSTORE_BASE64` | 키스토어 파일을 base64로 바꾼 한 줄 |
| `MULO_KEYSTORE_PASSWORD` | 키스토어 비밀번호 |
| `MULO_KEY_ALIAS` | 키 별칭 |
| `MULO_KEY_PASSWORD` | 키 비밀번호 |
| `MULO_DART_DEFINES` | `dart_defines.local.json` 내용 전체(JSON). 최소 `MULO_GOOGLE_SERVER_CLIENT_ID` |

## 키스토어 만들기 (한 번만)
```bash
keytool -genkeypair -v -keystore mulo-release.jks -alias mulo -keyalg RSA -keysize 2048 -validity 36500
# Windows PowerShell (결과를 클립보드에 복사)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("mulo-release.jks")) | Set-Clipboard
# macOS / Linux: base64 -i mulo-release.jks | tr -d '\n'
keytool -list -v -keystore mulo-release.jks -alias mulo   # SHA-1 확인
```
- 한국어 Windows의 keytool은 확인 질문(`[아니오]:`)에 `yes`를 못 알아듣고 같은 질문을 되풀이한다. **`y`**(또는 `예`)를 입력한다.
- 키스토어 파일과 비밀번호는 **반드시 따로 백업**한다. 잃으면 같은 앱으로 업데이트할 수 없다.
- 저장소에 올리지 않는다 (`*.jks` · `key.properties`는 gitignore).
- **구글 로그인**: 구글 클라우드 콘솔의 Android OAuth 클라이언트(패키지 `com.mulo.app`)에 위 **release 키의 SHA-1**을 추가해야 배포 APK에서 로그인이 된다.
- 지금까지 설치된 앱은 debug 키로 서명돼 있어서, release 키 APK는 **업데이트가 안 되고 지우고 다시 설치**해야 한다 (보관함 파일은 기기 저장소에 남지만 앱 DB는 사라진다).

## 로컬에서 서명 빌드
`android/key.properties`(git 제외)에 `storeFile=` `storePassword=` `keyAlias=` `keyPassword=`를 적으면 `flutter build apk --release --flavor full --split-per-abi --dart-define-from-file=dart_defines.local.json`이 서명한다. 키가 없으면 로컬 release는 debug 키로 서명된다 (배포 금지). CI 배포는 키가 없으면 실패한다 (`MULO_REQUIRE_RELEASE_SIGNING`).
