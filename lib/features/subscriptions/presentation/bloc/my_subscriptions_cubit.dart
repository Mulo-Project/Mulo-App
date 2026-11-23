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
    this.loaded = 0,
    this.failure,
    this.detail = '',
  });

  final MySubscriptionsStatus status;

  /// 내 YouTube 구독 채널 (이름순).
  final List<ChannelHit> channels;

  /// 불러오는 중에 지금까지 읽은 채널 수.
  final int loaded;

  final AccountFailure? failure;

  /// 실패의 자세한 까닭 (진단용).
  final String detail;

  @override
  List<Object?> get props => [
    status,
    channels,
    loaded,
    failure,
    detail,
  ];
}

/// 내 YouTube 구독 채널을 불러와 불러오는 화면의 상태. 늦게 온 옛 요청의 답은 버린다.
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
}
