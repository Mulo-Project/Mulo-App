import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';

/// 웹 검색(WebView)을 지원하는 플랫폼인가. 지금은 Android만 (데스크톱은 직접 입력 · 파일).
bool get lyricsWebSupported => Platform.isAndroid;

/// "제목 아티스트 가사" 검색 주소.
Uri lyricsSearchUri(Track track) {
  final artist = track.artist.trim();
  final query = [
    track.title.trim(),
    if (artist.isNotEmpty) artist,
    '가사',
  ].join(' ');
  return Uri.https('www.google.com', '/search', {'q': query});
}

/// 앱 안 웹 화면에서 가사를 검색하고, 사용자가 끌어서 고른 글을 돌려준다.
/// 취소하거나 고른 글이 없으면 null.
Future<String?> showLyricsWeb(BuildContext context, Track track) {
  return Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute(builder: (_) => LyricsWebScreen(track: track)),
  );
}

class LyricsWebScreen extends StatefulWidget {
  const LyricsWebScreen({super.key, required this.track});

  final Track track;

  @override
  State<LyricsWebScreen> createState() => _LyricsWebScreenState();
}

class _LyricsWebScreenState extends State<LyricsWebScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(lyricsSearchUri(widget.track));
  }

  Future<void> _import() async {
    final raw = await _controller.runJavaScriptReturningResult(
      'window.getSelection().toString()',
    );
    final text = _decode(raw);
    if (!mounted) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.lyricsWebNothingSelected)),
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  /// Android는 JS 문자열 결과를 JSON 문자열(따옴표 · 이스케이프 포함)로 준다.
  static String _decode(Object raw) {
    final s = raw.toString();
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s
          .substring(1, s.length - 1)
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', r'\')
          .replaceAllMapped(
            RegExp(r'\\u([0-9a-fA-F]{4})'),
            (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
          );
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: l10n.lyricsWebTitle,
              leading: CircleIconButton(
                icon: Icons.close_rounded,
                tooltip: l10n.actionCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: WebViewWidget(controller: _controller)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.lyricsWebHint,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: context.palette.onSurfaceMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  PillButton(
                    label: l10n.lyricsWebImport,
                    icon: Icons.download_rounded,
                    onPressed: _import,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
