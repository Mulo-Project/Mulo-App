import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/track.dart';
import '../../domain/usecases/library_usecases.dart';

class LibraryState extends Equatable {
  const LibraryState({this.tracks = const [], this.loaded = false});

  /// 추가일 최신순.
  final List<Track> tracks;

  /// DB에서 처음 목록을 받았는지 (빈 보관함 안내를 깜빡이지 않게).
  final bool loaded;

  @override
  List<Object?> get props => [tracks, loaded];
}

/// 보관함 곡 목록. DB 변경을 구독한다.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._watch) : super(const LibraryState());

  final WatchLibraryTracks _watch;
  StreamSubscription<List<Track>>? _sub;

  void start() {
    _sub ??= _watch(const NoParams())
        .listen((tracks) => emit(LibraryState(tracks: tracks, loaded: true)));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
