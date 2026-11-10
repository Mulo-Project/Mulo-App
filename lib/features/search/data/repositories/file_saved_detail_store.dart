import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/media_info.dart';
import '../../domain/repositories/saved_detail_store.dart';

/// 앱 문서 폴더의 `saved_details/<id>.txt`에 저장한 곡의 상세 정보를 쓴다. 쓰지 못해도 저장 자체는 막지 않는다.
class FileSavedDetailStore implements SavedDetailStore {
  Future<File> _file(String id) async {
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/saved_details',
    );
    await dir.create(recursive: true);
    return File(
      '${dir.path}/${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}.txt',
    );
  }

  @override
  Future<void> write(MediaHit hit) async {
    try {
      await (await _file(hit.id)).writeAsString(formatSavedDetail(hit));
    } on Object {
      // 상세 정보는 덤이다: 못 써도 넘어간다.
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final f = await _file(id);
      if (await f.exists()) await f.delete();
    } on Object {
      // 없으면 그만.
    }
  }
}

/// 상세 정보 글 파일의 내용.
String formatSavedDetail(MediaHit h) {
  final d = h.uploadedAt;
  final lines = <String>[
    '제목: ${h.title}',
    '주소: ${h.url}',
    if (h.uploader.isNotEmpty) '채널: ${h.uploader}',
    if (h.creators.length > 1) '함께 올린 채널: ${h.creators.join(', ')}',
    if (h.channelUrl != null) '채널 주소: ${h.channelUrl}',
    if (h.subscriberCount != null) '구독자: ${h.subscriberCount}',
    if (h.viewCount != null) '조회수: ${h.viewCount}',
    if (h.likeCount != null) '좋아요: ${h.likeCount}',
    if (d != null)
      '올린 날: ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
    if (h.duration != null) '길이: ${h.duration!.inSeconds}초',
    if (h.categories.isNotEmpty) '분류: ${h.categories.join(', ')}',
    if (h.album.isNotEmpty) '앨범: ${h.album}',
    if (h.description.isNotEmpty) '\n설명:\n${h.description}',
  ];
  return '${lines.join('\n')}\n';
}
