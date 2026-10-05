# 제목 마키 · 부드러운 아이콘

- 날짜: 2026-10-06
- 분류: 디자인 · 앱
- 상태: 완료 (merge 대기)
- 브랜치 · 커밋: `feature/player-marquee-rounded-icons`
- 상세 기능: 공통 작업 (디자인 시스템)

## 한 일
- `MarqueeText`: 제목이 칸보다 길 때만 잠깐 멈췄다가 옆으로 흐른다(끝은 흐리게). 들어가면 그냥 글자. 플레이어 · 미니 플레이어 · 재생 중인 곡 줄에 적용. 나머지 목록 줄은 전부 움직이면 산만해서 `…` 그대로 둔다.
- 아이콘: 화면의 `Icons.xxx`(Material) 전부를 `AppIcons.xxx` 한 곳의 매핑으로 바꿨다. 글리프는 Phosphor(둥글고 부드러운 선)이고, 재생 · 일시정지 · 이전 · 다음 · 좋아요 · 선택된 탭처럼 면이 필요한 곳만 Fill. 나중에 세트를 바꾸거나 직접 그린 아이콘으로 교체할 때 `AppIcons`와 폰트만 고친다.
- Phosphor를 고른 이유: Material Rounded보다 선이 가늘고 모서리가 둥글어 검정 · 보라 · 라임의 모던한 톤에 맞고, 같은 모양의 Fill 짝이 있어 활성 상태 표현이 쉽다.

- 재생 화면: 제목과 붙은 버튼(가사 · 대기열 · 좋아요)을 한 줄에서 제목 줄 세로 가운데로 맞추고, 아티스트는 아래 줄에 혼자 둔다 (모든 플레이어 모양이 쓰는 `PlayerControls` 한 곳 수정, `PlayerTitle`을 `PlayerTitleText` · `PlayerSubtitleText`로 나눔).

## 바꾼 설정
- `pubspec.yaml`: 폰트 `PhosphorRegular` · `PhosphorFill` 추가 (`assets/fonts/phosphor/`, MIT 라이선스 파일 포함). 패키지는 추가하지 않았다. `phosphor_flutter` 2.1.0은 현재 Flutter에서 `IconData`가 final이라 컴파일되지 않아, 폰트 파일만 가져오고 코드포인트를 `AppIcons`에 직접 적었다.
- `windows/flutter/generated_plugin*` 변경분은 이 작업과 무관해 포함하지 않았다.

## 확인
- `flutter analyze` 0, `flutter test` 통과 (`MarqueeText` 테스트 추가).
- 실제 화면에서 아이콘 굵기 · 크기가 어색한 곳이 있는지는 눈으로 봐야 한다.

## 남은 일 · 질문
- 직접 그린 아이콘으로 바꾸려면 SVG를 아이콘 폰트로 묶어 `AppIcons`만 가리키게 하면 된다.
