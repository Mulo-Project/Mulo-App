import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../downloads/domain/entities/download_request.dart';
import '../../../downloads/domain/usecases/download_usecases.dart';
import '../../../search/domain/entities/media_info.dart';
import '../../../search/domain/usecases/search_usecases.dart';
import '../../domain/entities/channel_new_videos.dart';
import '../../domain/entities/feed_video.dart';
import '../../domain/entities/subscribed_channel.dart';
import '../../domain/usecases/subscription_usecases.dart';
import 'subscriptions_cubit.dart';

enum NewVideosStatus { idle, checking, done }

/// 채널 하나의 새 영상 묶음 (화면에 보이는 것만).
class NewVideosGroup extends Equatable {
  const NewVideosGroup({required this.channel, required this.videos});

  final SubscribedChannel channel;
  final List<FeedVideo> videos;

  @override
  List<Object?> get props => [channel, videos];
}

class NewVideosState extends Equatable {
  const NewVideosState({
    this.status = NewVideosStatus.idle,
    this.checked = const [],
    this.hidden = const {},
    this.resolved = const {},
    this.selected = const {},
    this.queued = 0,
  });

  final NewVideosStatus status;

  /// 확인한 결과 (거르기 전).
  final List<ChannelNewVideos> checked;

  /// "음악만"에 걸려 숨긴 영상 id.
  final Set<String> hidden;

  /// "음악만" 채널에서 분류를 이미 확인한 영상 id.
  final Set<String> resolved;
  final Set<String> selected;

  /// 마지막으로 받기 대기열에 넣은 곡 수.
  final int queued;

  /// "음악만" 채널의 영상은 분류를 확인하기 전에는 보이지 않는다.
  bool _visible(SubscribedChannel c, FeedVideo v) =>
      !hidden.contains(v.id) && (!c.musicOnly || resolved.contains(v.id));

  /// 분류 확인이 남은 영상이 있는지.
  bool get resolving => checked.any(
    (r) => r.channel.musicOnly && r.videos.any((v) => !resolved.contains(v.id)),
  );

  List<NewVideosGroup> get groups => [
    for (final r in checked)
      if (r.videos.where((v) => _visible(r.channel, v)).isNotEmpty)
        NewVideosGroup(
          channel: r.channel,
          videos: [
            for (final v in r.videos)
              if (_visible(r.channel, v)) v,
          ],
        ),
  ];

  int get count => groups.fold(0, (n, g) => n + g.videos.length);

  Set<String> get visibleIds => {
    for (final g in groups)
      for (final v in g.videos) v.id,
  };

  bool get allSelected => count > 0 && visibleIds.every(selected.contains);

  NewVideosState copyWith({
    NewVideosStatus? status,
    List<ChannelNewVideos>? checked,
    Set<String>? hidden,
    Set<String>? resolved,
    Set<String>? selected,
    int? queued,
  }) => NewVideosState(
    status: status ?? this.status,
    checked: checked ?? this.checked,
    hidden: hidden ?? this.hidden,
    resolved: resolved ?? this.resolved,
    selected: selected ?? this.selected,
    queued: queued ?? this.queued,
  );

  @override
  List<Object?> get props => [
    status,
    checked,
    hidden,
    resolved,
    selected,
    queued,
  ];
}

/// 구독 채널의 새 영상을 확인하고, 골라서 받기 대기열에 넣는다 (자동으로 받지 않는다).
class NewVideosCubit extends Cubit<NewVideosState> {
  NewVideosCubit(
    this._subs,
    this._check,
    this._info,
    this._enqueue,
    this._findExisting,
    this._clear,
  ) : super(const NewVideosState());

  final SubscriptionsCubit _subs;
  final CheckNewVideos _check;
  final FetchMediaInfo _info;
  final EnqueueDownload _enqueue;
  final FindExistingDownload _findExisting;
  final ClearNewVideosNotification _clear;

  int _generation = 0;

