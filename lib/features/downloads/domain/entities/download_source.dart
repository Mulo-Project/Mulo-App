import 'package:equatable/equatable.dart';

/// 곡의 원본 주소를 같은 곡끼리 같은 문자열로 만든다 (이미 받은 곡 찾기용).
/// 유튜브 주소는 영상 id만 남기고(`watch?v=` · `youtu.be/` · `shorts/` · `embed/` · `live/`),
/// 재생목록 · 시간 같은 덧붙임은 버린다. 그 밖의 주소는 앞뒤 공백만 지운다.
String downloadSourceKey(String url) {
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || uri.host.isEmpty) return trimmed;
  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  String? id;
  if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
    id = segments.firstOrNull;
  } else if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
    if (segments.length >= 2 &&
        const {'shorts', 'embed', 'live', 'v'}.contains(segments.first)) {
      id = segments[1];
    } else {
      id = uri.queryParameters['v'];
    }
  }
  return id == null || id.isEmpty ? trimmed : 'youtube:$id';
}

/// 이미 받았거나 받는 중인 곡 (같은 원본 주소).
class ExistingDownload extends Equatable {
  const ExistingDownload({this.trackId, this.inQueue = false});

  static const none = ExistingDownload();

  /// 이미 받아 보관함에 있는 곡의 id. 없으면 null.
  final String? trackId;

  /// 지금 대기열에 있다 (받는 중 · 대기 · 일시정지).
  final bool inQueue;

  bool get exists => trackId != null || inQueue;

  @override
  List<Object?> get props => [trackId, inQueue];
}
