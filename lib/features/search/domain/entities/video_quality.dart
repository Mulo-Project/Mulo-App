/// 미리 듣기 영상 화질. 소리가 섞인 형식 중 [maxHeight] 이하에서 가장 큰 것을 쓴다
/// (유튜브의 소리 섞인 형식은 360p와 720p가 대표라, 이 둘만 고른다).
enum VideoQuality {
  standard(360),
  high(720);

  const VideoQuality(this.maxHeight);

  final int maxHeight;
}