  /// 켜 둔 채널의 새 영상을 확인한다. 이미 확인 중이면 건너뛴다.
  Future<void> check() async {
    if (state.status == NewVideosStatus.checking) return;
    await _subs.load();
    final channels = _subs.state.channels;
    if (!channels.any((c) => c.enabled)) {
      emit(const NewVideosState(status: NewVideosStatus.done));
      return;
    }
    final gen = ++_generation;
    emit(state.copyWith(status: NewVideosStatus.checking));
    final results = await _check(channels);
    if (gen != _generation || isClosed) return;
    emit(
      NewVideosState(
        status: NewVideosStatus.done,
        checked: [
          for (final r in results)
            if (r.videos.isNotEmpty || r.latestPublishedAt != null) r,
        ],
      ),
    );
    unawaited(_resolveCategories(gen));
  }

  /// "음악만" 채널의 새 영상은 분류(Music)를 읽어 아닌 것을 숨긴다. 읽지 못하면 그대로 보여 준다.
  Future<void> _resolveCategories(int gen) async {
    final todo = [
      for (final r in state.checked)
        if (r.channel.musicOnly)
          for (final v in r.videos) v,
    ];
    var next = 0;
    Future<void> worker() async {
      while (next < todo.length) {
        final v = todo[next++];
        var music = true;
        try {
          final info = await _info(v.url);
          if (info case VideoInfo(:final hit) when hit.categories.isNotEmpty) {
            music = hit.categories.contains('Music');
          }
        } on Object {
          // 읽지 못하면 걸러내지 않는다.
        }
        if (gen != _generation || isClosed) return;
        emit(
          state.copyWith(
            resolved: {...state.resolved, v.id},
            hidden: music ? null : {...state.hidden, v.id},
            selected: music ? null : ({...state.selected}..remove(v.id)),
          ),
        );
      }
    }

    await Future.wait([for (var i = 0; i < 3; i++) worker()]);
  }

  void toggle(String id) {
    final next = {...state.selected};
    next.contains(id) ? next.remove(id) : next.add(id);
    emit(state.copyWith(selected: next));
  }

  /// 보이는 영상을 모두 고르거나, 모두 골랐으면 모두 해제한다.
  void toggleAll() =>
      emit(state.copyWith(selected: state.allSelected ? {} : state.visibleIds));

  /// 채널 하나의 영상을 모두 고르거나 해제한다.
  void toggleChannel(String channelId) {
    final group = state.groups
        .where((g) => g.channel.id == channelId)
        .firstOrNull;
    if (group == null) return;
    final ids = {for (final v in group.videos) v.id};
    final all = ids.every(state.selected.contains);
    emit(
      state.copyWith(
        selected: all
            ? state.selected.difference(ids)
            : {...state.selected, ...ids},
      ),
    );
  }

  /// 고른 영상을 받기 대기열에 넣는다 (이미 받았거나 받는 중인 곡은 건너뛴다). 넣은 곡 수를 돌려준다.
  Future<int> startSelected() async {
    var queued = 0;
    for (final g in state.groups) {
      for (final v in g.videos) {
        if (!state.selected.contains(v.id)) continue;
        if ((await _findExisting(v.url)).exists) continue;
        final ok = await _enqueue(
          DownloadRequest(
            title: v.title,
            artist: v.author.isNotEmpty ? v.author : g.channel.name,
            thumbnailUrl: v.thumbnailUrl,
            url: v.url,
          ),
        );
        if (ok) queued++;
      }
    }
    if (!isClosed) {
      emit(state.copyWith(selected: {}, queued: queued));
    }
    return queued;
  }

  /// 화면을 닫을 때: 확인한 채널은 여기까지 봤다고 표시하고 목록을 비운다 (다음에 다시 뜨지 않는다).
  Future<void> markSeen() async {
    final seen = {
      for (final r in state.checked)
        if (r.latestPublishedAt != null) r.channel.id: r.latestPublishedAt!,
    };
    ++_generation;
    emit(const NewVideosState(status: NewVideosStatus.done));
    await _clear(const NoParams());
    await _subs.markSeen(seen);
  }
}
