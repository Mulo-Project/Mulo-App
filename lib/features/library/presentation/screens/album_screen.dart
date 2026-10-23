import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../covers/presentation/widgets/decorate_sheet.dart';
import '../bloc/library_cubit.dart';
import '../widgets/play_shuffle_row.dart';
import '../widgets/lazy_track_list.dart';
import '../widgets/track_list_tile.dart';

/// 앨범 화면: 앨범에 속한 곡 목록과 전체 재생.
/// [album]은 곡에 저장된 앨범 이름 그대로이고, 빈 문자열이면 "알 수 없는 앨범"이다.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, required this.album});

  final String album;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final all = context.select((LibraryCubit c) => c.state).tracks;
    // 보관함 목록은 추가일 최신순이라서 앨범 안에서는 제목 순으로 보여 준다.
    final tracks = [
      for (final t in all)
        if (t.album == album) t,
    ]..sort((a, b) => a.title.compareTo(b.title));
    final name = album.isEmpty ? l10n.unknownAlbum : album;

    return SafeArea(
      bottom: false,
      child: LazyTrackList(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        header: [
          AppTopBar(
            title: name,
            leading: const AppBackButton(),
            actions: [
              if (tracks.isNotEmpty)
                CircleIconButton(
                  icon: AppIcons.edit,
                  tooltip: l10n.albumRenameTooltip,
                  onPressed: () => _rename(context),
                ),
              // 이 묶음의 곡을 모두 재생목록에 담는다 (곡 메뉴의 "재생목록에 추가"와 같은 화면).
              CircleIconButton(
                icon: AppIcons.playlistAdd,
                tooltip: l10n.trackMenuAddToPlaylist,
                onPressed: tracks.isEmpty
                    ? null
                    : () => context.push(
                        Routes.playlistPick,
                        extra: [for (final t in tracks) t.id],
                      ),
              ),
              CircleIconButton(
                icon: AppIcons.sparkle,
                tooltip: l10n.decorateAlbumTooltip,
                onPressed: () => showDecorateSheet(
                  context,
                  coverKey: CoverKey.album(album),
                  title: name,
                  tone: toneFor(name),
                  icon: AppIcons.album,
                ),
              ),
            ],
          ),
          if (tracks.isEmpty)
            Padding(
              padding: AppSpacing.screen,
              child: Text(
                l10n.albumNotFound,
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
                    radius: AppRadii.md,
                    image: coverImageOf(context, CoverKey.album(album)),
                    tone: toneFor(name),
                    color: coverColorOf(context, CoverKey.album(album)),
                    icon: AppIcons.album,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: text.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${artistOf(l10n, tracks.first)} · ${l10n.songCount(tracks.length)}',
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
          showAlbum: false,
        ),
      ),
    );
  }

  /// 앨범 이름 바꾸기: 곡들의 앨범을 고치고, 앨범에 붙인 이미지 · 색을 새 이름으로 옮긴다.
  Future<void> _rename(BuildContext context) async {
    final l10n = context.l10n;
    final library = context.read<LibraryCubit>();
    final covers = context.read<CoverCubit>();
    final colors = context.read<CoverColorCubit>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final to = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _RenameDialog(initial: album),
    );
    if (to == null || to.trim() == album) return;
    final newName = to.trim();
    final from = CoverKey.album(album);
    final dest = CoverKey.album(newName);
    final image = covers.state[from];
    final color = colors.state[from];
    final renamed = await library.renameAlbum(album, newName);
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
    router.pushReplacement(Routes.album(newName));
  }
}

/// 새 앨범 이름 입력. 저장하면 이름, 취소하면 null. 빈 이름은 알 수 없는 앨범이 된다.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

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
    return AppDialog(
      title: l10n.albumRenameTitle,
      content: AppTextField(
        label: l10n.albumRenameHint,
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
