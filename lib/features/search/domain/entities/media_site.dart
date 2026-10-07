import 'package:equatable/equatable.dart';

/// 곡이 올라와 있는 사이트 (웹 검색 결과를 "어느 사이트인지" 보여 주려고).
class MediaSite extends Equatable {
  const MediaSite({required this.name, required this.host});

  /// 화면에 보일 이름. 모르는 사이트는 주소의 도메인.
  final String name;
  final String host;

  /// [url]이 가리키는 사이트. 주소를 읽을 수 없으면 이름이 빈 문자열이다.
  factory MediaSite.fromUrl(String url) {
    var host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.startsWith('www.')) host = host.substring(4);
    for (final (suffix, name) in _known) {
      if (host == suffix || host.endsWith('.$suffix')) {
        return MediaSite(name: name, host: host);
      }
    }
    return MediaSite(name: host, host: host);
  }

  bool get isYoutube => name == 'YouTube';

  static const _known = <(String, String)>[
    ('youtube.com', 'YouTube'),
    ('youtu.be', 'YouTube'),
    ('soundcloud.com', 'SoundCloud'),
    ('bandcamp.com', 'Bandcamp'),
    ('vimeo.com', 'Vimeo'),
    ('dailymotion.com', 'Dailymotion'),
    ('mixcloud.com', 'Mixcloud'),
    ('audiomack.com', 'Audiomack'),
    ('bilibili.com', 'bilibili'),
    ('nicovideo.jp', 'niconico'),
  ];

  @override
  List<Object?> get props => [name, host];
}
