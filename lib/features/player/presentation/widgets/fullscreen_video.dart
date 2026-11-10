import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/presentation/widgets/preview_video_controls.dart';
import 'native_video.dart';

/// 영상을 전체 화면(시스템 막대 숨김)으로 연다. 기기를 돌리면 가로 · 세로로 따라 돈다. 뒤로 가기 · 닫기 버튼으로 돌아온다.
/// 영상은 같은 텍스처를 그대로 쓰므로 소리 · 위치가 끊기지 않는다.
/// [controls]로 영상 위에 얹을 컨트롤을 넘긴다 (없으면 닫기 버튼만).
Future<void> showFullscreenVideo(
  BuildContext context, {
  WidgetBuilder? controls,
}) async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
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

  // 컨트롤이 없는 전체 화면은 화면을 누를 때만 축소 버튼이 잠깐 뜬다.
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
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: IgnorePointer(
                    ignoring: !_closeShown,
                    child: AnimatedOpacity(
                      opacity: _closeShown ? 1 : 0,
                      duration: AppMotion.fast,
                      child: const FullscreenVideoButton(exit: true),
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

/// 영상 오른쪽 아래의 작은 전체 화면 버튼. [exit]이면 전체 화면 안에서 쓰는 축소(닫기) 버튼이다.
class FullscreenVideoButton extends StatelessWidget {
  const FullscreenVideoButton({super.key, this.controls, this.exit = false});

  final bool exit;

  /// 전체 화면에서 영상 위에 얹을 컨트롤 (없으면 닫기 버튼만).
  final WidgetBuilder? controls;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      key: ValueKey(exit ? 'video-fullscreen-exit' : 'video-fullscreen'),
      icon: exit ? AppIcons.fullscreenExit : AppIcons.fullscreen,
      tooltip: exit
          ? context.l10n.videoFullscreenExit
          : context.l10n.videoFullscreen,
      size: AppSizes.rowButton,
      overlay: true,
      onPressed: exit
          ? () => Navigator.of(context).pop()
          : () => showFullscreenVideo(context, controls: controls),
    );
  }
}

/// 영상 화면([NativeVideo]) + 오른쪽 아래 전체 화면 버튼. 메인 플레이어와 임시 저장 곡의 영상 자리가 함께 쓴다.
class NativeVideoWithFullscreen extends StatelessWidget {
  const NativeVideoWithFullscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const NativeVideo(),
        Positioned(
          right: AppSpacing.xs,
          bottom: AppSpacing.xs,
          // 전체 화면으로 키우면 검색 미리보기와 같은 영상 컨트롤이 영상 위에 뜬다.
          child: FullscreenVideoButton(
            controls: (_) =>
                const PreviewVideoControls(fullscreen: true, main: true),
          ),
        ),
      ],
    );
  }
}

/// 영상 화면([NativeVideo]) 자체를 누르면 전체 화면으로 키운다 (원형 커버처럼 모서리에 버튼을 둘 수 없는 자리).
/// 전체 화면에는 [NativeVideoWithFullscreen]과 같은 영상 컨트롤이 뜬다.
class NativeVideoTapFullscreen extends StatelessWidget {
  const NativeVideoTapFullscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('video-tap-fullscreen'),
      behavior: HitTestBehavior.opaque,
      onTap: () => showFullscreenVideo(
        context,
        controls: (_) =>
            const PreviewVideoControls(fullscreen: true, main: true),
      ),
      child: const NativeVideo(),
    );
  }
}
