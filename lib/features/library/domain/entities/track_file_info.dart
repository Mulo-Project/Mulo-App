/// 음악 파일 자체의 정보. 알 수 없는 값은 null.
class TrackFileInfo {
  const TrackFileInfo({
    this.sizeBytes,
    this.mime,
    this.bitrate,
    this.sampleRate,
  });

  /// 파일 크기(byte).
  final int? sizeBytes;

  /// `audio/mpeg` 같은 형식.
  final String? mime;

  /// 비트레이트(bps).
  final int? bitrate;

  /// 샘플레이트(Hz).
  final int? sampleRate;

  bool get isEmpty =>
      sizeBytes == null && mime == null && bitrate == null && sampleRate == null;
}
