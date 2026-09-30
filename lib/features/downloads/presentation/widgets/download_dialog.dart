import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../playlists/presentation/bloc/playlists_cubit.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_request.dart';
import '../bloc/download_queue_cubit.dart';

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
  final _newPlaylist = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _genre.dispose();
    _newPlaylist.dispose();
    super.dispose();
  }

  Future<void> _createPlaylist() async {
    final made = await context.read<PlaylistsCubit>().create(_newPlaylist.text);
    if (made == null || !mounted) return;
    setState(() {
      _newPlaylist.clear();
      _selected.add(made.id);
    });
  }

  Future<void> _start() async {
    final ok = await context.read<DownloadQueueCubit>().enqueue(
      DownloadRequest(
        title: _title.text,
        artist: _artist.text,
        genre: _genre.text,
        playlistIds: _selected,
        quality: widget.quality,
      ),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final playlists = context.watch<PlaylistsCubit>().state;

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
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.downloadPlaylistsLabel.toUpperCase(),
                style: text.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              if (playlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    l10n.downloadPlaylistsEmpty,
                    style: text.bodyMedium?.copyWith(
                      color: context.palette.onSurfaceMuted,
                    ),
                  ),
                ),
              for (final pl in playlists)
                SettingRow(
                  title: pl.name,
                  description: l10n.songCount(pl.trackCount),
                  onTap: () => setState(() {
                    _selected.contains(pl.id)
                        ? _selected.remove(pl.id)
                        : _selected.add(pl.id);
                  }),
                  trailing: AppSwitch(
                    value: _selected.contains(pl.id),
                    onChanged: (v) => setState(() {
                      v ? _selected.add(pl.id) : _selected.remove(pl.id);
                    }),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: l10n.downloadNewPlaylist,
                      controller: _newPlaylist,
                      hint: l10n.downloadNewPlaylistHint,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createPlaylist(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  CircleIconButton(
                    icon: Icons.add_rounded,
                    tooltip: l10n.playlistsNew,
                    onPressed: _createPlaylist,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ListenableBuilder(
                listenable: _title,
                builder: (_, _) => SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: l10n.actionDownload,
                    icon: Icons.download_rounded,
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
