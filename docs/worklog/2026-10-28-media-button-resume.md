# 이어폰 버튼으로 재생 서비스 되살리기 (간헐 실패 고치기)

- 날짜: 2026-10-28
- 분류: 앱
- 상태: 진행 중 (기기 확인 대기)
- 브랜치 · 커밋: `fix/media-button-resume` (기반: `develop`)
- 상세 기능: 공통 작업 (알림 · 블루투스 미디어 버튼, [2026-10-12](2026-10-12-bluetooth-media-controls.md) · [2026-10-14](2026-10-14-foreground-service-fix.md)에 이어)

## 원인 (코드로 확인한 것)
- 리시버(`MuloMediaButtonReceiver`)는 저장소의 `resumable`만 보고 포그라운드 서비스를 띄운다. 그런데 앱이 알림 설정을 끄거나 곡이 없다고 `setSession(null)`을 보내면 세션은 서비스에서 빠지고 `SessionPlayer.info`가 null이라 플레이어 상태가 비어(재생 명령 없음) 있다. 대기열은 남아 `resumable`은 true이므로, 이때 버튼은 서비스만 띄우고 재생도 알림도 못 올려 아무 일도 하지 않았다 (포그라운드 시작 기한도 넘길 수 있다).
- `startForegroundService`가 백그라운드 제한으로 거부돼도(`ForegroundServiceStartNotAllowedException`) 조용히 지나가 원인을 알 수 없었다.
- (확인만, 바꾸지 않음) 일시정지한 채 최근 작업에서 앱을 밀거나 알림을 밀어 지우면 D-103 정책대로 버튼을 무시한다. 이것은 설계이고 설정 '알림이 없어도 블루투스로 재생'으로 푼다.

## 한 일
- `MediaButtonPolicy`(순수 규칙) + `PlaybackHub.prepareForButton()`: 버튼이 깨운 서비스는 세션을 만들고, 알림 내용이 없으면 대기열의 곡 정보로 채우고, 세션을 서비스에 올린다 (알림을 지운 뒤 이어 재생하는 설정이면 되살리기 포함, 전의 `reviveForButton` 대체).
- `MuloPlaybackService.onStartCommand`가 위를 부르고, 대기열이 없으면 서비스를 끝낸다.
- 리시버가 포그라운드 서비스 시작 거부를 `PlaybackStore.logStop`(`stopLog`)에 남긴다.
- 테스트: `MediaButtonPolicyTest`(JVM, 5개).

## 바꾼 설정
- `android/app/build.gradle.kts`: `testImplementation("junit:junit:4.13.2")` 추가. Manifest · pubspec 변경 없음.

## 확인
- `gradlew :app:testLiteDebugUnitTest` 통과 (Kotlin 컴파일 포함).
- **기기에서 확인하지 못했다**: 알림 설정을 끈 채 이어폰 버튼, 프로세스가 죽은 뒤 버튼, 백그라운드 제한 거부 경로는 실기기 확인이 필요하다. 알림을 꺼 둔 사용자도 버튼으로 재생하면 서비스 때문에 알림이 한 번 뜬다.
