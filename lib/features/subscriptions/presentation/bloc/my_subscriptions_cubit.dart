import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../account/domain/entities/google_account.dart';
import '../../../account/domain/usecases/account_usecases.dart';
import '../../domain/entities/channel_hit.dart';

enum MySubscriptionsStatus { idle, loading, done, failed }

class MySubscriptionsState extends Equatable {
  const MySubscriptionsState({
    this.status = MySubscriptionsStatus.idle,
    this.channels = const [],
    this.picked = const {},
    this.loaded = 0,
    this.failure,
    this.detail = '',
  });

  final MySubscriptionsStatus status;

  /// 내 YouTube 구독 채널 (이름순).
  final List<ChannelHit> channels;

  /// 고른 채널 id.
  final Set<String> picked;

  /// 불러오는 중에 지금까지 읽은 채널 수.
  final int loaded;

  final AccountFailure? failure;

  /// 실패의 자세한 까닭 (진단용).
  final String detail;

  MySubscriptionsState copyWith({Set<String>? picked}) => MySubscriptionsState(
    status: status,
    channels: channels,
    picked: picked ?? this.picked,
    loaded: loaded,
    failure: failure,
    detail: detail,
  );

  @override
  List<Object?> get props => [
    status,
    channels,
    picked,
    loaded,
    failure,
    detail,
  ];
}

/// 내 YouTube 구독 채널을 불러와 그중 고른 것만 앱의 구독 채널로 추가하는 화면의 상태.
/// 이미 구독 중인 채널은 [subscribedIds]로 알아 고를 수 없게 한다. 늦게 온 옛 요청의 답은 버린다.
class MySubscriptionsCubit extends Cubit<MySubscriptionsState> {
  MySubscriptionsCubit(this._fetch) : super(const MySubscriptionsState());

  final FetchMySubscriptions _fetch;
  int _request = 0;

  /// 구글 로그인이 돼 있어야 한다 (안 돼 있으면 `unauthorized` 실패).
  Future<void> load() async {
    final id = ++_request;
    emit(const MySubscriptionsState(status: MySubscriptionsStatus.loading));
    try {
      final items = await _fetch(
        MySubscriptionsParams(
          onProgress: (loaded) {
            if (id != _request || isClosed) return;
            emit(
              MySubscriptionsState(
                status: MySubscriptionsStatus.loading,
                loaded: loaded,
              ),
            );
          },
        ),
      );
      if (id != _request || isClosed) return;
      emit(
        MySubscriptionsState(
          status: MySubscriptionsStatus.done,
          channels: items,
        ),
      );
    } on AccountException catch (e) {
      if (id != _request || isClosed) return;
      emit(
        MySubscriptionsState(
          status: MySubscriptionsStatus.failed,
          failure: e.failure,
          detail: e.message,
        ),
      );
    } on Object catch (e) {
      if (id != _request || isClosed) return;
      emit(
        MySubscriptionsState(
          status: MySubscriptionsStatus.failed,
          failure: AccountFailure.failed,
          detail: '$e',
        ),
      );
    }
  }

  void toggle(String channelId) {
    final next = {...state.picked};
    next.contains(channelId) ? next.remove(channelId) : next.add(channelId);
    emit(state.copyWith(picked: next));
  }

  /// 아직 구독하지 않은 채널을 모두 고른다.
  void pickAllNew(Set<String> subscribedIds) => emit(
    state.copyWith(
      picked: {
        for (final c in state.channels)
          if (!subscribedIds.contains(c.id)) c.id,
      },
    ),
  );

  void clearPicked() => emit(state.copyWith(picked: {}));

  /// 고른 채널 (목록 순서대로, 이미 구독한 것은 뺀다).
  List<ChannelHit> pickedChannels(Set<String> subscribedIds) => [
    for (final c in state.channels)
      if (state.picked.contains(c.id) && !subscribedIds.contains(c.id)) c,
  ];
}
