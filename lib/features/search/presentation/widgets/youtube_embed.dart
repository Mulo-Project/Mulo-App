import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/design/design.dart';

/// 앱 안에서 유튜브 영상을 재생할 수 있는 플랫폼인가. 지금은 Android만 (WebView 임베드).
/// 데스크톱은 WebView가 없어서 유튜브로 열기만 된다.
bool get inAppVideoSupported => Platform.isAndroid;

/// 임베드 플레이어가 영상을 못 틀 때 (임베드 금지 · 없는 영상 · 연결 실패).
typedef EmbedFailed = void Function(String reason);

/// 유튜브 IFrame API 페이지. 오류와 준비 완료를 `Player` 채널로 알린다.
/// 영상 id는 유튜브 id 형식(영문 · 숫자 · `-` · `_`)만 받는다.
String youtubeEmbedHtml(String videoId) {
  assert(isYoutubeVideoId(videoId));
  return '''
<!DOCTYPE html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; height: 100%; background: #000; overflow: hidden; }
  iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
</style>
</head><body>
<div id="p"></div>
<script src="https://www.youtube.com/iframe_api"></script>
<script>
  function onYouTubeIframeAPIReady() {
    new YT.Player('p', {
      width: '100%', height: '100%', videoId: '$videoId',
      playerVars: { autoplay: 1, playsinline: 1, rel: 0, modestbranding: 1 },
      events: {
        onReady: function () { Player.postMessage('ready'); },
        onError: function (e) { Player.postMessage('error:' + e.data); }
      }
    });
  }
</script>
</body></html>''';
}

/// 유튜브 영상 id로 쓸 수 있는 글자만 들어 있는가 (HTML에 그대로 넣기 때문에 검사한다).
bool isYoutubeVideoId(String id) =>
    RegExp(r'^[A-Za-z0-9_-]{6,20}$').hasMatch(id);

/// 플레이어 페이지가 보낸 메시지를 뜻으로 옮긴다: 오류면 까닭(오류 번호), 아니면 null.
/// 101 · 150 · 153은 영상 주인이 임베드를 막은 경우다.
String? embedErrorOf(String message) =>
    message.startsWith('error:') ? message.substring(6) : null;

/// 첫 준비 신호를 기다리는 시간. 넘기면 연결이 안 되는 것으로 보고 실패로 알린다.
const embedReadyTimeout = Duration(seconds: 15);

/// 앱 안 유튜브 플레이어 (16:9). 재생할 수 없으면 [onFailed]로 알려서
/// 화면이 "유튜브에서 열기"로 돌아서게 한다. [inAppVideoSupported]일 때만 쓴다.
class YoutubeEmbedPlayer extends StatefulWidget {
  const YoutubeEmbedPlayer({
    super.key,
    required this.videoId,
    required this.onFailed,
  });

  final String videoId;
  final EmbedFailed onFailed;

  @override
  State<YoutubeEmbedPlayer> createState() => _YoutubeEmbedPlayerState();
}

class _YoutubeEmbedPlayerState extends State<YoutubeEmbedPlayer> {
  late final WebViewController _controller;
  Timer? _readyTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Player', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          // 영상 안의 링크로 다른 곳에 가지 않게, 유튜브 임베드 밖은 막는다.
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host ?? '';
            final allowed =
                host.isEmpty ||
                host == 'youtube.com' ||
                host.endsWith('.youtube.com') ||
                host.endsWith('.youtube-nocookie.com') ||
                host.endsWith('.google.com') ||
                host.endsWith('.googlevideo.com');
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? false) _fail('load:${e.errorCode}');
          },
        ),
      );
    // 앱의 재생 버튼을 눌렀을 때 바로 재생되도록, 웹 쪽 손동작 요구를 푼다.
    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      unawaited(platform.setMediaPlaybackRequiresUserGesture(false));
    }
    // baseUrl이 유튜브여야 임베드가 "참조 주소 없음"(오류 153)으로 거절되지 않는다.
    unawaited(
      _controller.loadHtmlString(
        youtubeEmbedHtml(widget.videoId),
        baseUrl: 'https://www.youtube.com',
      ),
    );
    _readyTimer = Timer(embedReadyTimeout, () => _fail('timeout'));
  }

  void _onMessage(JavaScriptMessage m) {
    if (m.message == 'ready') {
      _readyTimer?.cancel();
      return;
    }
    final error = embedErrorOf(m.message);
    if (error != null) _fail(error);
  }

  void _fail(String reason) {
    // 임베드 금지(101 · 150 · 153)는 준비 신호 뒤에 오기도 해서 준비 여부와 상관없이 받는다.
    if (!mounted) return;
    _readyTimer?.cancel();
    widget.onFailed(reason);
  }

  @override
  void dispose() {
    _readyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      // 페이지가 뜨기 전에는 이 색이 비친다.
      child: ColoredBox(
        color: context.palette.surfaceHigh,
        child: WebViewWidget(controller: _controller),
      ),
    ),
  );
}
