import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../search/domain/entities/engine_exception.dart';
import '../../../search/domain/entities/search_source.dart';
import '../../../search/domain/usecases/search_usecases.dart';

enum CoverWebStatus { idle, loading, loaded, failed }

class CoverWebState extends Equatable {
  const CoverWebState({
    this.status = CoverWebStatus.idle,
    this.images = const [],
  });

  final CoverWebStatus status;

  /// 찾은 이미지 주소 (영상 대표 이미지).
  final List<String> images;

  @override
  List<Object?> get props => [status, images];
}

/// 웹에서 커버로 쓸 이미지를 키워드로 찾는다 (검색 결과의 대표 이미지).
class CoverWebCubit extends Cubit<CoverWebState> {
  CoverWebCubit(this._search) : super(const CoverWebState());

  final SearchTracks _search;
  int _round = 0;

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final round = ++_round;
    emit(const CoverWebState(status: CoverWebStatus.loading));
    try {
      final page = await _search(SearchParams(q, SearchSource.youtube));
      if (isClosed || round != _round) return;
      emit(
        CoverWebState(
          status: CoverWebStatus.loaded,
          images: [
            for (final hit in page.items)
              if (hit.thumbnailUrl case final url? when url.isNotEmpty) url,
          ],
        ),
      );
    } on EngineException {
      if (!isClosed && round == _round) {
        emit(const CoverWebState(status: CoverWebStatus.failed));
      }
    }
  }
}

/// 입력이 곧바로 이미지 주소로 쓸 수 있는 http(s) 주소인가.
bool isWebImageUrl(String input) {
  final uri = Uri.tryParse(input.trim());
  return uri != null &&
      uri.hasAuthority &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}
