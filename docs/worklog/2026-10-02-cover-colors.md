# 커버 색 자유 선택 · 재생목록 카드 정리

- 날짜: 2026-10-02
- 분류: 앱 · 디자인
- 상태: 완료 (PR 대기)
- 브랜치: `feature/cover-colors`
- 상세 기능: 재생목록 관리 (#20) · 공통 (사용자 피드백 2026-10-02, 1/3)

## 한 일
- 앨범 · 재생목록 · **곡**의 커버 색을 테마와 상관없이 자유롭게 고른다 (색상 막대 + 견본). 곡 모델에는 색이 없었어서 같은 저장소(`cover_colors`)를 새로 두었다.
- 재생목록 카드: 대표곡 글자를 제목보다 작게.
- 보관함 요약 카드: 재생 중인 곡의 이미지를 오른쪽에 보여 준다.
- 구조: `CoverColorRepository` · 유스케이스 3개 · `CoverColorCubit`, 재생목록의 `colorIndex` · `setColor` 제거.

## 바꾼 설정
- drift 스키마 6 → 7 (`cover_colors` 추가, 생성 코드 `app_database.g.dart` 갱신).
- 문구(ko · en): `colorSheetTitle` · `colorCustom` · `colorOption` · `albumColorTooltip` · `trackMenuColor` 추가, `playlistColorPrimary` · `Secondary` · `Tertiary` · `Option` 삭제.
- 새 패키지 · 에셋 · 네이티브 변경 없음.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (재생목록 색 시트 · 새 재생목록 색 · 색 저장소 테스트).

## 남은 일 · 질문
- 옛 재생목록 색(테마 톤 번호)은 이전하지 않고 자동 색으로 돌아간다.
- 검색 결과(샘플) 곡은 아직 색이 연결되지 않는다 (실제 곡이 아님).
