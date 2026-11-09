import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import 'native_video.dart';

/// 영상을 전체 화면(가로, 시스템 막대 숨김)으로 연다. 뒤로 가기 · 닫기 버튼으로 돌아온다.
/// 영상은 같은 텍스처를 그대로 쓰므로 소리 · 위치가 끊기지 않는다.
/// [controls]로 영상 위에 얹을 컨트롤을 넘긴다 (없으면 닫기 버튼만).
Future<void> showFullscreenVideo(
  BuildContext context, {
  WidgetBuilder? controls,
}) async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  if (!context.mounted) return;
  try {
    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (_, _, _) => _FullscreenVideoPage(controls: controls),
      ),
    );
  } finally {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const []);
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({this.controls});

  final WidgetBuilder? controls;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  var _closeShown = false;
  Timer? _timer;

  // 컨트롤이 없는 전체 화면은 화면을 누를 때만 닫기 버튼이 잠깐 뜬다.
  void _toggleClose() {
    _timer?.cancel();
    setState(() => _closeShown = !_closeShown);
    if (_closeShown) {
      _timer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _closeShown = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controls = widget.controls;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NativeVideo(fit: BoxFit.contain),
          if (controls != null)
            controls(context)
          else ...[
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleClose,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: IgnorePointer(
                    ignoring: !_closeShown,
                    child: AnimatedOpacity(
                      opacity: _closeShown ? 1 : 0,
                      duration: AppMotion.fast,
                      child: CircleIconButton(
                        icon: AppIcons.close,
                        tooltip: context.l10n.videoFullscreenExit,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 영상 오른쪽 아래의 작은 전체 화면 버튼.
class FullscreenVideoButton extends StatelessWidget {
  const FullscreenVideoButton({super.key, this.controls});

  /// 전체 화면에서 영상 위에 얹을 컨트롤 (없으면 닫기 버튼만).
  final WidgetBuilder? controls;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      key: const ValueKey('video-fullscreen'),
      icon: AppIcons.fullscreen,
      tooltip: context.l10n.videoFullscreen,
      size: AppSizes.rowButton,
      onPressed: () => showFullscreenVideo(context, controls: controls),
    );
  }
}
