import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../domain/repositories/lyrics_repository.dart';

class FilePickerLyricsSource implements LyricsFileSource {
  @override
  Future<String?> pickText() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['lrc', 'txt'],
    );
    final path = file?.path;
    if (path == null) return null;
    return decodeLyricsBytes(await File(path).readAsBytes());
  }
}

/// UTF-8로 읽는다 (BOM은 뗀다). 깨진 글자는 대체 문자로 남긴다.
String decodeLyricsBytes(List<int> bytes) {
  final start =
      bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF
      ? 3
      : 0;
  return utf8.decode(bytes.sublist(start), allowMalformed: true);
}
