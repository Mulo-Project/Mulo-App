import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../bloc/playlists_cubit.dart';
import 'playlist_card.dart';

enum _Action { playAll, color, image, rename, delete }

enum _ImageAction { pick, reset }

/// 재생목록 팝업 메뉴: 전체 재생 · 색(하위 메뉴) · 이미지(하위 메뉴) · 이름 바꾸기 · 삭제.
/// 카드의 ⋮, 길게 누르기, 오른쪽 클릭, 상세 화면의 ⋮에서 같은 메뉴를 연다.
/// [globalPosition]이 있으면 눌린 자리에, 없으면 [context] 위젯 옆에 띄운다.
/// 좋아요 목록은 색 · 이름 · 삭제 항목이 없다.
Future<void> showPlaylistMenu(
  BuildContext context,
  Playlist pl, {
  Offset? globalPosition,
  VoidCallback? onDeleted,
}) async {
  final l10n = context.l10n;
  final hasImage = context.read<CoverCubit>().state.containsKey(
    CoverKey.playlist(pl.id),
  );
  final action = await showAppMenu<_Action>(
    context,
    globalPosition: globalPosition,
    items: [
      AppMenuItem(
        value: _Action.playAll,
        icon: Icons.play_arrow_rounded,
        label: l10n.playlistMenuPlayAll,
      ),
      // 색은 이미지가 없을 때만 카드에 보인다.
      if (!pl.isFavorites && !hasImage)
        AppMenuItem(
          value: _Action.color,
          icon: Icons.palette_rounded,
          label: l10n.playlistMenuColor,
        ),
      AppMenuItem(
        value: _Action.image,
        icon: Icons.image_rounded,
        label: l10n.playlistMenuImage,
      ),
      if (!pl.isFavorites) ...[
        AppMenuItem(
          value: _Action.rename,
          icon: Icons.edit_rounded,
          label: l10n.playlistMenuRename,
        ),
        AppMenuItem(
          value: _Action.delete,
          icon: Icons.delete_outline_rounded,
          label: l10n.playlistMenuDelete,
          destructive: true,
          dividerBefore: true,
        ),
      ],
    ],
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _Action.playAll:
      await _playAll(context, pl);
    case _Action.color:
      await _pickColor(context, pl, globalPosition);
    case _Action.image:
      await _pickImage(context, pl, hasImage, globalPosition);
    case _Action.rename:
      await _rename(context, pl);
    case _Action.delete:
      await _delete(context, pl, onDeleted);
  }
}

Future<void> _playAll(BuildContext context, Playlist pl) async {
  final tracks = await context.read<PlaylistsCubit>().tracksOf(pl.id);
  if (!context.mounted) return;
  if (tracks.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.playlistPlayEmpty)));
    return;
  }
  context.read<NowPlayingCubit>().playQueue(tracks);
}

/// 색 하위 메뉴: 색 견본 아이콘 + 이름. 자동은 새로고침 아이콘.
Future<void> _pickColor(
  BuildContext context,
  Playlist pl,
  Offset? globalPosition,
) async {
  final l10n = context.l10n;
  final tokens = context.tokens;
  const auto = -1;
  final picked = await showAppMenu<int>(
    context,
    globalPosition: globalPosition,
    items: [
      AppMenuItem(
        value: auto,
        icon: Icons.autorenew_rounded,
        label: l10n.playlistColorAuto,
        selected: pl.colorIndex == null,
      ),
      for (final tone in GlowTone.values)
        AppMenuItem(
          value: tone.index,
          icon: Icons.circle,
          iconColor: tokens.glow(tone).first,
          label: playlistToneName(l10n, tone),
          selected: pl.colorIndex == tone.index,
        ),
    ],
  );
  if (picked == null || !context.mounted) return;
  await context.read<PlaylistsCubit>().setColor(
    pl.id,
    picked == auto ? null : picked,
  );
}

/// 이미지 하위 메뉴: 사진에서 고르기 · (이미지가 있으면) 기본 이미지로.
Future<void> _pickImage(
  BuildContext context,
  Playlist pl,
  bool hasImage,
  Offset? globalPosition,
) async {
  final l10n = context.l10n;
  final covers = context.read<CoverCubit>();
  final action = await showAppMenu<_ImageAction>(
    context,
    globalPosition: globalPosition,
    items: [
      AppMenuItem(
        value: _ImageAction.pick,
        icon: Icons.photo_library_rounded,
        label: l10n.playlistImagePick,
      ),
      if (hasImage)
        AppMenuItem(
          value: _ImageAction.reset,
          icon: Icons.restart_alt_rounded,
          label: l10n.playlistImageReset,
        ),
    ],
  );
  switch (action) {
    case _ImageAction.pick:
      await covers.pickFromDevice(CoverKey.playlist(pl.id));
    case _ImageAction.reset:
      await covers.clear(CoverKey.playlist(pl.id));
    case null:
      break;
  }
}

Future<void> _rename(BuildContext context, Playlist pl) async {
  final cubit = context.read<PlaylistsCubit>();
  final name = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _RenameDialog(initial: pl.name),
  );
  if (name == null) return;
  await cubit.rename(pl.id, name);
}

Future<void> _delete(
  BuildContext context,
  Playlist pl,
  VoidCallback? onDeleted,
) async {
  final l10n = context.l10n;
  final cubit = context.read<PlaylistsCubit>();
  final covers = context.read<CoverCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _DeleteDialog(name: pl.name),
  );
  if (ok != true) return;
  await cubit.delete(pl.id);
  await covers.clear(CoverKey.playlist(pl.id));
  messenger.showSnackBar(SnackBar(content: Text(l10n.playlistDeleted)));
  onDeleted?.call();
}

/// 새 이름 입력. 저장하면 이름, 취소하면 null.
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

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(_name.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      backgroundColor: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.playlistRenameTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.playlistNewHint,
              controller: _name,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(label: l10n.playlistRenameSave, onPressed: _save),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: l10n.actionCancel,
              variant: PillVariant.tonal,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: context.palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.playlistDeleteTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.playlistDeleteBody(name), style: text.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: l10n.playlistDeleteConfirm,
              icon: Icons.delete_outline_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: l10n.actionCancel,
              variant: PillVariant.tonal,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
