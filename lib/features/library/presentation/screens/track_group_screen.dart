import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/decorate_sheet.dart';
import '../../domain/entities/track_group.dart';
import '../bloc/library_cubit.dart';
import '../widgets/lazy_track_list.dart';
import '../widgets/library_selection.dart';
import '../widgets/play_shuffle_row.dart';
import '../widgets/rename_progress.dart';
import '../widgets/track_list_tile.dart';

export '../../domain/entities/track_group.dart';

/// 상세 화면 ⋮ 메뉴의 동작.
enum _GroupAction { rename, decorate }

/// 아티스트 · 앨범 · 장르 화면: 그 묶음의 곡 목록과 전체 재생 · 셔플, 위 막대 ⋮ 메뉴에 이름 바꾸기 · 꾸미기.
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
                  // 이름 바꾸기 · 꾸미기는 버튼 하나(⋮)의 팝업 메뉴로 모은다 (제목 자리 확보).
                  // 장르는 이미지 · 색을 따로 꾸미지 않는다.
                  if (tracks.isNotEmpty || kind != TrackGroupKind.genre)
                    Builder(
                      builder: (menuContext) => CircleIconButton(
                        icon: AppIcons.more,
                        tooltip: l10n.actionMore,
                        onPressed: () async {
                          final action = await showAppMenu<_GroupAction>(
                            menuContext,
                            items: [
                              if (tracks.isNotEmpty)
                                AppMenuItem(
                                  value: _GroupAction.rename,
                                  icon: AppIcons.edit,
                                  label: _renameTooltip(l10n),
                                ),
                              if (kind != TrackGroupKind.genre)
                                AppMenuItem(
                                  value: _GroupAction.decorate,
                                  icon: AppIcons.sparkle,
                                  label: kind == TrackGroupKind.artist
                                      ? l10n.decorateArtistTooltip
                                      : l10n.decorateAlbumTooltip,
                                ),
                            ],
                          );
                          if (!context.mounted || action == null) return;
                          switch (action) {
                            case _GroupAction.rename:
                              _rename(context, tracks.length);
                            case _GroupAction.decorate:
                              showDecorateSheet(
                                context,
                                coverKey: key,
                                title: title,
                                tone: toneFor(title),
                                icon: _icon,
                              );
                          }
                        },
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
                const SizedBox(height: AppSpacing.sm),
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

  /// 이름 바꾸기: 묶음의 모든 곡의 그 정보를 고치고, 붙여 둔 이미지 · 색을 새 이름으로 옮긴다.
  /// 곡이 여러 곡이면 진행 대화상자를 보이고, 파일 태그에 못 쓴 곡이 있으면 안내한다.
  Future<void> _rename(BuildContext context, int count) async {
    final l10n = context.l10n;
    final library = context.read<LibraryCubit>();
    final covers = context.read<CoverCubit>();
    final colors = context.read<CoverColorCubit>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final to = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _RenameDialog(kind: kind, initial: name),
    );
    if (to == null || to.trim() == name || !context.mounted) return;
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

/// 새 이름 입력. 저장하면 이름, 취소하면 null. 빈 이름은 "알 수 없는 …"이 된다.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.kind, required this.initial});

  final TrackGroupKind kind;
  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_name.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, hint) = switch (widget.kind) {
      TrackGroupKind.artist => (l10n.artistRenameTitle, l10n.artistRenameHint),
      TrackGroupKind.album => (l10n.albumRenameTitle, l10n.albumRenameHint),
      TrackGroupKind.genre => (l10n.genreRenameTitle, l10n.genreRenameHint),
    };
    return AppDialog(
      title: title,
      content: AppTextField(
        label: hint,
        controller: _name,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(label: l10n.albumRenameSave, onPressed: _save),
      ],
    );
  }
}
