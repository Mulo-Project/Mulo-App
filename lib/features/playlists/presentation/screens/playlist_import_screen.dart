import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../account/domain/entities/google_account.dart';
import '../../../account/presentation/bloc/account_cubit.dart';
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

  void _load() => _cubit.submit(_controller.text);

  /// 내 재생목록: 로그인돼 있지 않으면 먼저 로그인한 뒤 불러온다.
  Future<void> _openMine() async {
    final account = context.read<AccountCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final support = account.state.support;
    if (support != AccountSupport.available) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            support == AccountSupport.notConfigured
                ? l10n.settingsAccountNotConfigured(
                    AppConfig.googleRequiredKeys,
                  )
                : l10n.settingsAccountUnsupported,
          ),
        ),
      );
      return;
    }
    if (!account.state.signedIn) {
      final allow = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (_) => const _SignInPromptDialog(),
      );
      if (allow != true) return;
      if (await account.signIn() == null) {
        if (account.state.failure != null) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.settingsAccountFailed)),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    await _cubit.loadMine();
  }

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
                Padding(
                  padding: AppSpacing.screen.copyWith(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: PillButton(
                      label: l10n.playlistImportMine,
                      icon: AppIcons.playlistPlay,
                      variant: PillVariant.tonal,
                      onPressed: _openMine,
                    ),
                  ),
                ),
                Expanded(
                  child: _Body(onRetry: _load, onSignIn: _openMine),
                ),
                _Footer(starting: _starting, onStart: _start),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 로그인하지 않고 "내 재생목록"을 눌렀을 때: 구글 로그인을 할지 묻는다.
class _SignInPromptDialog extends StatelessWidget {
  const _SignInPromptDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: l10n.playlistImportSignInPromptTitle,
      body: l10n.playlistImportSignInPromptBody,
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PillButton(
          label: l10n.playlistImportSignInAllow,
          icon: AppIcons.person,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.onRetry, required this.onSignIn});

  final VoidCallback onRetry;

  /// 내 재생목록을 읽으려면 로그인해야 할 때 누르는 버튼의 동작.
  final VoidCallback onSignIn;

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
      case PlaylistImportStatus.results:
        if (state.results.isEmpty) {
          return state.mine
              ? message(
                  l10n.playlistImportMineEmptyTitle,
                  l10n.playlistImportMineEmptyBody,
                )
              : message(
                  l10n.playlistImportNoResultsTitle,
                  l10n.playlistImportNoResultsBody,
                );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            if (state.mine)
              Padding(
                padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
                child: Text(
                  l10n.playlistImportMineTitle,
                  style: text.titleMedium,
                ),
              ),
            for (final hit in state.results)
              _ResultRow(
                hit: hit,
                onTap: () => context.read<PlaylistImportCubit>().open(hit),
              ),
          ],
        );
      case PlaylistImportStatus.failed:
        if (state.mine) {
          final expired = state.accountFailure == AccountFailure.unauthorized;
          return message(
            expired ? l10n.playlistImportLoginTitle : l10n.searchErrorTitle,
            switch (state.accountFailure) {
                  AccountFailure.unauthorized =>
                    l10n.playlistImportLoginExpiredBody,
                  AccountFailure.network => l10n.searchNetworkBody,
                  _ => l10n.searchErrorBody,
                }.trimRight() +
                (state.accountDetail.isEmpty
                    ? ''
                    : '\n(${state.accountDetail})'),
            action: PillButton(
              label: expired ? l10n.settingsAccountSignIn : l10n.actionRetry,
              icon: expired ? AppIcons.person : AppIcons.refresh,
              onPressed: onSignIn,
            ),
          );
        }
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
        if (state.results.isNotEmpty)
          Padding(
            padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: PillButton(
                label: l10n.playlistImportBackToResults,
                icon: AppIcons.back,
                variant: PillVariant.tonal,
                onPressed: cubit.backToResults,
              ),
            ),
          ),
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

/// 찾은 재생목록 한 줄: 대표 이미지 · 이름 · 채널 · 곡 수. 누르면 곡 목록을 읽는다.
class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.hit, required this.onTap});

  final PlaylistHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final thumb = hit.thumbnailUrl;
    final count = hit.trackCount;
    return TrackTile(
      title: hit.title,
      subtitle: [
        if (hit.channel.isNotEmpty) hit.channel,
        if (count != null) l10n.songCount(count),
      ].join(' · '),
      tone: toneFor(hit.id),
      artwork: thumb == null ? null : NetworkImage(thumb),
      trailing: Icon(AppIcons.chevronRight, color: p.onSurfaceMuted),
      onTap: onTap,
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
