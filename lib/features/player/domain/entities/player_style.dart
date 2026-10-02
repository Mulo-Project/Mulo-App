/// 전체 화면 플레이어의 모양. 재생 화면의 더 보기 메뉴("플레이어 테마")에서 고른다 (D-039).
enum PlayerStyle {
  /// 네모: 큰 정사각 커버와 얇은 진행 막대.
  square,

  /// 꽉 찬 이미지: 커버가 위쪽을 채우고 배경으로 스며든다.
  fullBleed,

  /// 호: 흐린 커버 배경과 빛나는 재생 버튼을 두른 곡선 진행 호.
  arc,

  /// 커스텀: 소프트(뉴모피즘) 화면. 키 큰 둥근 틀 안의 커버와 틀을 따라 도는 진행 막대.
  custom;

  static const PlayerStyle initial = square;
}
