# CI · 태그 배포 (GitHub Actions)

- 날짜: 2026-11-23
- 분류: 설정
- 상태: 진행 중 (Actions에서 첫 실행 확인 대기)
- 브랜치: `chore/ci-cd-github-actions-release`

## 한 일
- `.github/workflows/ci.yml`, `release.yml` 추가. 절차 · Secrets 목록은 [docs/release.md](../release.md), 결정 D-170.
- `android/app/build.gradle.kts`: release 서명 설정(env / `key.properties`), CI 배포는 키가 없으면 실패.

## 바꾼 설정
- Gradle 서명 설정, README 빌드 절 링크.

## 확인
- 클라우드 스레드라 빌드 · Actions 실행은 못 했다. workflow YAML 문법만 확인. 첫 실행은 PR의 CI에서.

## 남은 일 · 질문
- Secrets 5개 등록, 키스토어 생성, 구글 OAuth에 release SHA-1 등록.
