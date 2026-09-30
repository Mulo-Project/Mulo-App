import 'package:equatable/equatable.dart';

/// 재생목록 하나 (상세 기능: 재생목록 관리 #20).
class Playlist extends Equatable {
  const Playlist({required this.id, required this.name, this.trackCount = 0});

  final String id;
  final String name;
  final int trackCount;

  @override
  List<Object?> get props => [id, name, trackCount];
}
