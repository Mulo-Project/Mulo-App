import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/track_group.dart';
import '../bloc/library_cubit.dart';
import 'rename_progress.dart';

/// 선택 모드에서 고를 수 있는 일괄 작업.
enum SelectionAction { addToPlaylist, album, artist, genre }

/// 보관함 선택 모드 하단 막대: 닫기 · 선택 수 · 모두 선택 / 해제 · "작업" 버튼.
/// "작업"을 누르면 [showSelectionActionSheet]로 복수 작업 목록을 띄운다.
class LibrarySelectionBottomBar extends StatelessWidget {
  const LibrarySelectionBottomBar({
    super.key,
    required this.count,
    required this.allPicked,
    required this.onClose,
    required this.onToggleAll,
    required this.onActions,
  });

  final int count;
  final bool allPicked;
  final VoidCallback onClose;
  final VoidCallback onToggleAll;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return GlassSurface(
      solid: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            CircleIconButton(
              icon: AppIcons.close,
              tooltip: l10n.selectClose,
              onPressed: onClose,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.selectCount(count),
                style: text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CircleIconButton(
              icon: allPicked ? AppIcons.radioOff : AppIcons.checkCircle,
              tooltip: allPicked
                  ? l10n.newVideosSelectNone
                  : l10n.newVideosSelectAll,
              onPressed: onToggleAll,
            ),
            const SizedBox(width: AppSpacing.xs),
            PillButton(
              label: l10n.selectActions,
              icon: AppIcons.more,
              compact: true,
              onPressed: onActions,
            ),
          ],
        ),
      ),
    );
  }
}

/// 고른 곡에 할 일 목록 바텀 시트. 항목을 누르면 시트를 닫고 그 작업을 돌려준다.
Future<SelectionAction?> showSelectionActionSheet(
  BuildContext context,
  int count,
) {
  final l10n = context.l10n;
  return showAppSheet<SelectionAction>(
    context,
    builder: (sheet) {
      void pick(SelectionAction a) => Navigator.of(sheet).pop(a);
      return SafeArea(
        child: Padding(
          padding: appSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetTitle(l10n.selectCount(count)),
              const SizedBox(height: AppSpacing.xs),
              MenuRow(
                icon: AppIcons.playlistAdd,
                label: l10n.trackMenuAddToPlaylist,
                onTap: () => pick(SelectionAction.addToPlaylist),
              ),
              MenuRow(
                icon: AppIcons.album,
                label: l10n.selectAssignAlbum,
                onTap: () => pick(SelectionAction.album),
              ),
              MenuRow(
                icon: AppIcons.person,
                label: l10n.selectAssignArtist,
                onTap: () => pick(SelectionAction.artist),
              ),
              MenuRow(
                icon: AppIcons.category,
                label: l10n.selectAssignGenre,
                onTap: () => pick(SelectionAction.genre),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 고른 곡 [ids]에 앨범 · 아티스트 · 장르([kind])를 한 번에 지정한다.
/// 값을 적고 → "고른 N곡의 앨범이 A로 바뀌어요" 확인을 받은 뒤 → 곡마다 파일 태그를 먼저 쓰고 DB를 고친다 (D-120).
/// 실제로 적용했으면 true, 취소했으면 false. 태그를 못 쓴 곡은 바꾸지 않고 안내한다.
Future<bool> assignToSelection(
  BuildContext context, {
  required TrackGroupKind kind,
  required Set<String> ids,
}) async {
  final l10n = context.l10n;
  final library = context.read<LibraryCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final value = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _AssignDialog(kind: kind),
  );
  if (value == null || !context.mounted) return false;
  final name = value.trim();
  final shown = name.isEmpty ? _unknownOf(l10n, kind) : name;
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialog) => AppDialog(
      title: _titleOf(l10n, kind),
      body: _confirmOf(l10n, kind, ids.length, shown),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(dialog).pop(false),
        ),
        PillButton(
          label: l10n.selectConfirmApply,
          onPressed: () => Navigator.of(dialog).pop(true),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  // 곡이 몇 곡 안 되면 금방 끝나므로 진행 대화상자 없이 바로 한다.
  final result = ids.length >= 4
      ? await showProgressWhile(
          context,
          task: (report) =>
              library.assignGroup(ids, kind, name, onProgress: report),
        )
      : await library.assignGroup(ids, kind, name);
  if (result.failed > 0) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.selectAssignPartial(result.failed))),
    );
  }
  return true;
}

String _unknownOf(AppLocalizations l10n, TrackGroupKind kind) => switch (kind) {
  TrackGroupKind.artist => l10n.unknownArtist,
  TrackGroupKind.album => l10n.unknownAlbum,
  TrackGroupKind.genre => l10n.unknownGenre,
};

String _titleOf(AppLocalizations l10n, TrackGroupKind kind) => switch (kind) {
  TrackGroupKind.artist => l10n.selectAssignArtistTitle,
  TrackGroupKind.album => l10n.selectAssignAlbumTitle,
  TrackGroupKind.genre => l10n.selectAssignGenreTitle,
};

String _confirmOf(
  AppLocalizations l10n,
  TrackGroupKind kind,
  int count,
  String value,
) => switch (kind) {
  TrackGroupKind.artist => l10n.selectConfirmArtist(count, value),
  TrackGroupKind.album => l10n.selectConfirmAlbum(count, value),
  TrackGroupKind.genre => l10n.selectConfirmGenre(count, value),
};

/// 지정할 값 입력. 누르면 값, 취소하면 null. 비워 두면 "알 수 없는 …"이 된다.
class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.kind});

  final TrackGroupKind kind;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  final _value = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _next() => Navigator.of(context).pop(_value.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (widget.kind) {
      TrackGroupKind.artist => l10n.trackEditArtist,
      TrackGroupKind.album => l10n.trackEditAlbum,
      TrackGroupKind.genre => l10n.trackEditGenre,
    };
    return AppDialog(
      title: _titleOf(l10n, widget.kind),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.selectAssignHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: label,
            controller: _value,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _next(),
          ),
        ],
      ),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(label: l10n.selectConfirmApply, onPressed: _next),
      ],
    );
  }
}
