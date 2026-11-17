import 'dart:async';

import 'package:flutter/services.dart';

/// 앱 DB는 네이티브(Kotlin `MuloDb` · `LibraryDb`)가 쥔다. Dart는 값을 넘겨 부르고 결과를 받을 뿐이다
/// (채널 `music_app/db`). 테이블이 바뀌면 네이티브가 `music_app/db/changes`로 알려 주고, [watch]가 목록을 다시 읽는다.
/// 앱 밖(알림의 좋아요 · 받기 끝)에서 바뀐 것도 같은 길로 온다.
class NativeDb {
  NativeDb({MethodChannel? channel, EventChannel? changes})
    : _channel = channel ?? const MethodChannel('music_app/db'),
      _changes = changes ?? const EventChannel('music_app/db/changes');

  final MethodChannel _channel;
  final EventChannel _changes;

  /// 바뀐 테이블 이름들. 플랫폼 구독은 하나만 만들고 모든 듣는 쪽이 나눠 쓴다.
  late final Stream<Set<String>> _tableChanges = _changes
      .receiveBroadcastStream()
      .map((e) => {for (final t in (e as List<Object?>)) t! as String});

  Future<T?> call<T>(String method, [Map<String, Object?>? args]) =>
      _channel.invokeMethod<T>(method, args);

  /// 항목이 맵인 목록을 돌려주는 호출.
  Future<List<Map<String, Object?>>> list(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    final rows = await _channel.invokeListMethod<Object?>(method, args);
    return [
      for (final r in rows ?? const <Object?>[])
        Map<String, Object?>.from(r! as Map),
    ];
  }

  /// 맵 하나를 돌려주는 호출.
  Future<Map<String, Object?>> map(
    String method, [
    Map<String, Object?>? args,
  ]) async => Map<String, Object?>.from(
    (await _channel.invokeMapMethod<String, Object?>(method, args))!,
  );

  /// 구독하자마자 한 번, 이후 [tables] 중 하나가 바뀔 때마다 [load]를 다시 불러 새 값을 흘려보낸다.
  /// 읽는 중에 또 바뀌면 끝난 뒤 한 번 더 읽는다. 구독을 끊으면 알림 듣기도 끊는다.
  Stream<T> watch<T>(Set<String> tables, Future<T> Function() load) {
    return Stream<T>.multi((c) {
      var running = false;
      var again = false;
      Future<void> run() async {
        if (running) {
          again = true;
          return;
        }
        running = true;
        try {
          do {
            again = false;
            final value = await load();
            if (c.isClosed) return;
            c.add(value);
          } while (again);
        } on Object catch (e, st) {
          if (!c.isClosed) c.addError(e, st);
        } finally {
          running = false;
        }
      }

      // 먼저 듣기 시작해 첫 읽기 도중의 바뀜을 놓치지 않는다.
      final sub = _tableChanges
          .where((changed) => changed.any(tables.contains))
          .listen((_) => unawaited(run()));
      c.onCancel = sub.cancel;
      unawaited(run());
    });
  }
}

/// 네이티브가 돌려준 곡 맵의 시각(초)을 DateTime으로.
DateTime dateOfSec(Object? sec) =>
    DateTime.fromMillisecondsSinceEpoch(((sec! as num).toInt()) * 1000);
