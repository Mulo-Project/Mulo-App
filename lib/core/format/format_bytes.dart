const _mb = 1024 * 1024;

/// 바이트를 "120 MB" · "1.5 GB"처럼 짧게.
String formatBytes(int bytes) {
  if (bytes >= 1024 * _mb) {
    final gb = bytes / (1024 * _mb);
    return '${gb == gb.roundToDouble() ? gb.round() : gb.toStringAsFixed(1)} GB';
  }
  return '${(bytes / _mb).round()} MB';
}
