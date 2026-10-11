import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/channel_hit.dart';
import '../../domain/usecases/subscription_usecases.dart';

enum ChannelSearchStatus { idle, loading, done, failed }

class ChannelSearchState extends Equatable {
  const ChannelSearchState({
    this.status = ChannelSearchStatus.idle,
    this.query = '',
    this.results = const [],
  });

  final ChannelSearchStatus status;
  final String query;
  final List<ChannelHit> results;

  @override
  List<Object?> get props => [status, query, results];
}

/// 키워드로 채널을 찾는다. 늦게 온 옛 요청의 답은 버린다.
class ChannelSearchCubit extends Cubit<ChannelSearchState> {
  ChannelSearchCubit(this._search) : super(const ChannelSearchState());

  final SearchChannels _search;
  int _request = 0;

  Future<void> search(String input) async {
    final query = input.trim();
    final id = ++_request;
    if (query.isEmpty) {
      emit(const ChannelSearchState());
      return;
    }
    emit(ChannelSearchState(status: ChannelSearchStatus.loading, query: query));
    try {
      final results = await _search(query);
      if (id != _request || isClosed) return;
      emit(
        ChannelSearchState(
          status: ChannelSearchStatus.done,
          query: query,
          results: results,
        ),
      );
    } on Object {
      if (id != _request || isClosed) return;
      emit(
        ChannelSearchState(status: ChannelSearchStatus.failed, query: query),
      );
    }
  }
}
