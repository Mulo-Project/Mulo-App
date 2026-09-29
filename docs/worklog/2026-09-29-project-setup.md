# 프로젝트 설정 (git 컨벤션, 규칙, Pretendard)

- 날짜: 2026-09-29
- 분류: 설정 · 문서 · 디자인
- 상태: 완료
- 브랜치: `main`(초기 설정) · `feature/design-system`(Pretendard)
- 상세 기능: 없음 (공통)

## 한 일
- git 저장소 생성: `main`(초기 설정 커밋) → `develop` → 작업 브랜치 `feature/design-system`.
- Git 규칙 [git.md](../git.md): 브랜치 · 커밋 형식(`<type>(<scope>): 한국어 요약`) · merge 승인 · 태그. PR 템플릿 `.github/pull_request_template.md`.
- 프로젝트 규칙 [CLAUDE.md](../../CLAUDE.md): 진행 방식, 기록 방법(worklog · decisions · Notion), 아키텍처, 폴더 구조, 코드 스타일.
- 문서 구조: [docs/README.md](../README.md), [decisions.md](../decisions.md)(D-001~D-007), `docs/worklog/`.
- Pretendard 적용: v1.3.9 공식 배포본에서 Regular · Medium · SemiBold · Bold(OTF)와 라이선스만 `assets/fonts/pretendard/`에 넣고, 테마 기본 글꼴로 지정 (D-006).
- 곡 분위기 테마는 설정이 켜져 있을 때만 적용하기로 기록 (D-005, 구현은 나중).

## 바꾼 설정
- `pubspec.yaml`: `description` 한국어로, `flutter.fonts`에 Pretendard 4굵기 등록.
- `.gitignore`: 기본값 유지.

## 확인
- `flutter analyze` 0, `flutter test` 통과, 에뮬레이터에서 Pretendard 표시 확인.

## 남은 일 · 질문
- GitHub 원격 저장소는 아직 없음 → 만들면 `docs/git.md`에 주소 추가 후 push.
- 서버(Spring Boot)를 같은 저장소에 둘지(예: `server/`) 따로 둘지 미정.
