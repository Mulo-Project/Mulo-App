# 유리 범위 줄이기 · 이미지 카드

- 날짜: 2026-09-30
- 분류: 디자인
- 상태: 완료 (merge 대기)
- 브랜치: `fix/design-glass-scope` (`feature/library-cover-images` 위)
- 상세 기능: 공통 (디자인)

## 한 일
- 사용자 피드백 반영 (D-015): 배경 빛 번짐 제거(단색), 유리는 떠 있는 바 · 원형/보조 버튼 · 강조 카드에만.
- 설정 묶음 · 입력칸 · 선택 알약 · 스위치 → 평범한 면.
- `CoverCard`(사진 또는 테마 색 그라데이션, 유리 없음) 추가 → 재생목록 카드 · 플레이어 커버에 사용.
- 팔레트 `onGlow` · `scrim` 추가, `GlassCard` · `CoverCard` 안의 글자는 `onGlow`로 (라이트 테마 대비).

## 확인
- `flutter analyze` 0, `flutter test` 통과, 한국어 스크린샷 확인.
