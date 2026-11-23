import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/subscription_usecases.dart';

class ChannelInfoState extends Equatable {
  const ChannelInfoState({
    this.loading = true,
    this.subscriberCount,
    this.bannerUrl,
    this.description,
    this.categories = const {},
    this.savePath = '',
  });

  /// 구독자 수를 읽는 중인지.
  final bool loading;
  final int? subscriberCount;

  /// 채널 배너 이미지. 없으면 null.
  final String? bannerUrl;

  /// 채널 소개 전체. 못 읽었으면 null (검색 결과의 한 토막을 쓴다).
  final String? description;

  /// 알림 받을 분류 (비어 있으면 모든 분류).
  final Set<String> categories;

  /// 새 영상을 저장할 폴더 (비어 있으면 기본 저장 위치).
  final String savePath;

  ChannelInfoState copyWith({
    bool? loading,
    int? subscriberCount,
    String? bannerUrl,
    String? description,
    Set<String>? categories,
    String? savePath,
  }) => ChannelInfoState(
    loading: loading ?? this.loading,
    subscriberCount: subscriberCount ?? this.subscriberCount,
    bannerUrl: bannerUrl ?? this.bannerUrl,
    description: description ?? this.description,
    categories: categories ?? this.categories,
    savePath: savePath ?? this.savePath,
  );

  @override
  List<Object?> get props => [
    loading,
    subscriberCount,
    bannerUrl,
    description,
    categories,
    savePath,
  ];
}

/// 채널 정보 시트: 구독자 수를 읽고, 알림 받을 분류 · 저장 위치를 고른다.
class ChannelInfoCubit extends Cubit<ChannelInfoState> {
  ChannelInfoCubit(this._fetch) : super(const ChannelInfoState());

  final FetchChannelDetails _fetch;

  /// [categories] · [savePath]는 이미 구독 중인 채널이면 저장돼 있는 값.
  Future<void> load(
    String channelId, {
    Set<String> categories = const {},
    String savePath = '',
  }) async {
    emit(ChannelInfoState(categories: categories, savePath: savePath));
    try {
      final info = await _fetch(channelId);
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          subscriberCount: info.subscriberCount,
          bannerUrl: info.bannerUrl,
          description: info.description,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(loading: false));
    }
  }

  void toggleCategory(String name) {
    final next = {...state.categories};
    next.contains(name) ? next.remove(name) : next.add(name);
    emit(state.copyWith(categories: next));
  }

  void clearCategories() => emit(state.copyWith(categories: const {}));

  void setSavePath(String path) => emit(state.copyWith(savePath: path));
}
