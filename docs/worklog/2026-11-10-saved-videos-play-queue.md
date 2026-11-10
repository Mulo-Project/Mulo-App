# 저장한 음원 재생 목록

- 저장한 음원 페이지에 재생 · 셔플 · 반복 버튼. 목록 전체를 화면 순서(음원 → 영상)대로 차례로 듣는다.
- 미니 플레이어에 이전/다음 버튼이 목록 재생 중에만 뜬다. 이전: 3초 넘게 들었으면 처음부터, 아니면 앞 곡.
- 구현: `PreviewCubit.playQueue/next/previous/toggleShuffle`, `queueActive/shuffle/loop`. 결정 D-160.
- 확인 필요(PC): `flutter analyze`, `flutter test test/features/search/preview_test.dart`, 기기에서 곡 사이 이어짐 · 영상 전환.
