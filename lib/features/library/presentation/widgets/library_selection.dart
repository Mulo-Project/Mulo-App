import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_color_cubit.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../lyrics/presentation/bloc/lyrics_cubit.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/track_group.dart';
import '../../../player/presentation/bloc/now_playing_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import 'track_list_tile.dart' show TrackSelection;
import '../bloc/library_cubit.dart';
import 'rename_progress.dart';

/// 선택 모드에서 고를 수 있는 일괄 작업.
enum SelectionAction {
  selectAll,
  playNext,
  addToQueue,
  addToPlaylist,
  removeFromPlaylist,
  removeFromQueue,
  album,
  artist,
  genre,
  delete,
}

/// 보관함 선택 모드 하단 막대: 닫기 · 선택 수 · "작업" 버튼.
/// "작업"을 누르면 [showSelectionActionSheet]로 복수 작업 목록을 띄운다.
class LibrarySelectionBottomBar extends StatelessWidget {
  const LibrarySelectionBottomBar({
    super.key,
    required this.count,
    required this.onClose,
    required this.onActions,
    this.countLabel,
  });

  final int count;

  /// 선택 수 글(비우면 "N곡 선택"). 곡이 아닌 것을 고르는 화면이 바꾼다.
  final String? countLabel;
  final VoidCallback onClose;
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
                countLabel ?? l10n.selectCount(count),
                style: text.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
  int count, {
  required bool allPicked,
  bool inPlaylist = false,
  bool inQueue = false,
  bool canSelectAll = true,
  bool editable = true,
}) {
  final l10n = context.l10n;
  return showAppSheet<SelectionAction>(
    context,
    builder: (sheet) {
      void pick(SelectionAction a) => Navigator.of(sheet).pop(a);
      // 항목이 많아 시트 높이(화면의 9/16)를 넘으면 잘려 보이지 않으므로 스크롤되게 한다.
      return SafeArea(
        child: SingleChildScrollView(
          padding: appSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetTitle(l10n.selectCount(count)),
              const SizedBox(height: AppSpacing.xs),
              if (canSelectAll && !allPicked)
                MenuRow(
                  icon: AppIcons.checkCircle,
                  label: l10n.newVideosSelectAll,
                  onTap: () => pick(SelectionAction.selectAll),
                ),
              if (!inQueue)
                MenuRow(
                  icon: AppIcons.playlistPlay,
                  label: l10n.trackMenuPlayNext,
                  onTap: () => pick(SelectionAction.playNext),
                ),
              if (!inQueue)
                MenuRow(
                  icon: AppIcons.queue,
                  label: l10n.trackMenuAddToQueue,
                  onTap: () => pick(SelectionAction.addToQueue),
                ),
              MenuRow(
                icon: AppIcons.playlistAdd,
                label: l10n.trackMenuAddToPlaylist,
                onTap: () => pick(SelectionAction.addToPlaylist),
              ),
              if (inPlaylist)
                MenuRow(
                  icon: AppIcons.playlistRemove,
                  label: l10n.trackMenuRemoveFromPlaylist,
                  onTap: () => pick(SelectionAction.removeFromPlaylist),
                ),
              if (inQueue)
                MenuRow(
                  icon: AppIcons.playlistRemove,
                  label: l10n.trackMenuRemoveFromQueue,
                  onTap: () => pick(SelectionAction.removeFromQueue),
                ),
              if (editable) ...[
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
                MenuRow(
                  icon: AppIcons.delete,
                  label: l10n.selectDelete,
                  onTap: () => pick(SelectionAction.delete),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// 고른 곡의 음악 파일과 보관함 기록을 한 번에 지운다 (확인을 받은 뒤).
/// 지운 곡이 하나라도 있으면 true. 못 지운 곡(권한 거절 등)은 기록을 그대로 두고 개수를 알린다.
Future<bool> deleteSelection(BuildContext context, List<Track> tracks) async {
  if (tracks.isEmpty) return false;
  final l10n = context.l10n;
  final library = context.read<LibraryCubit>();
  final player = context.read<NowPlayingCubit>();
  final covers = context.read<CoverCubit>();
  final colors = context.read<CoverColorCubit>();
  final lyrics = context.read<LyricsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialog) => AppDialog(
      title: l10n.trackDeleteTitle,
      body: l10n.selectDeleteBody(tracks.length),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(dialog).pop(false),
        ),
        PillButton(
          label: l10n.trackDeleteConfirm,
          icon: AppIcons.delete,
          onPressed: () => Navigator.of(dialog).pop(true),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  // 파일부터 한꺼번에 지운다 (삭제 동의 창은 한 번만). 못 지운 곡은 기록을 그대로 둔다.
  final deleted = await library.deleteAll(tracks);
  for (final track in tracks) {
    if (!deleted.contains(track.id)) continue;
    await covers.clear(CoverKey.track(track.id));
    await colors.clear(CoverKey.track(track.id));
    await lyrics.clear(track.id);
    player.removeFromQueue(track);
  }
  final failed = tracks.length - deleted.length;
  if (failed > 0) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.selectDeleteFailed(failed))),
    );
  }
  return failed < tracks.length;
}

/// 고른 곡 [ids]에 앨범 · 아티스트 · 장르([kind])를 한 번에 지정한다.
/// 값을 적고 → "고른 N곡의 앨범이 A로 바뀌어요" 확인을 받은 뒤 → 곡마다 파일 태그를 먼저 쓰고 DB를 고친다 (D-120).
/// 실제로 적용했으면 true, 취소했으면 false. 태그를 못 쓴 곡은 바꾸지 않고 안내한다.
Future<bool> assignToSelection(
  BuildContext context, {
  required TrackGroupKind kind,
  required Set<String> ids,
  String initial = '',
}) async {
  final l10n = context.l10n;
  final library = context.read<LibraryCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final value = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _AssignDialog(kind: kind, initial: initial),
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
  const _AssignDialog({required this.kind, required this.initial});

  final TrackGroupKind kind;

  /// 처음 채워 둘 값 (앨범 화면에서 앨범 지정이면 그 앨범 이름).
  final String initial;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  late final _value = TextEditingController(text: widget.initial);

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
          Text(switch (widget.kind) {
            TrackGroupKind.artist => l10n.selectAssignHintArtist,
            TrackGroupKind.album => l10n.selectAssignHintAlbum,
            TrackGroupKind.genre => l10n.selectAssignHintGenre,
          }, style: Theme.of(context).textTheme.bodySmall),
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
        PillButton(label: l10n.selectNext, onPressed: _next),
      ],
    );
  }
}

