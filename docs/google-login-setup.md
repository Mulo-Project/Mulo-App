# 구글 로그인 설정 (내 유튜브 재생목록)

"내 재생목록"을 불러오려면 구글 로그인이 필요하고, 로그인에는 Google Cloud의 OAuth 클라이언트 ID가 빌드에 들어 있어야 한다 (D-073).
값이 없으면 설정의 로그인 버튼이 꺼져 있고 어떤 값이 없는지 문구로 알려 준다. 값은 저장소에 넣지 않고 `--dart-define`으로만 넣는다.

| 기기 | 필요한 값 | 만드는 클라이언트 |
|---|---|---|
| Android | `MULO_GOOGLE_SERVER_CLIENT_ID` | 웹 애플리케이션 (+ Android 클라이언트가 같은 프로젝트에 있어야 함) |

## 1. Google Cloud 프로젝트 만들기
1. <https://console.cloud.google.com> 에 로그인 → 위쪽 프로젝트 선택 → **새 프로젝트** → 이름 `Mulo` → 만들기.
2. 만든 프로젝트가 선택돼 있는지 확인한다.

## 2. YouTube Data API v3 켜기
1. 왼쪽 메뉴 **API 및 서비스 → 라이브러리**.
2. `YouTube Data API v3` 검색 → 선택 → **사용**.

## 3. OAuth 동의 화면 + 테스트 사용자
1. **API 및 서비스 → OAuth 동의 화면**(또는 Google Auth Platform → 브랜딩/대상).
2. 사용자 유형 **외부** → 앱 이름 `Mulo`, 지원 이메일 · 개발자 연락처 이메일 입력 → 저장.
3. **범위(데이터 액세스)** 에서 `.../auth/youtube.readonly` 추가.
4. **대상(테스트 사용자)** 에서 **테스트 사용자 추가** → 앱에서 로그인할 구글 계정 이메일을 넣는다.
   게시 상태가 "테스트 중"인 동안은 여기에 넣은 계정만 로그인할 수 있다 (최대 100명).

## 4. Android 클라이언트 (패키지 + SHA-1)
Android는 "패키지 이름 + 서명 지문"으로 앱을 확인한다. 이 클라이언트 ID 자체는 앱에 넣지 않지만 **만들어 두지 않으면 로그인이 실패**한다.

디버그 SHA-1 (이 PC, PowerShell):
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```
출력의 `SHA1:` 줄 값을 복사한다. `keytool`이 없다고 나오면 대신:
```powershell
cd android; .\gradlew signingReport
```
(`Variant: liteDebug` 또는 `fullDebug` 아래의 `SHA1`.)

1. **API 및 서비스 → 사용자 인증 정보 → 사용자 인증 정보 만들기 → OAuth 클라이언트 ID**.
2. 애플리케이션 유형 **Android**, 패키지 이름 `com.mulo.app`, SHA-1 인증서 지문에 위 값을 붙여 넣기 → 만들기.
3. 출시용 서명 키를 쓰게 되면 그 키의 SHA-1로 Android 클라이언트를 하나 더 만든다.

## 5. 웹 클라이언트 ID → `MULO_GOOGLE_SERVER_CLIENT_ID`
1. 같은 화면에서 OAuth 클라이언트 ID 만들기 → 유형 **웹 애플리케이션** → 이름 `Mulo Web` → 만들기 (리디렉션 URI는 비워도 된다).
2. 나온 **클라이언트 ID**(`...apps.googleusercontent.com`)를 복사한다 → 이것이 `MULO_GOOGLE_SERVER_CLIENT_ID`.

## 6. 실행할 때 값 넣기
### 터미널
```powershell
flutter run --dart-define=MULO_GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
```

### 파일로 한 번에 (권장)
1. 저장소 루트의 `dart_defines.example.json`을 `dart_defines.local.json`으로 복사하고 값을 채운다 (`.gitignore`에 들어 있어 올라가지 않는다).
2. 실행:
```powershell
flutter run --dart-define-from-file=dart_defines.local.json
flutter build apk --debug --dart-define-from-file=dart_defines.local.json
```
Android flavor를 쓰면 `--flavor lite`(또는 `full`)를 같이 붙인다.

### VS Code
`.vscode/launch.json`의 **Mulo (구글 로그인 값 포함)** 구성이 위 파일을 읽는다. 실행 및 디버그 창에서 그 구성을 고르고 F5.
Android Studio는 Run/Debug Configurations → **Additional run args**에 `--dart-define-from-file=dart_defines.local.json`.

## 확인
앱 설정 > 계정의 "로그인" 버튼이 켜져 있고, 누르면 구글 로그인 창이 뜨면 된다.
테스트 사용자가 아닌 계정이면 "액세스 차단됨(앱이 인증되지 않음)"이 나온다 → 3단계의 테스트 사용자에 추가한다.
Android에서 `정의되지 않은 오류` · 로그인 창이 바로 닫히면 4단계의 패키지 이름 · SHA-1이 맞는지 확인한다.
