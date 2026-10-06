import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/presentation/bloc/library_cubit.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_request.dart';
import '../bloc/download_queue_cubit.dart';
import '../bloc/download_settings_cubit.dart';
import 'playlist_picker_dialog.dart';

/// 받기 팝업: 제목 · 아티스트 · 장르를 고치고, 저장할 때 넣을 재생목록을 고른다.
/// "받기"를 누르면 대기열에 넣고 true를 돌려준다 (닫기만 하면 false).
Future<bool> showDownloadDialog(
  BuildContext context, {
  required String title,
  String artist = '',
  String genre = '',
  Quality quality = Quality.best,
}) async {
  final queue = context.read<DownloadQueueCubit>();
  final playlists = context.read<PlaylistsCubit>();
  final settings = context.read<DownloadSettingsCubit>();
  final library = context.read<LibraryCubit>();
  final started = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    isScrollControlled: true,
    // 탭 틀(미니 플레이어 · 탭 바) 위에 뜨도록 최상위 내비게이터에서 연다.
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: queue),
        BlocProvider.value(value: playlists),
        BlocProvider.value(value: settings),
        BlocProvider.value(value: library),
      ],
      child: _DownloadSheet(
        title: title,
        artist: artist,
        genre: genre,
        quality: quality,
      ),
    ),
  );
  return started ?? false;
}

class _DownloadSheet extends StatefulWidget {
  const _DownloadSheet({
    required this.title,
    required this.artist,
    required this.genre,
    required this.quality,
  });

  final String title;
  final String artist;
  final String genre;
  final Quality quality;

  @override
  State<_DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends State<_DownloadSheet> {
  late final _title = TextEditingController(text: widget.title);
  late final _artist = TextEditingController(text: widget.artist);
  late final _genre = TextEditingController(text: widget.genre);
  // 기본 저장 위치로 채워 시작하고, 이 곡만 바꿀 수 있다 (기본값은 설정에서).
  late final _savePath = TextEditingController(
    text: context.read<DownloadSettingsCubit>().state,
  );
  final Set<String> _selected = {};

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _genre.dispose();
    _savePath.dispose();
    super.dispose();
  }

  Future<void> _pickPlaylists() async {
    final picked = await showPlaylistPickerDialog(context, selected: _selected);
    if (picked == null || !mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(picked);
    });
  }

  Future<void> _pickFolder() async {
    final path = await context.read<DownloadSettingsCubit>().pickFolder();
    if (path != null && mounted) setState(() => _savePath.text = path);
  }

  Future<void> _start() async {
    final ok = await context.read<DownloadQueueCubit>().enqueue(
      DownloadRequest(
        title: _title.text,
        artist: _artist.text,
        genre: _genre.text,
        playlistIds: _selected,
        quality: widget.quality,
        savePath: _savePath.text,
      ),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        // 키보드가 올라오면 그만큼 띄운다.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.downloadDialogTitle, style: text.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: l10n.downloadFieldTitle, controller: _title),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: l10n.downloadFieldArtist,
                controller: _artist,
                hint: l10n.unknownArtist,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(label: l10n.downloadFieldGenre, controller: _genre),
              _GenreSuggestions(
                controller: _genre,
                label: l10n.downloadGenreExisting,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: l10n.downloadFieldSavePath,
                      controller: _savePath,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CircleIconButton(
                    icon: AppIcons.folderOpen,
                    tooltip: l10n.downloadPickFolder,
                    onPressed: _pickFolder,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.downloadPlaylistsLabel.toUpperCase(),
                style: text.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              _PlaylistPickRow(
                summary: _selected.isEmpty
                    ? l10n.downloadPlaylistsNone
                    : l10n.downloadPlaylistsSelected(_selected.length),
                onTap: _pickPlaylists,
              ),
              const SizedBox(height: AppSpacing.lg),
              ListenableBuilder(
                listenable: _title,
                builder: (_, _) => SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: l10n.actionDownload,
                    icon: AppIcons.download,
                    onPressed: _title.text.trim().isEmpty ? null : _start,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 팝업의 재생목록 줄: 고른 개수를 보여 주고, 누르면 고르는 대화상자를 연다.
class _PlaylistPickRow extends StatelessWidget {
  const _PlaylistPickRow({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: ShapeDecoration(
        color: p.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          side: BorderSide(color: p.outline),
        ),
      ),
      child: SettingRow(
        title: summary,
        onTap: onTap,
        trailing: Icon(AppIcons.chevronRight, color: p.onSurfaceMuted),
      ),
    );
  }
}

/// 보관함에 이미 있는 장르를 많은 순서로 보여 주고, 누르면 장르 칸을 그 장르로 채운다.
class _GenreSuggestions extends StatelessWidget {
  const _GenreSuggestions({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tracks = context.select((LibraryCubit c) => c.state).tracks;
    final counts = <String, int>{};
    for (final t in tracks) {
      final g = t.genre.trim();
      if (g.isNotEmpty) counts[g] = (counts[g] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final genres =
        (counts.keys.toList()..sort((a, b) {
              final byCount = counts[b]!.compareTo(counts[a]!);
              return byCount != 0 ? byCount : a.compareTo(b);
            }))
            .take(12)
            .toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.xs),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final g in genres)
                  PillButton(
                    label: g,
                    compact: true,
                    variant: PillVariant.tonal,
                    selected: controller.text.trim() == g,
                    onPressed: () => controller.text = g,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
