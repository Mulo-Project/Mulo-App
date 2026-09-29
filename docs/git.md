# Git 규칙

원격 저장소: 아직 없음 (GitHub 공개 예정). 생기면 여기에 주소를 적는다.

## 브랜치
| 브랜치 | 용도 | 만드는 곳 → 합치는 곳 |
|---|---|---|
| `main` | 배포 가능한 상태. 직접 커밋 금지 | `develop` → `main` (릴리스 때) |
| `develop` | 통합 브랜치. 직접 커밋 금지 | 작업 브랜치 → `develop` |
| `feature/<scope>-<요약>` | 기능 하나 (Notion 상세 기능) | `develop`에서 → `develop`으로 |
| `ui/<scope>-<요약>` | 화면 퍼블리싱 묶음 (화면마다 커밋 분리) | `develop`에서 → `develop`으로 |
| `fix/<scope>-<요약>` | 버그 수정 | `develop`에서 → `develop`으로 |
| `chore/<요약>` · `docs/<요약>` | 설정 · 빌드 · 문서 | `develop`에서 → `develop`으로 |
| `hotfix/<요약>` | 배포본 긴급 수정 | `main`에서 → `main` + `develop` |

- 요약은 영어 소문자 · 하이픈. 예: `feature/player-mini-player`, `chore/pretendard-font`
- 브랜치 하나에는 한 가지 작업만.

## 커밋 메시지
```
<type>(<scope>): <무엇을 했는지, 한국어, 50자 안쪽>

<필요하면 본문: 왜 바꿨는지, 참고할 점>

Refs: 상세 기능 #<Notion ID>   ← 관련 명세가 있으면
```
- **type**: `feat` 기능 · `fix` 버그 · `ui` 화면 퍼블리싱 · `design` 디자인 시스템 · `refactor` · `test` · `docs` · `chore`(빌드 · 설정 · 의존성) · `style`(포맷만)
- **scope** (영역): `app` · `design` · `player` · `download` · `library` · `playlist` · `lyrics` · `settings` · `server` · `build` · `docs`. 영역이 없으면 괄호 생략.
- 예: `design(design): 글로우 카드 추가`는 중복이므로 `design: 글로우 카드 추가`처럼 scope를 생략해도 된다.
- 생성 코드는 원본과 같은 커밋에 넣는다.
- 커밋 전: `dart format`, `flutter analyze` 경고 0, `flutter test` 통과.

## Push · PR · Merge
- 작업 브랜치 커밋 · push는 자유롭게 한다.
- `develop` · `main`으로의 합치기는 PR로만 하고(원격이 생기기 전에는 로컬 merge), **합치기 전에 사용자 승인을 받는다.**
- PR 제목은 커밋 규칙과 같은 형식, 본문은 `.github/pull_request_template.md`.
- merge 방식: 작업 브랜치 → `develop`은 Squash merge 기본, 커밋을 남겨야 하는 `ui/` 묶음은 Merge commit. `develop` → `main`은 Merge commit.

## 태그 · 버전
- `main`에 합칠 때 `v<major>.<minor>.<patch>` 태그와 `pubspec.yaml`의 `version`을 같이 올린다. MVP 완료 = `v0.1.0`.