/// 곡 목록 화면의 여러 곡 선택 상태 · 동작 (보관함 곡 탭, 앨범 · 아티스트 · 장르 화면이 같이 쓴다).
/// 길게 눌러 하나라도 고르면 선택 모드이고, [selectionBar]가 하단 막대를 만든다.
mixin TrackPicker<T extends StatefulWidget> on State<T> {
  /// 고른 곡 id. 비어 있지 않으면 선택 모드.
  final picked = <String>{};

  bool get selecting => picked.isNotEmpty;

  void togglePick(String id) => setState(() {
    picked.contains(id) ? picked.remove(id) : picked.add(id);
  });

  void clearPicked() => setState(picked.clear);

  /// 고른 곡 id (목록에서 사라진 곡은 뺀다). [all]에 같은 곡이 여러 번 있어도(홈은 구역마다 곡이 겹친다) 한 번만 센다.
  List<String> pickedIds(List<Track> all) => [
    for (final t in pickedTracks(all)) t.id,
  ];

  /// 고른 곡 (목록 순서, 같은 곡은 한 번만).
  List<Track> pickedTracks(List<Track> all) {
    final seen = <String>{};
    return [
      for (final t in all)
        if (picked.contains(t.id) && seen.add(t.id)) t,
    ];
  }

  bool allPicked(List<Track> shown) =>
      shown.isNotEmpty && shown.every((t) => picked.contains(t.id));

  /// 곡 줄에 넘길 선택 상태.
  TrackSelection selectionFor(Track t) => TrackSelection(
    active: selecting,
    selected: picked.contains(t.id),
    onToggle: () => togglePick(t.id),
  );

  /// 하단 선택 막대 (선택 모드가 아니면 null). 탭 틀 · 시스템 바 위에 뜨도록 아래 여백을 더한다.
  Widget? selectionBar(List<Track> all, List<Track> shown) {
    if (!selecting) return null;
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
      child: LibrarySelectionBottomBar(
        count: picked.length,
        onClose: clearPicked,
        onActions: () => _runActions(all, shown),
      ),
    );
  }

  /// 재생목록 안의 곡 목록이면 그 재생목록 id (작업 시트에 "재생목록에서 빼기"가 더해진다).
  String? get pickerPlaylistId => null;

  /// 재생 대기열 화면이면 true (작업 시트에 "대기열에서 빼기"가 더해진다).
  bool get pickerInQueue => false;

  /// 작업 시트에 "전체 선택"을 둘지 (여러 구역이 한 화면에 있는 홈은 끈다).
  bool get pickerCanSelectAll => true;

  /// 작업 시트에 앨범 · 아티스트 · 장르 지정을 둘지 (읽기 전용 목록은 끈다).
  bool get pickerEditable => true;

  /// 묶음(아티스트 · 앨범 · 장르 줄) 하나의 곡을 모두 고르거나, 이미 모두 골랐으면 모두 푼다.
  void toggleGroup(List<Track> tracks) => setState(() {
    final ids = tracks.map((t) => t.id);
    if (ids.every(picked.contains)) {
      picked.removeAll(ids);
    } else {
      picked.addAll(ids);
    }
  });

  /// 묶음의 곡이 모두 골라져 있는가.
  bool groupPicked(List<Track> tracks) =>
      tracks.every((t) => picked.contains(t.id));

  /// 목록 맨 아래에 비워 둘 높이 (선택 막대에 마지막 곡이 가리지 않게).
  /// 값 입력창에 처음 채워 둘 값: 고른 곡들의 [kind] 값이 모두 같으면 그 값, 다르면 빈 칸.
  String initialAssignValue(List<Track> all, TrackGroupKind kind) {
    final values = {
      for (final t in all)
        if (picked.contains(t.id)) kind.valueOf(t),
    };
    return values.length == 1 ? values.first : '';
  }

  double get selectionBottomGap => selecting ? 72 : 0;

  /// 복수 작업 시트를 띄우고 고른 작업을 한다.
  Future<void> _runActions(List<Track> all, List<Track> shown) async {
    final ids = pickedIds(all);
    final action = await showSelectionActionSheet(
      context,
      ids.length,
      allPicked: allPicked(shown),
      inPlaylist: pickerPlaylistId != null,
      inQueue: pickerInQueue,
      canSelectAll: pickerCanSelectAll,
      editable: pickerEditable,
    );
    if (action == null || !mounted) return;
    if (action != SelectionAction.selectAll && ids.isEmpty) return;
    switch (action) {
      case SelectionAction.selectAll:
        setState(() => picked.addAll(shown.map((t) => t.id)));
      case SelectionAction.playNext:
        // 고른 곡들이 목록에 보이는 순서대로 지금 곡 바로 뒤에 들어간다.
        context.read<NowPlayingCubit>().playAllNext(pickedTracks(all));
        clearPicked();
      case SelectionAction.addToQueue:
        // 고른 순서가 아니라 목록에 보이는 순서대로 붙는다.
        context.read<NowPlayingCubit>().addAllToQueue(pickedTracks(all));
        clearPicked();
      case SelectionAction.addToPlaylist:
        await context.push(Routes.playlistPick, extra: ids);
      case SelectionAction.removeFromPlaylist:
        final playlists = context.read<PlaylistsCubit>();
        for (final id in ids) {
          await playlists.removeTrack(id, pickerPlaylistId!);
        }
        if (mounted) clearPicked();
      case SelectionAction.removeFromQueue:
        context.read<NowPlayingCubit>().removeFromQueueByIds(ids.toSet());
        clearPicked();
      case SelectionAction.album ||
          SelectionAction.artist ||
          SelectionAction.genre:
        final kind = switch (action) {
          SelectionAction.album => TrackGroupKind.album,
          SelectionAction.artist => TrackGroupKind.artist,
          _ => TrackGroupKind.genre,
        };
        final done = await assignToSelection(
          context,
          kind: kind,
          ids: ids.toSet(),
          initial: initialAssignValue(all, kind),
        );
        if (done && mounted) clearPicked();
      case SelectionAction.delete:
        final deleted = await deleteSelection(context, pickedTracks(all));
        if (deleted && mounted) clearPicked();
    }
  }
}
