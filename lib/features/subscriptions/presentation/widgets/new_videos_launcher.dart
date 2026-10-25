import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/new_video_download_request.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/new_videos_cubit.dart';
import '../bloc/subscriptions_cubit.dart';

/// 앱을 켤 때 구독 채널의 새 영상을 확인하고, 있으면 "보기"가 달린 안내 줄을 위에 한 번 띄운다
/// (스낵바 대신 화면 위에서 내려오는 줄. 8초 뒤 · 닫기 · 보기를 누르면 사라진다).
/// 새 영상 알림(Android 백그라운드 확인)을 눌러 앱이 열렸을 때도 새 영상 화면으로 안내한다.
class NewVideosLauncher extends StatefulWidget {
  const NewVideosLauncher({
    super.key,
    required this.child,
    required this.onOpen,
  });

  final Widget child;

  /// 새 영상 화면을 연다.
  final VoidCallback onOpen;

  @override
  State<NewVideosLauncher> createState() => _NewVideosLauncherState();
}

class _NewVideosLauncherState extends State<NewVideosLauncher> {
  StreamSubscription<void>? _opens;
  StreamSubscription<NewVideoDownloadRequest>? _downloads;
  var _announced = false;

  /// 위 안내 줄에 보이는 새 영상 수 (없으면 줄이 없다).
  int? _bannerCount;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _opens = sl<WatchNewVideosOpens>()(const NoParams()).listen((_) {
      widget.onOpen();
    });
    _downloads = sl<WatchNewVideoDownloads>()(const NoParams())
        .listen(_download);
    unawaited(_boot());
  }

  Future<void> _boot() async {
    final subs = sl<SubscriptionsCubit>();
    await subs.load();
    // 알림의 "바로 받기"로 앱이 새로 켜졌다면 그 영상을 받기 시작한다.
    for (final r in await sl<TakeNewVideoDownloads>()(const NoParams())) {
      await _download(r);
    }
    // 알림 본문을 눌러 앱이 새로 켜졌다면 새 영상 목록으로 바로 간다.
    final fromNotification = await sl<TakeNewVideosOpen>()(const NoParams());
    if (!mounted) return;
    if (fromNotification) {
      widget.onOpen();
      return;
    }
    if (subs.state.settings.checkOnLaunch && subs.state.hasEnabled) {
      unawaited(sl<NewVideosCubit>().check());
    }
  }

  /// 알림의 "바로 받기": 받기 대기열에 넣고 알린다.
  Future<void> _download(NewVideoDownloadRequest request) async {
    final queued = await sl<NewVideosCubit>().handleDownloadRequest(request);
    if (!queued || !mounted || request.background) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.newVideosStarted(1))));
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _opens?.cancel();
    _downloads?.cancel();
    super.dispose();
  }

  void _announce(BuildContext context, NewVideosState state) {
    // 샘플(모양 확인용)은 안내하지 않는다.
    if (_announced ||
        state.sample ||
        state.status != NewVideosStatus.done ||
        state.resolving ||
        state.unseenCount == 0) {
      return;
    }
    _announced = true;
    // 이미 안내했거나 본 영상은 목록에 남아 있어도 다시 알리지 않는다.
    setState(() => _bannerCount = state.unseenCount);
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 8), _hideBanner);
  }

  void _hideBanner() {
    _bannerTimer?.cancel();
    if (mounted) setState(() => _bannerCount = null);
  }

  void _openFromBanner() {
    // 안내를 한 번 했으니 보고 닫지 않아도 다음 실행에서는 다시 알리지 않는다.
    unawaited(sl<NewVideosCubit>().acknowledge());
    _hideBanner();
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<NewVideosCubit, NewVideosState>(
        bloc: sl<NewVideosCubit>(),
        listener: _announce,
        child: Stack(
          children: [
            widget.child,
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: NewVideosBanner(
                count: _bannerCount,
                onOpen: _openFromBanner,
                onClose: _hideBanner,
              ),
            ),
          ],
        ),
      );
}

/// 화면 위에서 내려오는 새 영상 안내 줄: 아이콘 · "구독 채널에 새 영상이 N개 있어요" · 보기 · 닫기.
/// 흐림 없는 단색 면이라 스크롤하는 화면 위에 떠 있어도 가볍다. 없으면 아무것도 그리지 않는다.
class NewVideosBanner extends StatelessWidget {
  const NewVideosBanner({
    super.key,
    required this.count,
    required this.onOpen,
    required this.onClose,
  });

  final int? count;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    // 없으면 아무것도 두지 않는다 (다른 화면의 아이콘 · 글자와 겹쳐 찾히지 않게). 나타날 때만 위에서 내려온다.
    if (count == null) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.2, end: 0),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (context, dy, child) => Opacity(
        opacity: (1 + dy / 1.2).clamp(0.0, 1.0),
        child: FractionalTranslation(translation: Offset(0, dy), child: child),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          top + AppSpacing.xs,
          AppSpacing.md,
          0,
        ),
        child: Material(
          color: p.surfaceHigh,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            side: BorderSide(color: p.accent.withValues(alpha: .5)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              top: AppSpacing.xxs,
              bottom: AppSpacing.xxs,
              right: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                Icon(AppIcons.download, size: AppSizes.iconMd, color: p.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.newVideosAnnounce(count!),
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PlainButton(
                  key: const ValueKey('new-videos-banner-open'),
                  label: l10n.newVideosOpen,
                  accent: true,
                  onPressed: onOpen,
                ),
                // 이 줄은 화면 틀(Navigator) 위에 있어 Overlay가 없으므로 툴팁은 쓰지 않는다.
                Semantics(
                  button: true,
                  label: l10n.actionClear,
                  child: PlainButton(
                    key: const ValueKey('new-videos-banner-close'),
                    icon: AppIcons.close,
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
