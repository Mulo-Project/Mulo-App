/// 저장 포맷 (상세 기능: 오디오 추출 저장 #5).
enum AudioFormat { m4a, opus, mp3 }

/// 영상 파일 저장 형식 (영상도 같이 저장할 때 고른다).
/// mp4: H.264 + AAC (어디서나 재생). webm: VP9 + Opus (원본 그대로, 다시 인코딩 없음).
enum VideoFormat {
  mp4('mp4', 'video/mp4'),
  webm('webm', 'video/webm');

  const VideoFormat(this.extension, this.mime);

  final String extension;
  final String mime;
}

/// 영상 화질 선택지 (세로 픽셀 상한). 이 이하에서 가장 좋은 화질을 받는다.
const videoHeights = [360, 480, 720, 1080];
