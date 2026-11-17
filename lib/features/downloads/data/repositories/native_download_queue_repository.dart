import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/default_video_folder.dart';
import '../../../covers/domain/entities/cover_art.dart';
import '../../domain/entities/download_item.dart';
import '../../domain/entities/download_request.dart';
import '../../domain/entities/download_source.dart';
import '../../domain/entities/tag_notice.dart';
import '../../domain/repositories/download_queue_repository.dart';
import '../../domain/repositories/download_settings_repository.dart';
import '../datasources/download_queue_store.dart';

/// 받기 큐 저장소 (Android): 받기 큐 · 이어받기 · 변환 · 태그 · 저장 · 보관함 등록은 모두 네이티브(`music_app/downloads`,
/// Kotlin `DownloadEngine`)가 한다. 여기서는 요청을 넘기고 네이티브가 알려 주는 상태를 그리는 데 쓴다.
/// 앱이 꺼져 있어도 받기는 네이티브(포그라운드 서비스)가 이어 가고, 앱을 켜면 지금 상태를 받아 온다.
class NativeDownloadQueueRepository implements DownloadQueueRepository {
  NativeDownloadQueueRepository({
    required this._settings,
    required this._openLibrary,
    this._onEngineError,
    this._onLibraryChanged,
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('music_app/downloads') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final DownloadSettingsRepository _settings;

  /// 보관함 DB를 연다 (네이티브가 그 파일에 쓰기 전에, 최신 스키마가 되도록 Dart가 먼저 한 번 연다).
  final Future<void> Function() _openLibrary;

  /// 엔진이 받기를 못 해서 낸 오류 문구를 알린다 (버전이 오래된 경우 엔진 쪽이 알아서 업데이트한다).
  final void Function(String message)? _onEngineError;

  /// 네이티브가 보관함 DB에 곡을 썼다: 목록 스트림이 다시 읽도록 표를 알린다.
  final void Function()? _onLibraryChanged;

  final _changes = StreamController<List<DownloadItem>>.broadcast();
  final _tagNotices = StreamController<TagNotice>.broadcast();
  var _items = const <DownloadItem>[];
  Future<void>? _ready;

  Future<void> _ensureReady() => _ready ??= _init();

  Future<void> _init() async {
    // 옛 버전(Dart 큐)이 shared_preferences에 남긴 대기열을 네이티브가 한 번 가져간다.
    try {
      final prefs = await SharedPreferences.getInstance();
      await _channel.invokeMethod<void>('importLegacy', {
        'queue': prefs.getString('download.queue'),
        'sources': prefs.getString('download.sources'),
      });
    } on PlatformException {
      // 가져오기는 덤이다.
    } on MissingPluginException {
      // 네이티브가 없는 빌드(데스크톱 등)는 받기를 쓸 수 없다.
    }
    try {
      await _openLibrary();
      await _channel.invokeMethod<void>('dbReady');
    } on Object {
      // DB를 못 열면 네이티브가 등록을 맡겨 두었다가 다음에 쓴다.
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    try {
      final raw = await _channel.invokeListMethod<Object?>('snapshot');
      _setItems(raw ?? const []);
    } on PlatformException {
      // 상태는 다음 알림에서 다시 온다.
    } on MissingPluginException {
      // 네이티브가 없다.
    }
  }

  void _setItems(List<Object?> raw) {
    _items = [for (final e in raw) _itemOf(Map<Object?, Object?>.from(e! as Map))];
    _changes.add(_items);
  }

  Future<void> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'queue':
        _setItems(call.arguments as List<Object?>);
      case 'tagNotice':
        final m = Map<Object?, Object?>.from(call.arguments as Map);
        _tagNotices.add(
          TagNotice(
            title: m['title'] as String? ?? '',
            extension: m['extension'] as String? ?? '',
            ok: m['ok'] == true,
            detail: m['detail'] as String? ?? '',
          ),
        );
      case 'saved':
        // 고정한 폴더가 없을 때의 기준: 마지막에 받은 폴더.
        final folder = call.arguments;
        if (folder is String && folder.isNotEmpty) {
          unawaited(_settings.saveLastSavePath(folder));
        }
      case 'engineError':
        final message = call.arguments;
        if (message is String) _onEngineError?.call(message);
      case 'libraryChanged':
        _onLibraryChanged?.call();
    }
  }

  static DownloadItem _itemOf(Map<Object?, Object?> m) {
    final cover = m['cover'];
    return DownloadItem(
      id: m['id']! as String,
      title: m['title'] as String? ?? '',
      artist: m['artist'] as String? ?? '',
      genre: m['genre'] as String? ?? '',
      playlistIds: {...?(m['playlistIds'] as List<Object?>?)?.cast<String>()},
      status: DownloadStatus.values.byName(m['status']! as String),
      progress: (m['progress'] as num?)?.toDouble() ?? 0,
      thumbnailUrl: m['thumbnailUrl'] as String?,
      cover: cover is Map ? _coverOf(Map<Object?, Object?>.from(cover)) : null,
      duration: m['durationMs'] == null
          ? null
          : Duration(milliseconds: (m['durationMs']! as num).toInt()),
      color: (m['color'] as num?)?.toInt(),
      url: m['url'] as String? ?? '',
      error: m['error'] as String? ?? '',
      processing: m['processing'] == true,
      savedFolder: m['savedFolder'] as String? ?? '',
    );
  }

  static CoverArt? _coverOf(Map<Object?, Object?> c) {
    final t = CoverTransform(
      scale: (c['scale'] as num?)?.toDouble() ?? 1,
      dx: (c['dx'] as num?)?.toDouble() ?? 0,
      dy: (c['dy'] as num?)?.toDouble() ?? 0,
      rotation: (c['rotation'] as num?)?.toDouble() ?? 0,
    );
    final url = c['url'] as String?;
    final path = c['path'] as String?;
    if (url != null) return CoverArt.web(url, transform: t);
    if (path != null) return CoverArt.file(path, transform: t);
    return null;
  }

  @override
  Stream<List<DownloadItem>> watchQueue() {
    late final StreamController<List<DownloadItem>> out;
    StreamSubscription<List<DownloadItem>>? sub;
    out = StreamController<List<DownloadItem>>(
      onListen: () async {
        await _ensureReady();
        out.add(_items);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Stream<TagNotice> watchTagNotices() => _tagNotices.stream;

  @override
  Future<ExistingDownload> findExisting(String url) async {
    await _ensureReady();
    final r = await _channel.invokeMapMethod<String, Object?>('findExisting', {
      'url': url,
    });
    return ExistingDownload(
      trackId: r?['trackId'] as String?,
      inQueue: r?['inQueue'] == true,
    );
  }

  @override
  Future<String?> sourceUrlOf(String trackId) async {
    await _ensureReady();
    return _channel.invokeMethod<String>('sourceUrlOf', {'trackId': trackId});
  }

  @override
  Future<void> enqueue(DownloadRequest request) async {
    await _ensureReady();
    final format = request.format ?? await _settings.loadFormat();
    final folder = request.videoFormat != null
        ? (request.savePath.isNotEmpty ? request.savePath : defaultVideoFolder())
        : (request.savePath.isNotEmpty
              ? request.savePath
              : await _settings.loadSavePath());
    final payload = {
      ...encodeDownloadRequest(request),
      'resolvedFormat': format.name,
      'resolvedFolder': folder,
    };
    await _channel.invokeMethod<String>('enqueue', {
      'request': jsonEncode(_withoutNulls(payload)),
    });
  }

  /// JSON에서 null 값을 뺀다 (네이티브가 없는 칸과 null을 같게 읽도록).
  static Object? _withoutNulls(Object? v) {
    if (v is Map) {
      return {
        for (final e in v.entries)
          if (e.value != null) e.key: _withoutNulls(e.value),
      };
    }
    if (v is List) return [for (final e in v) _withoutNulls(e)];
    return v;
  }

  @override
  Future<void> pause(String id) => _command('pause', id);

  @override
  Future<void> resume(String id) => _command('resume', id);

  @override
  Future<void> retry(String id) => _command('retry', id);

  @override
  Future<void> cancel(String id) => _command('cancel', id);

  Future<void> _command(String method, String id) async {
    await _ensureReady();
    await _channel.invokeMethod<void>(method, {'id': id});
  }

  @override
  Future<int> cancelAll({String? playlistId}) async {
    await _ensureReady();
    return await _channel.invokeMethod<int>('cancelAll', {
          'playlistId': playlistId,
        }) ??
        0;
  }
}
