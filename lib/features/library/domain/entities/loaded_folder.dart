import 'track.dart';

/// 음악을 불러오는 폴더 하나와 그 안의 곡 수.
class LoadedFolder {
  const LoadedFolder({
    required this.path,
    required this.trackCount,
    this.isDefault = false,
  });

  final String path;
  final int trackCount;

  /// 기본 저장 위치 (삭제 불가).
  final bool isDefault;
}

/// 보관함에 보일 곡인지: 불러오는 폴더([roots]) 안에 있어야 한다.
/// 폴더를 모르는 곡(빈 값)은 판단할 수 없어 보인다.
bool isVisibleInLibrary(Track track, Iterable<String> roots) =>
    track.folder.isEmpty || roots.any((r) => isInsideFolder(track.folder, r));

/// 폴더 경로 맞추기: 끝의 구분자를 없애고 `\`는 `/`로 바꾼다.
String normalizeFolderPath(String path) {
  final p = path.trim().replaceAll(r'\', '/');
  return p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p;
}

/// [path]가 [folder] 안(같은 폴더 또는 하위 폴더)에 있는지.
bool isInsideFolder(String path, String folder) {
  final p = normalizeFolderPath(path);
  final f = normalizeFolderPath(folder);
  if (f.isEmpty) return false;
  return p == f || p.startsWith(f.endsWith('/') ? f : '$f/');
}

/// [folder] 안(하위 폴더 포함)에 있는 곡 수.
int countTracksIn(String folder, Iterable<Track> tracks) =>
    tracks.where((t) => isInsideFolder(t.folder, folder)).length;
