/// 미리 듣기 영상 화질. 영상 형식 중 [maxHeight] 이하에서 가장 큰 것을 쓴다.
enum VideoQuality {
  low(144),
  standard(360),
  medium(480),
  high(720),
  full(1080);

  const VideoQuality(this.maxHeight);

  final int maxHeight;
}
