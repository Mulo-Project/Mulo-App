import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../covers/presentation/bloc/cover_cubit.dart';
import '../../../library/domain/entities/track.dart' show formatDuration;
import '../../../search/domain/entities/engine_exception.dart';
import '../../../search/domain/entities/media_info.dart';
import '../bloc/playlist_import_cubit.dart';

/// 유튜브 재생목록 가져오기 (상세 기능: 유튜브 재생목록 가져오기 #22).
/// 재생목록 주소를 넣으면 곡 목록이 나오고, 받을 곡을 고르면(처음에는 모두 선택)
/// 같은 이름의 새 재생목록을 만들어 대기열에 넣는다. 대표 이미지가 재생목록 커버가 된다.
class PlaylistImportScreen extends StatefulWidget {
  const PlaylistImportScreen({super.key, this.initialUrl = ''});

  final String initialUrl;

  @override
  State<PlaylistImportScreen> createState() => _PlaylistImportScreenState();
}

class _PlaylistImportScreenState extends State<PlaylistImportScreen> {
  late final _controller = TextEditingController(text: widget.initialUrl);
  late final PlaylistImportCubit _cubit = sl<PlaylistImportCubit>();
  var _starting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl.trim().isNotEmpty) _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cubit.close();
    super.dispose();
  }

  void _load() => _cubit.load(_controller.text);

  Future<void> _start() async {
    if (_starting) return;
    final l10n = context.l10n;
    final covers = context.read<CoverCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _starting = true);
    final result = await _cubit.start();
    if (result == null) {
      if (mounted) setState(() => _starting = false);
      return;
    }
    final thumb = result.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) {
      await covers.setFromUrl(CoverKey.playlist(result.playlistId), thumb);
    }
    router.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.skipped == 0
              ? l10n.playlistImportStarted(result.queued)
              : l10n.playlistImportStartedSkipped(
                  result.queued,
                  result.skipped,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: BlocProvider.value(
            value: _cubit,
            child: Column(
              children: [
                AppTopBar(
                  title: l10n.playlistsImport,
                  leading: CircleIconButton(
                    icon: AppIcons.back,
                    tooltip: l10n.actionBack,
                    onPressed: () => context.pop(),
                  ),
                ),
                Padding(
                  padding: AppSpacing.screen,
                  child: AppSearchField(
                    controller: _controller,
                    hint: l10n.playlistImportHint,
                    clearTooltip: l10n.actionClear,
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: _Body(onRetry: _load)),
                _Footer(starting: _starting, onStart: _start),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<PlaylistImportCubit>().state;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    Widget message(String title, String body, {Widget? action}) => Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action,
            ],
          ],
        ),
      ),
    );

    switch (state.status) {
      case PlaylistImportStatus.idle:
        return message(
          l10n.playlistImportEmptyTitle,
          l10n.playlistImportEmptyBody,
        );
      case PlaylistImportStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PlaylistImportStatus.failed:
        if (state.notPlaylist) {
          return message(
            l10n.playlistImportNotPlaylistTitle,
            l10n.playlistImportNotPlaylistBody,
          );
        }
        return message(
          l10n.searchErrorTitle,
          switch (state.failure) {
            EngineFailure.network => l10n.searchNetworkBody,
            EngineFailure.unauthorized => l10n.searchAuthBody,
            EngineFailure.notFound => l10n.searchNotFoundBody,
            EngineFailure.unavailable => l10n.searchNotReadyBody,
            _ => l10n.searchErrorBody,
          },
          action: PillButton(
            label: l10n.actionRetry,
            icon: AppIcons.refresh,
            onPressed: onRetry,
          ),
        );
      case PlaylistImportStatus.loaded:
        if (state.entries.isEmpty) {
          return message(
            l10n.playlistImportNoTracksTitle,
            l10n.playlistImportNoTracksBody,
          );
        }
        return _Tracks(state: state);
    }
  }
}

class _Tracks extends StatelessWidget {
  const _Tracks({required this.state});

  final PlaylistImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<PlaylistImportCubit>();

    return ListView(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: Row(
            children: [
              ArtworkBox(
                image: state.thumbnailUrl == null
                    ? null
                    : NetworkImage(state.thumbnailUrl!),
                size: 56,
                radius: AppRadii.sm,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.title,
                      style: text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.songCount(state.entries.length),
                      style: text.bodySmall?.copyWith(color: p.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: AppSpacing.screen.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PillButton(
              label: state.allSelected
                  ? l10n.playlistImportClear
                  : l10n.playlistImportSelectAll,
              icon: state.allSelected
                  ? AppIcons.radioOff
                  : AppIcons.checkCircle,
              variant: PillVariant.tonal,
              onPressed: cubit.toggleAll,
            ),
          ),
        ),
        for (final hit in state.entries)
          _Row(
            hit: hit,
            selected: state.selected.contains(hit.id),
            onTap: () => cubit.toggle(hit.id),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.hit, required this.selected, required this.onTap});

  final MediaHit hit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final thumb = hit.thumbnailUrl;
    return TrackTile(
      title: hit.title,
      subtitle: [
        if (hit.uploader.isNotEmpty) hit.uploader,
        if (hit.duration != null) formatDuration(hit.duration!),
      ].join(' · '),
      tone: toneFor(hit.id),
      artwork: thumb == null ? null : NetworkImage(thumb),
      trailing: Icon(
        selected ? AppIcons.checkCircle : AppIcons.radioOff,
        color: selected ? p.accent : p.onSurfaceMuted,
      ),
      onTap: onTap,
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.starting, required this.onStart});

  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<PlaylistImportCubit>().state;
    if (state.status != PlaylistImportStatus.loaded || state.entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final count = state.selected.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SizedBox(
        width: double.infinity,
        child: PillButton(
          label: l10n.playlistImportStart(count),
          icon: AppIcons.download,
          onPressed: count == 0 || starting ? null : onStart,
        ),
      ),
    );
  }
}
