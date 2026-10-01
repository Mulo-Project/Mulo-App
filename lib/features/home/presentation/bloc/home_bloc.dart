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
    this.revision = 0,
  });

  final HomePeriod period;
  final HomeSummary summary;
  final bool loaded;

  /// 요약을 새로 받을 때마다 올라간다. 곡은 id만으로 같다고 보기 때문에,
  /// 곡 정보를 고쳐도 화면이 다시 그려지도록 내용 대신 이 값을 비교한다.
  final int revision;

  HomeState copyWith({
    HomePeriod? period,
    HomeSummary? summary,
    bool? loaded,
    int? revision,
  }) => HomeState(
    period: period ?? this.period,
    summary: summary ?? this.summary,
    loaded: loaded ?? this.loaded,
    revision: revision ?? this.revision,
  );

  @override
  List<Object?> get props => [period, summary, loaded, revision];
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
