import 'dart:io' show Platform;

/// 미리 듣기에 쓸 오디오 형식을 OS별로 정한다 (한 곳에서만).
///
/// 지금은 Android만 개발한다. Android 플레이어(ExoPlayer)는 webm/opus를 기본으로 풀고,
/// DASH m4a(`ftypdash`)는 못 여는 일이 있었다 (D-062). Apple(iOS · macOS)은 반대로 webm/opus를
/// 못 풀어 m4a(AAC)가 필요하므로, iOS를 만들 때 이 정책의 `apple` 분기를 확인한다.
enum AudioFormat { webm, m4a }

/// 이 기기에서 먼저 고를 형식.
AudioFormat preferredAudioFormat() =>
    (Platform.isIOS || Platform.isMacOS) ? AudioFormat.m4a : AudioFormat.webm;

/// yt-dlp `-f` 값: 먼저 고를 형식, 없으면 아무 오디오.
String ytDlpAudioSelector([AudioFormat? format]) =>
    switch (format ?? preferredAudioFormat()) {
      AudioFormat.webm => 'bestaudio[ext=webm]/bestaudio/best',
      AudioFormat.m4a => 'bestaudio[ext=m4a]/bestaudio/best',
    };
