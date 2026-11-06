import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../bloc/now_playing_cubit.dart';

/// 소리 없는 영상 화면. 소리는 네이티브 플레이어가 내므로 이 화면은 주어진 위치 · 재생 상태를
/// 따라가기만 한다 (오디오 포커스도 가져가지 않는다). 위치가 [maxDrift] 넘게 어긋나면 다시 맞춘다.
/// 앱 화면이 사라지면 영상도 함께 사라지고 소리만 이어진다.
class MutedVideo extends StatefulWidget {
  const MutedVideo({
    super.key,
    required this.source,
    required this.position,
    required this.playing,
    this.headers = const {},
    this.onStarted,
    this.maxDrift = const Duration(milliseconds: 600),
  });

  /// `content://…` · `file` 경로 · `http(s)://…` 주소.
  final String source;
  final Map<String, String> headers;
  final Duration position;
  final bool playing;
  final Duration maxDrift;

  /// 영상이 실제로 움직이기 시작했을 때 (열지 못했거나 [_startLimit]이 지나도) 한 번 알린다.
  /// 소리를 잠시 멈춰 둔 쪽이 이어서 내는 데 쓴다.
  final VoidCallback? onStarted;

  @override
  State<MutedVideo> createState() => _MutedVideoState();
}

class _MutedVideoState extends State<MutedVideo> {
  VideoPlayerController? _controller;
  var _ready = false;

  /// 마지막으로 위치를 맞춘 시각. 버퍼링 중에 계속 되감지 않게 간격을 둔다.
  DateTime _lastSync = DateTime.fromMillisecondsSinceEpoch(0);

  /// 위치를 맞출 때 다시 찾는 데 걸리는 시간만큼 앞서 가서 소리와 맞춘다.
  static const _seekLead = Duration(milliseconds: 300);
  static const _resyncGap = Duration(seconds: 2);
  static const _startLimit = Duration(seconds: 6);

  /// 영상이 실제로 움직이기 시작하면 [MutedVideo.onStarted]를 한 번 부른다.
  void _notifyWhenMoving(VideoPlayerController c) {
    final callback = widget.onStarted;
    if (callback == null) return;
    if (!widget.playing) return callback();
    final start = c.value.position;
    var done = false;
    late final VoidCallback check;
    void fire() {
      if (done) return;
      done = true;
      c.removeListener(check);
      callback();
    }

    check = () {
      final v = c.value;
      if (v.isPlaying &&
          !v.isBuffering &&
          v.position > start + const Duration(milliseconds: 100)) {
        fire();
      }
    };
    c.addListener(check);
    Timer(_startLimit, fire);
  }

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(MutedVideo old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) {
      _open();
      return;
    }
    _follow();
  }

  VideoPlayerController _create() {
    final s = widget.source;
    final options = VideoPlayerOptions(mixWithOthers: true);
    if (s.startsWith('content://')) {
      return VideoPlayerController.contentUri(
        Uri.parse(s),
        videoPlayerOptions: options,
      );
    }
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return VideoPlayerController.networkUrl(
        Uri.parse(s),
        httpHeaders: widget.headers,
        videoPlayerOptions: options,
      );
    }
    return VideoPlayerController.file(File(s), videoPlayerOptions: options);
  }

  Future<void> _open() async {
    final old = _controller;
    final controller = _create();
    setState(() {
      _controller = controller;
      _ready = false;
    });
    unawaited(old?.dispose());
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      await controller.setVolume(0);
      await controller.setLooping(false);
      await controller.seekTo(widget.position + _seekLead);
      if (widget.playing) await controller.play();
      _lastSync = DateTime.now();
      _notifyWhenMoving(controller);
      if (mounted && _controller == controller) setState(() => _ready = true);
      debugPrint('[video] 재생 시작: ${controller.value.size}');
    } catch (e) {
      // 영상을 못 열면 화면만 비운다 (소리 재생에는 영향이 없다). 까닭은 로그로 남긴다.
      debugPrint('[video] 영상을 못 엶 (${widget.source.split('?').first}): $e');
      widget.onStarted?.call();
      if (mounted && _controller == controller) setState(() => _ready = false);
    }
  }

  void _follow() {
    final c = _controller;
    if (c == null || !_ready) return;
    final value = c.value;
    if (widget.playing && !value.isPlaying) {
      unawaited(c.play());
    } else if (!widget.playing && value.isPlaying) {
      unawaited(c.pause());
    }
    // 버퍼링 중에는 되감지 않는다 (되감으면 또 버퍼링해서 영영 못 맞춘다).
    if (value.isBuffering) return;
    final drift = (value.position - widget.position).abs();
    final now = DateTime.now();
    if (drift > widget.maxDrift && now.difference(_lastSync) > _resyncGap) {
      _lastSync = now;
      unawaited(c.seekTo(widget.position + _seekLead));
    }
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !_ready) return const SizedBox.shrink();
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }
}

/// 지금 재생 중인 영상 곡의 화면. 재생 위치 · 상태는 [NowPlayingCubit]에서 읽는다.
class NowPlayingVideo extends StatelessWidget {
  const NowPlayingVideo({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NowPlayingCubit>().state;
    final track = state.track;
    if (track == null) return const SizedBox.shrink();
    return MutedVideo(
      source: track.uri,
      position: state.position,
      playing: state.isPlaying,
    );
  }
}
