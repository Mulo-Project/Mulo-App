import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/design/design.dart';
import '../bloc/now_playing_cubit.dart';

/// 소리 없는 영상 화면. 소리는 네이티브 플레이어가 내므로 이 화면은 주어진 위치 · 재생 상태를
/// 따라가기만 한다 (오디오 포커스도 가져가지 않는다). 어긋나면 재생 속도로 따라잡는다.
/// 앱 화면이 사라지면 영상도 함께 사라지고 소리만 이어진다.
///
/// 같은 [source]의 영상 플레이어는 하나를 같이 쓴다: 미니 플레이어에서 상세 화면으로(또는 반대로)
/// 옮겨도 영상을 다시 열지 않고 이어서 보여 준다 (쓰는 화면이 없어진 뒤 잠시 지나면 정리한다).
class MutedVideo extends StatefulWidget {
  const MutedVideo({
    super.key,
    required this.source,
    required this.position,
    required this.playing,
    this.headers = const {},
  });

  /// `content://…` · `file` 경로 · `http(s)://…` 주소.
  final String source;
  final Map<String, String> headers;
  final Duration position;
  final bool playing;

  @override
  State<MutedVideo> createState() => _MutedVideoState();
}

class _MutedVideoState extends State<MutedVideo> {
  late _VideoSession _session;

  @override
  void initState() {
    super.initState();
    _session = _VideoSession.acquire(
      widget.source,
      widget.headers,
      widget.position,
      widget.playing,
    );
  }

  @override
  void didUpdateWidget(MutedVideo old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source) {
      _session.release();
      _session = _VideoSession.acquire(
        widget.source,
        widget.headers,
        widget.position,
        widget.playing,
      );
      return;
    }
    _session.update(widget.position, widget.playing);
  }

  @override
  void dispose() {
    _session.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final c = _session.controller;
        if (c == null || !_session.ready) return const SizedBox.shrink();
        // 영상이 돌기 시작할 때까지는 숨겨 두었다가 부드럽게 보여 준다 (그동안은 커버가 보인다).
        return AnimatedOpacity(
          opacity: _session.shown ? 1 : 0,
          duration: AppMotion.medium,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
        );
      },
    );
  }
}

/// 영상 주소 하나당 하나인 영상 플레이어와 소리 맞추기. 화면(위젯)들이 나눠 쓴다.
class _VideoSession extends ChangeNotifier {
  _VideoSession(this.source, this.headers);

  static final _sessions = <String, _VideoSession>{};

  /// 쓰는 화면이 모두 없어진 뒤 이만큼 기다렸다가 정리한다 (화면을 옮기는 사이에 다시 쓸 수 있게).
  static const _graceTime = Duration(seconds: 3);

  static _VideoSession acquire(
    String source,
    Map<String, String> headers,
    Duration position,
    bool playing,
  ) {
    var session = _sessions[source];
    if (session == null) {
      session = _VideoSession(source, headers);
      _sessions[source] = session;
      session._setTarget(position, playing);
      unawaited(session._open());
    } else {
      session._setTarget(position, playing);
      session._follow();
    }
    session._refs++;
    session._graceTimer?.cancel();
    return session;
  }

  final String source;
  final Map<String, String> headers;

  VideoPlayerController? controller;

  /// 영상이 열렸다 / 소리 위치에 맞춰 돌기 시작했다 (그때까지 화면은 숨긴다).
  bool ready = false;
  bool shown = false;

  var _refs = 0;
  Timer? _graceTimer;
  var _disposed = false;

  var _position = Duration.zero;
  var _playing = false;

  /// 소리 위치를 받은 시각. 위치는 0.25초마다만 와서 그 사이를 어림하는 데 쓴다.
  var _positionStamp = DateTime.now();

  /// 마지막으로 되감은 시각.
  var _lastSync = DateTime.fromMillisecondsSinceEpoch(0);
  var _speed = 1.0;

  /// 위치를 옮길 때 다시 찾는 데 걸리는 시간만큼 앞서 가서 소리와 맞춘다.
  static const _seekLead = Duration(milliseconds: 300);
  static const _resyncGap = Duration(seconds: 3);

  /// 처음 열 때는 소리보다 이만큼 앞 지점에서 미리 받아 두었다가, 소리가 거기 닿는 순간 튼다.
  static const _startAhead = Duration(milliseconds: 1500);
  static const _bufferWait = Duration(seconds: 4);
  static const _movingWait = Duration(seconds: 3);

  /// 어긋남을 되감지 않고 재생 속도로 따라잡는다 (되감으면 그때마다 끊겨 보인다).
  static const _deadBand = Duration(milliseconds: 250);
  static const _catchUp = 1.06;
  static const _slowDown = 0.94;

  /// 이만큼 넘게 어긋나면(사용자가 위치를 크게 옮긴 경우 등) 한 번 되감는다.
  static const _hardSeekGap = Duration(milliseconds: 2500);

  void release() {
    _refs--;
    if (_refs > 0) return;
    _graceTimer?.cancel();
    _graceTimer = Timer(_graceTime, _dispose);
  }

  void _dispose() {
    if (_disposed) return;
    _disposed = true;
    _sessions.remove(source);
    final c = controller;
    controller = null;
    unawaited(c?.dispose());
    super.dispose();
  }

