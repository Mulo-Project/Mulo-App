import 'package:file_picker/file_picker.dart';

import '../../domain/repositories/cover_repository.dart';

class FilePickerImageSource implements CoverImageSource {
  @override
  Future<String?> pickFromDevice() async {
    // 한 장만 고른다 (pickFiles는 여러 장 선택 화면이 뜬다).
    final file = await FilePicker.pickFile(type: FileType.image);
    return file?.path;
  }
}
