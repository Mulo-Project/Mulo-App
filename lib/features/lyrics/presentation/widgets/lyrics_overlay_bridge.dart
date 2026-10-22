import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../notifications/presentation/bloc/notification_settings_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/lyrics_cubit.dart';
import '../bloc/lyrics_overlay_cubit.dart';
import '../bloc/lyrics_settings_cubit.dart';

/// 설정이 켜져 있으면 지금 곡의 싱크 가사를 떠 있는 가사 창에 올린다 (앱 셸 한 곳에서 감싼다).
/// 곡 정보 숨기기가 켜져 있으면 올리지 않는다. 창의 닫기(✕)를 누르면 설정을 끈다.
class LyricsOverlayBridge extends StatefulWidget {
  const LyricsOverlayBridge({super.key, required this.child});

  final Widget child;

  @override
  State<LyricsOverlayBridge> createState() => _LyricsOverlayBridgeState();
}

class _LyricsOverlayBridgeState extends State<LyricsOverlayBridge> {
  StreamSubscription<void>? _closed;

  @override
  void initState() {
    super.initState();
    final settings = context.read<LyricsSettingsCubit>();
    _closed = context.read<LyricsOverlayCubit>().closed.listen(
      (_) => settings.setOverlay(false),
    );
  }

  @override
  void dispose() {
    _closed?.cancel();
    super.dispose();
  }

  void _sync(BuildContext context) {
    final enabled = context.read<LyricsSettingsCubit>().state.overlay;
    final hide = context
        .read<NotificationSettingsCubit>()
        .state
        .settings
        .hideSongInfo;
    final track = context.read<NowPlayingCubit>().state.track;
    final overlay = context.read<LyricsOverlayCubit>();
    if (!enabled || hide || track == null) {
      overlay.sync(enabled: false, trackId: null, lyrics: null);
      return;
    }
    final lyricsCubit = context.read<LyricsCubit>();
    final lyrics = lyricsCubit.state;
    if (lyrics.trackId != track.id) {
      lyricsCubit.show(track);
      return;
    }
    if (lyrics.loading) return;
    final l10n = context.l10n;
    overlay.sync(
      enabled: true,
      trackId: track.id,
      lyrics: lyrics.lyrics,
      hideLabel: l10n.lyricsOverlayHideTrack,
      offLabel: l10n.lyricsOverlayTurnOff,
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<LyricsSettingsCubit, LyricsSettings>(
        listenWhen: (a, b) => a.overlay != b.overlay,
        listener: (context, _) => _sync(context),
      ),
      BlocListener<NowPlayingCubit, NowPlayingState>(
        listenWhen: (a, b) => a.track?.id != b.track?.id,
        listener: (context, _) => _sync(context),
      ),
      BlocListener<LyricsCubit, LyricsState>(
        listener: (context, _) => _sync(context),
      ),
      BlocListener<NotificationSettingsCubit, NotificationSettingsState>(
        listenWhen: (a, b) =>
            a.settings.hideSongInfo != b.settings.hideSongInfo ||
            a.loaded != b.loaded,
        listener: (context, _) => _sync(context),
      ),
    ],
    child: widget.child,
  );
}
