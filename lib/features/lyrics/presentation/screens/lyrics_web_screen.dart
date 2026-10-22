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

/// 앱 안 웹 화면에서 가사를 검색하고, 사용자가 끌어서 "담기"한 글 모음을 돌려준다.
/// 취소하거나 모은 글이 없으면 null.
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
  final _scratch = TextEditingController();
  bool _loading = true;
  bool _scratchOpen = false;
  double _scratchHeight = 140;
  static const _scratchMin = 80.0;

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

  /// 웹에서 고른 글을 모음 맨 아래에 새 줄로 붙인다.
  Future<void> _add() async {
    final raw = await _controller.runJavaScriptReturningResult(
      'window.getSelection().toString()',
    );
    final text = _decode(raw).trim();
    if (!mounted) return;
    if (text.isEmpty) {
      _snack(context.l10n.lyricsWebNothingSelected);
      return;
    }
    final current = _scratch.text;
    _scratch.text = current.trim().isEmpty
        ? text
        : '${current.trimRight()}\n$text';
    setState(() => _scratchOpen = true);
  }

  void _import() {
    final text = _scratch.text.trim();
    if (text.isEmpty) {
      _snack(context.l10n.lyricsWebScratchEmpty);
      return;
    }
    Navigator.of(context).pop(text);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _scratch.dispose();
    super.dispose();
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
    // 뒤로가기는 웹 기록을 먼저 되돌리고, 더 갈 곳이 없을 때만 화면을 닫는다.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.palette.background,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.lyricsWebTitle,
                leading: CircleIconButton(
                  icon: AppIcons.close,
                  tooltip: l10n.actionCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_loading) const IgnorePointer(child: LoadingState()),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _scratchOpen = !_scratchOpen),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.lyricsWebScratchTitle,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Icon(
                            _scratchOpen
                                ? AppIcons.chevronDown
                                : AppIcons.chevronUp,
                            color: context.palette.onSurfaceMuted,
                          ),
                        ],
                      ),
                    ),
                    if (_scratchOpen) ...[
                      const SizedBox(height: AppSpacing.xs),
                      // 위쪽 손잡이를 끌어 모은 글 영역 높이를 조절한다.
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (d) => setState(
                          () => _scratchHeight = (_scratchHeight - d.delta.dy)
                              .clamp(
                                _scratchMin,
                                MediaQuery.sizeOf(context).height * .6,
                              ),
                        ),
                        child: SizedBox(
                          height: 20,
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: context.palette.onSurfaceMuted,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: _scratchHeight,
                        child: AppTextField(
                          label: l10n.lyricsWebScratchTitle,
                          controller: _scratch,
                          hint: l10n.lyricsWebScratchHint,
                          expands: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      PillButton(
                        label: l10n.lyricsWebClear,
                        icon: AppIcons.delete,
                        variant: PillVariant.tonal,
                        compact: true,
                        onPressed: () => _scratch.clear(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.lyricsWebHint,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.palette.onSurfaceMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: l10n.lyricsWebAdd,
                            icon: AppIcons.playlistAdd,
                            variant: PillVariant.tonal,
                            onPressed: _add,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: PillButton(
                            label: l10n.lyricsWebImport,
                            icon: AppIcons.download,
                            onPressed: _import,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
