import 'package:url_launcher/url_launcher.dart';

import '../../domain/repositories/link_opener.dart';

/// 유튜브 앱이 있으면 그 앱으로, 없으면 브라우저로 연다.
class UrlLauncherLinkOpener implements LinkOpener {
  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
