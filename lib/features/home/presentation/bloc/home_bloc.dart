import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_summary.dart';
import '../../domain/usecases/home_usecases.dart';

sealed class HomeEvent {
  const HomeEvent();
}

/// 홈을 열 때: 요약 구독 시작.
class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// 순위 · 분석 기간 바꾸기.
class HomePeriodChanged extends HomeEvent {
  const HomePeriodChanged(this.period);

  final HomePeriod period;
}

class _HomeSummaryUpdated extends HomeEvent {
  const _HomeSummaryUpdated(this.summary);

  final HomeSummary summary;
}

class HomeState extends Equatable {
  const HomeState({
    this.period = HomePeriod.week,
    this.summary = const HomeSummary(),
    this.loaded = false,
  });

  final HomePeriod period;
  final HomeSummary summary;
  final bool loaded;

  HomeState copyWith({
    HomePeriod? period,
    HomeSummary? summary,
    bool? loaded,
  }) => HomeState(
    period: period ?? this.period,
    summary: summary ?? this.summary,
    loaded: loaded ?? this.loaded,
  );

  @override
  List<Object?> get props => [period, summary, loaded];
}

/// 홈 (많이 들은 곡 · 청취 분석 · 추천 · 최근 재생). 보관함 · 재생 기록 변경을 구독한다.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._watch) : super(const HomeState()) {
    on<HomeStarted>((_, _) => _subscribe());
    on<HomePeriodChanged>((e, emit) {
      emit(state.copyWith(period: e.period));
      _subscribe();
    });
    on<_HomeSummaryUpdated>(
      (e, emit) => emit(state.copyWith(summary: e.summary, loaded: true)),
    );
  }

  final WatchHomeSummary _watch;
  StreamSubscription<HomeSummary>? _sub;

  void _subscribe() {
    _sub?.cancel();
    _sub = _watch(HomeSummaryParams(state.period))
        .listen((s) => add(_HomeSummaryUpdated(s)));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
