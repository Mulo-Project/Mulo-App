/// 전체 화면 플레이어의 모양. 설정의 "플레이어 테마"에서 고른다 (D-039).
enum PlayerStyle {
  /// 음반: 둥근 디스크 커버와 원형 진행 호.
  vinyl,

  /// 네모: 큰 정사각 커버와 얇은 진행 막대.
  square,

  /// 꽉 찬 이미지: 커버가 위쪽을 채우고 배경으로 스며든다.
  fullBleed,

  /// 호: 흐린 커버 배경과 빛나는 재생 버튼을 두른 곡선 진행 호.
  arc;

  static const PlayerStyle initial = square;
}
