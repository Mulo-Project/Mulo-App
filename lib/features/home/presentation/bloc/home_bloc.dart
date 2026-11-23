import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/usecases/home_usecases.dart';

sealed class HomeEvent {
  const HomeEvent();
}

/// 홈을 열 때: 요약 구독 시작 · 가입일 읽기.
class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class _HomeSummaryUpdated extends HomeEvent {
  const _HomeSummaryUpdated(this.summary);

  final HomeSummary summary;
}

class HomeState extends Equatable {
  const HomeState({
    this.summary = const HomeSummary(),
    this.joinedAt,
    this.loaded = false,
    this.revision = 0,
  });

  final HomeSummary summary;

  /// 앱을 처음 쓴 날. 아직 못 읽었으면 null.
  final DateTime? joinedAt;
  final bool loaded;

  /// 요약을 새로 받을 때마다 올라간다. 곡은 id만으로 같다고 보기 때문에,
  /// 곡 정보를 고쳐도 화면이 다시 그려지도록 내용 대신 이 값을 비교한다.
  final int revision;

  HomeState copyWith({
    HomeSummary? summary,
    DateTime? joinedAt,
    bool? loaded,
    int? revision,
  }) => HomeState(
    summary: summary ?? this.summary,
    joinedAt: joinedAt ?? this.joinedAt,
    loaded: loaded ?? this.loaded,
    revision: revision ?? this.revision,
  );

  @override
  List<Object?> get props => [summary, joinedAt, loaded, revision];
}

/// 홈 (최근 들은 곡 · 날짜별 청취 · 많이 들은 곡 · 추천). 보관함 · 재생 기록 변경을 구독한다.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._watch, this._joinDate) : super(const HomeState()) {
    on<HomeStarted>((_, emit) async {
      _sub?.cancel();
      _sub = _watch(const HomeSummaryParams())
          .listen((s) => add(_HomeSummaryUpdated(s)));
      final joined = await _joinDate(const NoParams());
      emit(state.copyWith(joinedAt: joined));
    });
    on<_HomeSummaryUpdated>(
      (e, emit) => emit(
        state.copyWith(
          summary: e.summary,
          loaded: true,
          revision: state.revision + 1,
        ),
      ),
    );
  }

  final WatchHomeSummary _watch;
  final GetJoinDate _joinDate;
  StreamSubscription<HomeSummary>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
