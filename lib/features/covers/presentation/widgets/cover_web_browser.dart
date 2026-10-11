import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/cover_cubit.dart';
import 'cover_editor_page.dart';

/// 앱 안 브라우저(WebView)로 이미지를 고를 수 있는 플랫폼인가. 지금은 Android만
/// (데스크톱은 검색어 · 주소 입력 화면을 쓴다).
bool get coverWebBrowserSupported => Platform.isAndroid;

/// 이름으로 이미지 검색 주소.
Uri coverSearchUri(String query) =>
    Uri.https('www.bing.com', '/images/search', {'q': query});

/// 이미지를 누르면 원본 주소를 앱으로 보내는 스크립트. 검색 결과 링크에 실린 원본 주소를 우선하고,
/// 없으면 눌린 큰 이미지(80px 이상)의 주소를 쓴다. 눌림은 웹 쪽 동작으로 새지 않게 막는다.
const _pickScript = '''
(function () {
  if (window.__muloPick) return;
  window.__muloPick = true;
  document.addEventListener('click', function (e) {
    var el = e.target, url = null;
    var a = el.closest ? el.closest('a[m]') : null;
    if (a) {
      try { url = JSON.parse(a.getAttribute('m')).murl; } catch (_) {}
    }
    if (!url) {
      var img = el.closest ? el.closest('img') : null;
      if (img && img.naturalWidth >= 80) {
        var s = img.currentSrc || img.src;
        if (/^https?:/.test(s)) url = s;
      }
    }
    if (url) {
      e.preventDefault();
      e.stopPropagation();
      MuloPick.postMessage(url);
    }
  }, true);
})();
''';

/// 웹 이미지 고르기(브라우저): 이름으로 검색한 이미지 결과에서 이미지를 누르면 곧바로
/// 확대 · 위치 편집 화면으로 간다. 편집 화면에서 뒤로 가면 이 브라우저가 그대로 남고,
/// "적용"하면 맞춘 [CoverArt]를 돌려주며 닫힌다. 브라우저를 닫으면 null.
class CoverWebBrowser extends StatefulWidget {
  const CoverWebBrowser({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<CoverWebBrowser> createState() => _CoverWebBrowserState();
}

class _CoverWebBrowserState extends State<CoverWebBrowser> {
  late final _input = TextEditingController(text: widget.initialQuery.trim());
  late final WebViewController _web;
  bool _loading = true;
  bool _canGoBack = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MuloPick',
        onMessageReceived: (m) => _pick(m.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) async {
            await _web.runJavaScript(_pickScript);
            final back = await _web.canGoBack();
            if (mounted) {
              setState(() {
                _loading = false;
                _canGoBack = back;
              });
            }
          },
        ),
      );
    final q = _input.text.trim();
    if (q.isNotEmpty) _web.loadRequest(coverSearchUri(q));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _search(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    _web.loadRequest(coverSearchUri(q));
  }

  Future<void> _pick(String url) async {
    if (_editing || !mounted) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return;
    _editing = true;
    final art = await showCoverEditor(context, CoverArt.web(url));
    _editing = false;
    // 뒤로 가면(null) 브라우저를 그대로 둔다. 적용했으면 맞춘 이미지를 돌려주며 닫는다.
    if (art != null && mounted) Navigator.of(context).pop(art);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return PopScope(
      // 웹 기록이 있으면 뒤로 가기는 웹의 이전 페이지로, 없으면 브라우저를 닫는다.
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _web.goBack();
      },
      child: Scaffold(
        backgroundColor: p.background,
        body: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.coverSourceWeb,
                leading: CircleIconButton(
                  icon: AppIcons.close,
                  tooltip: l10n.actionBack,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Padding(
                padding: AppSpacing.screen.copyWith(top: AppSpacing.xs),
                child: AppSearchField(
                  hint: l10n.coverWebHint,
                  clearTooltip: l10n.actionClear,
                  controller: _input,
                  onSubmitted: _search,
                ),
              ),
              Padding(
                padding: AppSpacing.screen.copyWith(
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.coverWebBrowserHelp,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: p.onSurfaceMuted),
                  ),
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(child: WebViewWidget(controller: _web)),
            ],
          ),
        ),
      ),
    );
  }
}
