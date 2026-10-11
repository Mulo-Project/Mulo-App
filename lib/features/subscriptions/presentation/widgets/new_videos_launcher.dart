import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/new_video_download_request.dart';
import '../../domain/usecases/subscription_usecases.dart';
import '../bloc/new_videos_cubit.dart';
import '../bloc/subscriptions_cubit.dart';

/// 앱을 켤 때 구독 채널의 새 영상을 확인하고, 있으면 "보기"가 달린 안내를 한 번 띄운다.
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
        state.count == 0) {
      return;
    }
    _announced = true;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.newVideosAnnounce(state.count)),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: l10n.newVideosOpen,
          onPressed: widget.onOpen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<NewVideosCubit, NewVideosState>(
        bloc: sl<NewVideosCubit>(),
        listener: _announce,
        child: widget.child,
      );
}
