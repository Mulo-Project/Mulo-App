import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../search/domain/usecases/search_usecases.dart';

class ChannelInfoState extends Equatable {
  const ChannelInfoState({
    this.loading = true,
    this.subscriberCount,
    this.categories = const {},
  });

  /// 구독자 수를 읽는 중인지.
  final bool loading;
  final int? subscriberCount;

  /// 알림 받을 분류 (비어 있으면 모든 분류).
  final Set<String> categories;

  @override
  List<Object?> get props => [loading, subscriberCount, categories];
}

/// 채널 정보 시트: 구독자 수를 읽고, 알림 받을 분류를 고른다.
class ChannelInfoCubit extends Cubit<ChannelInfoState> {
  ChannelInfoCubit(this._fetch) : super(const ChannelInfoState());

  final FetchChannelInfo _fetch;

  Future<void> load(String channelUrl, Set<String> categories) async {
    emit(ChannelInfoState(categories: categories));
    try {
      final info = await _fetch(channelUrl);
      if (isClosed) return;
      emit(
        ChannelInfoState(
          loading: false,
          subscriberCount: info.subscriberCount,
          categories: state.categories,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(ChannelInfoState(loading: false, categories: state.categories));
    }
  }

  void toggleCategory(String name) {
    final next = {...state.categories};
    next.contains(name) ? next.remove(name) : next.add(name);
    emit(
      ChannelInfoState(
        loading: state.loading,
        subscriberCount: state.subscriberCount,
        categories: next,
      ),
    );
  }

  void clearCategories() => emit(
    ChannelInfoState(
      loading: state.loading,
      subscriberCount: state.subscriberCount,
      categories: const {},
    ),
  );
}
