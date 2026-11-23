import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../domain/entities/track_group.dart';
import '../bloc/library_cubit.dart';
import '../widgets/lazy_track_list.dart';
import '../widgets/library_selection.dart';
import '../widgets/play_shuffle_row.dart';
import '../widgets/rename_progress.dart';
import 'collection_info_screen.dart';
import '../widgets/track_list_tile.dart';

export '../../domain/entities/track_group.dart';

/// 아티스트 · 앨범 · 장르 화면: 그 묶음의 곡 목록과 전체 재생 · 셔플, 위 막대 ⋮ 메뉴의 "정보"(큰 이미지 · 이름 바꾸기 · 색).
/// 세 화면은 모양이 같고 이름 · 아이콘 · 문구만 다르다 ([TrackGroupKind]).
/// [name]은 곡에 저장된 값 그대로이고, 빈 문자열이면 "알 수 없는 …"이다.
class TrackGroupScreen extends StatefulWidget {
  const TrackGroupScreen({super.key, required this.kind, required this.name});

  final TrackGroupKind kind;
  final String name;

  @override
  State<TrackGroupScreen> createState() => _TrackGroupScreenState();
}

class _TrackGroupScreenState extends State<TrackGroupScreen>
    with TrackPicker<TrackGroupScreen> {
  TrackGroupKind get kind => widget.kind;
  String get name => widget.name;

  String _title(AppLocalizations l10n) => switch (kind) {
    TrackGroupKind.artist => name.isEmpty ? l10n.unknownArtist : name,
    TrackGroupKind.album => name.isEmpty ? l10n.unknownAlbum : name,
    TrackGroupKind.genre => genreOf(l10n, name),
  };

  String _notFound(AppLocalizations l10n) => switch (kind) {
    TrackGroupKind.artist => l10n.artistNotFound,
    TrackGroupKind.album => l10n.albumNotFound,
    TrackGroupKind.genre => l10n.genreNotFound,
  };

  String _coverKey(String value) => switch (kind) {
    TrackGroupKind.artist => CoverKey.artist(value),
    TrackGroupKind.album => CoverKey.album(value),
    TrackGroupKind.genre => CoverKey.genre(value),
  };

  IconData get _icon => switch (kind) {
    TrackGroupKind.artist => AppIcons.person,
    TrackGroupKind.album => AppIcons.album,
    TrackGroupKind.genre => AppIcons.category,
  };

  String _route(String value) => switch (kind) {
    TrackGroupKind.artist => Routes.artist(value),
    TrackGroupKind.album => Routes.album(value),
    TrackGroupKind.genre => Routes.genre(value),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final all = context.select((LibraryCubit c) => c.state).tracks;
    // 보관함 목록은 추가일 최신순이라서 묶음 안에서는 제목 순으로 보여 준다.
    final tracks = [
      for (final t in all)
        if (kind.contains(t, name)) t,
    ]..sort((a, b) => a.title.compareTo(b.title));
    final title = _title(l10n);
    final key = _coverKey(name);
    // 아티스트는 동그란 이미지, 나머지는 둥근 네모.
    final radius = kind == TrackGroupKind.artist ? 48.0 : AppRadii.md;
    final subtitle = switch (kind) {
      TrackGroupKind.album when tracks.isNotEmpty =>
        '${artistOf(l10n, tracks.first)} · ${l10n.songCount(tracks.length)}',
      _ => l10n.songCount(tracks.length),
    };

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          LazyTrackList(
            padding: EdgeInsets.only(
              bottom:
                  AppSpacing.lg +
                  MediaQuery.paddingOf(context).bottom +
                  selectionBottomGap,
            ),
            header: [
              AppTopBar(
                title: title,
                leading: const AppBackButton(),
                actions: [
                  // 이미지 · 색 · 이름 바꾸기는 "정보" 화면 하나에서 한다.
                  if (tracks.isNotEmpty)
                    CircleIconButton(
                      icon: AppIcons.info,
                      tooltip: l10n.collectionMenuInfo,
                      onPressed: () => _openInfo(
                        context,
                        title: title,
                        key: key,
                        subtitle: subtitle,
                        count: tracks.length,
                        circle: kind == TrackGroupKind.artist,
                      ),
                    ),
                ],
              ),
              if (tracks.isEmpty)
                Padding(
                  padding: AppSpacing.screen,
                  child: Text(
                    _notFound(l10n),
                    style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                  ),
                )
              else ...[
                Padding(
                  padding: AppSpacing.screen,
                  child: Row(
                    children: [
                      ArtworkBox(
                        size: 96,
                        radius: radius,
                        image: coverImageOf(context, key),
                        tone: toneFor(title),
                        color: coverColorOf(context, key),
                        icon: _icon,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: text.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: text.bodyMedium?.copyWith(
                                color: p.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PlayShuffleRow(tracks: tracks),
                // 위 소개 영역과 곡 목록을 가는 선과 넉넉한 간격으로 나눈다.
                const SizedBox(height: AppSpacing.md),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: AppDivider(),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
            trackCount: tracks.length,
            trackBuilder: (context, i) => TrackListTile(
              track: tracks[i],
              queue: tracks,
              index: i,
              // 앨범 화면에서는 줄마다 앨범 이름을 다시 쓰지 않는다.
              showAlbum: kind != TrackGroupKind.album,
              selection: selectionFor(tracks[i]),
            ),
          ),
          // 하나라도 고르면 하단에 선택 막대가 올라온다.
          ?selectionBar(all, tracks),
        ],
      ),
    );
  }

  String _renameTooltip(AppLocalizations l10n) => switch (kind) {
    TrackGroupKind.artist => l10n.artistRenameTooltip,
    TrackGroupKind.album => l10n.albumRenameTooltip,
    TrackGroupKind.genre => l10n.genreRenameTooltip,
  };

  /// 정보 화면을 열고, 이름을 바꿨으면 이어서 이름 바꾸기를 한다.
  Future<void> _openInfo(
    BuildContext context, {
    required String title,
    required String key,
    required String subtitle,
    required int count,
    required bool circle,
  }) async {
    final l10n = context.l10n;
    final to = await showCollectionInfo(
      context,
      screenTitle: switch (kind) {
        TrackGroupKind.artist => l10n.artistInfoTitle,
        TrackGroupKind.album => l10n.albumInfoTitle,
        TrackGroupKind.genre => l10n.genreInfoTitle,
      },
      title: title,
      subtitle: subtitle,
      nameLabel: _renameTooltip(l10n),
      coverKey: key,
      tone: toneFor(title),
      icon: _icon,
      circle: circle,
      allowEmptyName: true,
      initialName: name,
    );
    if (to == null || !context.mounted) return;
    await _rename(context, to, count);
  }

  /// 이름 바꾸기: 묶음의 모든 곡의 그 정보를 고치고, 붙여 둔 이미지 · 색을 새 이름으로 옮긴다.
  /// 곡이 여러 곡이면 진행 대화상자를 보이고, 파일 태그에 못 쓴 곡이 있으면 안내한다.
  Future<void> _rename(BuildContext context, String to, int count) async {
    final l10n = context.l10n;
    final library = context.read<LibraryCubit>();
    final covers = context.read<CoverCubit>();
    final colors = context.read<CoverColorCubit>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (to.trim() == name) return;
    final newName = to.trim();
    final from = _coverKey(name);
    final dest = _coverKey(newName);
    final image = covers.state[from];
    final color = colors.state[from];
    // 곡이 몇 곡 안 되면 금방 끝나므로 진행 대화상자 없이 바로 한다.
    final renamed = count >= 4
        ? await showProgressWhile(
            context,
            task: (report) =>
                library.renameGroup(kind, name, newName, onProgress: report),
          )
        : await library.renameGroup(kind, name, newName);
    // 합치는 경우(새 이름에 이미 설정이 있으면)에는 그쪽을 남긴다.
    if (image != null && !covers.state.containsKey(dest)) {
      await covers.setArt(dest, image);
    }
    if (color != null && !colors.state.containsKey(dest)) {
      await colors.setColor(dest, Color(color));
    }
    await covers.clear(from);
    await colors.clear(from);
    // 제목이 바뀐 화면으로 가므로 성공 안내는 없고, 파일에 못 쓴 때만 알린다.
    if (renamed.failed > 0) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.trackEditTagFailed)));
    }
    router.pushReplacement(_route(newName));
  }
}
