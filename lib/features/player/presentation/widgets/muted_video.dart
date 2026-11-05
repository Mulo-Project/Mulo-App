import 'dart:async';
import 'dart:io';

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
    this.maxDrift = const Duration(milliseconds: 600),
  });

  /// `content://…` · `file` 경로 · `http(s)://…` 주소.
  final String source;
  final Map<String, String> headers;
  final Duration position;
  final bool playing;
  final Duration maxDrift;

  @override
  State<MutedVideo> createState() => _MutedVideoState();
}

class _MutedVideoState extends State<MutedVideo> {
  VideoPlayerController? _controller;
  var _ready = false;

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
    const options = VideoPlayerOptions(mixWithOthers: true);
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
      await controller.seekTo(widget.position);
      if (widget.playing) await controller.play();
      if (mounted && _controller == controller) setState(() => _ready = true);
    } catch (_) {
      // 영상을 못 열면 화면만 비운다 (소리 재생에는 영향이 없다).
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
    final drift = (value.position - widget.position).abs();
    if (drift > widget.maxDrift) unawaited(c.seekTo(widget.position));
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