  void _setTarget(Duration position, bool playing) {
    if (position != _position || playing != _playing) {
      _positionStamp = DateTime.now();
    }
    _position = position;
    _playing = playing;
  }

  void update(Duration position, bool playing) {
    _setTarget(position, playing);
    _follow();
  }

  /// 지금 소리가 있는 자리 (재생 중이면 마지막으로 받은 위치에서 흐른 시간을 더한다).
  Duration _audioNow() => _playing
      ? _position + DateTime.now().difference(_positionStamp)
      : _position;

  VideoPlayerController _create() {
    final options = VideoPlayerOptions(mixWithOthers: true);
    if (source.startsWith('content://')) {
      return VideoPlayerController.contentUri(
        Uri.parse(source),
        videoPlayerOptions: options,
      );
    }
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return VideoPlayerController.networkUrl(
        Uri.parse(source),
        httpHeaders: headers,
        videoPlayerOptions: options,
      );
    }
    return VideoPlayerController.file(File(source), videoPlayerOptions: options);
  }

  bool _alive(VideoPlayerController c) => !_disposed && controller == c;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _bufferedPast(VideoPlayerController c, Duration at) =>
      c.value.buffered.any((r) => r.start <= at && r.end >= at);

  Future<void> _open() async {
    final c = _create();
    controller = c;
    try {
      await c.initialize();
      if (!_alive(c)) return;
      await c.setVolume(0);
      await c.setLooping(false);
      await _alignedStart(c);
    } catch (e) {
      // 영상을 못 열면 화면만 비운다 (소리 재생에는 영향이 없다). 까닭은 로그로 남긴다.
      debugPrint('[video] 영상을 못 엶 (${source.split('?').first}): $e');
      if (_alive(c)) {
        ready = false;
        _notify();
      }
    }
  }

  /// 소리보다 조금 앞 지점에서 멈춘 채 받아 두었다가, 소리가 그 자리에 닿는 순간 영상을 튼다.
  /// 그러면 영상이 도중에 튀며 따라붙지 않고 소리와 같은 자리에서 시작한다.
  Future<void> _alignedStart(VideoPlayerController c) async {
    if (!_playing) {
      // 멈춘 상태면 그 자리의 첫 화면만 보여 준다.
      await c.seekTo(_position);
      if (_alive(c)) {
        ready = shown = true;
        _notify();
      }
      return;
    }
    final target = _audioNow() + _startAhead;
    await c.seekTo(target);
    final bufferDeadline = DateTime.now().add(_bufferWait);
    while (_alive(c) &&
        DateTime.now().isBefore(bufferDeadline) &&
        !_bufferedPast(c, target + const Duration(milliseconds: 300))) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    // 소리가 그 자리에 닿기를 기다린다 (이미 지났으면 지금 소리 자리로 옮겨 튼다).
    while (_alive(c) &&
        _playing &&
        _audioNow() < target - const Duration(milliseconds: 60) &&
        target - _audioNow() < _startAhead + const Duration(seconds: 1)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (!_alive(c)) return;
    if (_audioNow() > target + const Duration(milliseconds: 300)) {
      await c.seekTo(_audioNow() + _seekLead);
    }
    if (_playing) await c.play();
    _lastSync = DateTime.now();
    if (!_alive(c)) return;
    ready = true;
    _notify();
    _revealWhenMoving(c);
    debugPrint('[video] 재생 시작: ${c.value.size}');
  }

  /// 영상이 실제로 움직이기 시작하면 화면을 보여 준다 (움직이지 않아도 잠시 뒤에는 보여 준다).
  void _revealWhenMoving(VideoPlayerController c) {
    final start = c.value.position;
    late final VoidCallback check;
    void reveal() {
      c.removeListener(check);
      if (_alive(c) && !shown) {
        shown = true;
        _notify();
      }
    }

    check = () {
      final v = c.value;
      if (v.isPlaying &&
          !v.isBuffering &&
          v.position > start + const Duration(milliseconds: 100)) {
        reveal();
      }
    };
    c.addListener(check);
    Timer(_movingWait, reveal);
  }

  void _setSpeed(VideoPlayerController c, double speed) {
    if (_speed == speed) return;
    _speed = speed;
    unawaited(c.setPlaybackSpeed(speed));
  }

  void _follow() {
    final c = controller;
    if (c == null || !ready || _disposed) return;
    final value = c.value;
    if (_playing && !value.isPlaying) {
      unawaited(c.play());
    } else if (!_playing && value.isPlaying) {
      unawaited(c.pause());
    }
    // 버퍼링 중에는 건드리지 않는다.
    if (value.isBuffering) return;
    // 양수면 영상이 소리보다 앞서 있다.
    final drift = value.position - _audioNow();
    final now = DateTime.now();
    if (drift.abs() > _hardSeekGap) {
      if (now.difference(_lastSync) > _resyncGap) {
        _lastSync = now;
        _setSpeed(c, 1);
        unawaited(c.seekTo(_audioNow() + _seekLead));
      }
    } else if (drift > _deadBand) {
      _setSpeed(c, _slowDown);
    } else if (drift < -_deadBand) {
      _setSpeed(c, _catchUp);
    } else {
      _setSpeed(c, 1);
    }
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
