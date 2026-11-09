import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../app/router.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../account/domain/entities/google_account.dart';
import '../../../account/presentation/widgets/sign_in_flow.dart';
import '../widgets/channel_pick_sheet.dart';
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

  /// 마지막으로 연 구글 계정 목록을 다시 연다 (로그인이 풀렸을 때의 "로그인" · "다시 시도" 버튼).
  Future<void> Function() _reopen = () async {};

  /// 내 재생목록: 로그인돼 있지 않으면 먼저 로그인한 뒤 불러온다.
  Future<void> _openMine() async {
    _reopen = _openMine;
    if (!await ensureGoogleSignIn(context) || !mounted) return;
    await _cubit.loadMine();
  }

  /// 구독 채널의 재생목록: 채널을 고르면 그 채널의 업로드 전체와 재생목록을 보여 준다.
  Future<void> _openChannels() async {
    final channel = await showChannelPickSheet(context);
    if (channel == null || !mounted) return;
    final uploads = context.l10n.channelPlaylistsUploads;
    Future<void> open() async {
      _reopen = open;
      if (!await ensureGoogleSignIn(context) || !mounted) return;
      await _cubit.loadChannel(channel.id, channel.name, uploads);
    }

    await open();
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
    // 만든 재생목록 상세로 바로 가서 곡별 받기 진행을 보여 준다.
    router.pushReplacement(Routes.playlistDetail(result.playlistId));
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

  Widget _shortcuts(AppLocalizations l10n) => Padding(
    padding: AppSpacing.screen.copyWith(top: AppSpacing.xs),
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: PillButton(
            label: l10n.playlistImportMine,
            icon: AppIcons.playlistPlay,
            variant: PillVariant.tonal,
            onPressed: _openMine,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: PillButton(
            label: l10n.playlistImportChannels,
            icon: AppIcons.person,
            variant: PillVariant.tonal,
            onPressed: _openChannels,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<PlaylistImportCubit, PlaylistImportState>(
        builder: (context, state) {
          // 찾은 재생목록 하나를 열어 보는 중(읽는 중 · 곡 목록 · 실패)이면 뒤로 가기는 찾은 목록으로 돌아간다.
          final viewing =
              state.results.isNotEmpty &&
              (state.status == PlaylistImportStatus.loading ||
                  state.status == PlaylistImportStatus.loaded ||
                  state.status == PlaylistImportStatus.failed);
          return PopScope(
            canPop: !viewing,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && viewing) _cubit.backToResults();
            },
            child: Scaffold(
              backgroundColor: p.background,
              body: AppBackground(
                child: SafeArea(
                  child: Column(
                    children: [
                      AppTopBar(
                        title: l10n.playlistsImport,
                        leading: AppBackButton(
                          onPressed: viewing ? _cubit.backToResults : null,
                        ),
                      ),
                      // 재생목록 하나를 열어 보는 동안은 찾기 칸을 숨겨 곡 목록에 집중한다.
                      if (!viewing) ...[
                        Padding(
                          padding: AppSpacing.screen,
                          child: AppSearchField(
                            controller: _controller,
                            hint: l10n.playlistImportHint,
                            clearTooltip: l10n.actionClear,
                            // 이 화면은 검색이 주 동작이라 아래 큰 버튼들보다 커 보이게 한다.
                            height: 56,
                            onSubmitted: (_) => _load(),
                          ),
                        ),
                      ],
                      Expanded(
                        child: _Body(
                          onRetry: _load,
                          onSignIn: () => _reopen(),
                          // 내 재생목록 · 채널 버튼은 검색창과 달리 목록과 함께 스크롤된다.
                          shortcuts: viewing ? null : _shortcuts(l10n),
                        ),
                      ),
                      _Footer(starting: _starting, onStart: _start),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.onRetry,
    required this.onSignIn,
    this.shortcuts,
  });

  final VoidCallback onRetry;

  /// 목록 위에 함께 스크롤되는 버튼들 (없으면 곡 목록을 열어 보는 중).
  final Widget? shortcuts;

  /// 내 재생목록을 읽으려면 로그인해야 할 때 누르는 버튼의 동작.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlaylistImportCubit>().state;
    final content = _content(context, state);
    final lead = shortcuts;
    // 안내 화면은 버튼 아래 남은 자리 가운데에 놓고, 같이 스크롤한다 (결과 목록은 목록 맨 위에 붙인다).
    final listing =
        state.status == PlaylistImportStatus.results &&
        state.results.isNotEmpty;
    final withLead =
        lead != null &&
        (state.status == PlaylistImportStatus.idle ||
            state.status == PlaylistImportStatus.results ||
            state.status == PlaylistImportStatus.failed);
    if (!withLead || listing) return content;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: lead),
        SliverFillRemaining(hasScrollBody: false, child: content),
      ],
    );
  }

  Widget _content(BuildContext context, PlaylistImportState state) {
    final l10n = context.l10n;

    // 모든 안내에 아이콘을 붙여 같은 모양으로 보인다.
    Widget message(
      String title,
      String body, {
      Widget? action,
      IconData icon = AppIcons.playlistPlay,
    }) => EmptyState(icon: icon, title: title, body: body, action: action);

    switch (state.status) {
      case PlaylistImportStatus.idle:
        return message(
          l10n.playlistImportEmptyTitle,
          l10n.playlistImportEmptyBody,
        );
      case PlaylistImportStatus.loading:
        return LoadingState(label: l10n.playlistImportLoading);
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
                  icon: AppIcons.search,
                );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            ?shortcuts,
            if (state.mine) SectionTitle(l10n.playlistImportMineTitle),
            if (state.channel.isNotEmpty) SectionTitle(state.channel),
            for (final hit in state.results)
              _ResultRow(
                hit: hit,
                onTap: () => context.read<PlaylistImportCubit>().open(hit),
              ),
          ],
        );
      case PlaylistImportStatus.failed:
        if (state.fromAccount &&
            state.accountFailure == AccountFailure.network) {
          return EmptyState.network(onRetry: onSignIn);
        }
        if (state.fromAccount &&
            state.accountFailure == AccountFailure.unauthorized) {
          return EmptyState.signIn(
            body: l10n.playlistImportLoginExpiredBody,
            onSignIn: onSignIn,
          );
        }
        if (!state.fromAccount && state.failure == EngineFailure.network) {
          return EmptyState.network(onRetry: onRetry);
        }
        if (state.fromAccount &&
            state.accountFailure == AccountFailure.timeout) {
          return EmptyState.timeout(onRetry: onSignIn);
        }
        if (!state.fromAccount && state.failure == EngineFailure.timeout) {
          return EmptyState.timeout(onRetry: onRetry);
        }
        if (state.fromAccount) {
          final expired = state.accountFailure == AccountFailure.unauthorized;
          final noChannel = state.accountFailure == AccountFailure.noChannel;
          final body = switch (state.accountFailure) {
            AccountFailure.unauthorized => l10n.playlistImportLoginExpiredBody,
            AccountFailure.noChannel => l10n.playlistImportNoChannelBody,
            AccountFailure.network => l10n.searchNetworkBody,
            _ => l10n.searchErrorBody,
          };
          return message(
            expired
                ? l10n.playlistImportLoginTitle
                : noChannel
                ? l10n.playlistImportNoChannelTitle
                : l10n.searchErrorTitle,
            // 채널이 없는 것은 예상된 상황이라 자세한 사유는 붙이지 않는다.
            noChannel || state.accountDetail.isEmpty
                ? body
                : '$body\n(${state.accountDetail})',
            icon: noChannel ? AppIcons.person : AppIcons.hourglassEmpty,
            action: noChannel
                ? null
                : PillButton(
                    label: expired
                        ? l10n.settingsAccountSignIn
                        : l10n.actionRetry,
                    icon: expired ? AppIcons.person : AppIcons.refresh,
                    onPressed: onSignIn,
                  ),
          );
        }
        if (state.notPlaylist) {
          return message(
            l10n.playlistImportNotPlaylistTitle,
            l10n.playlistImportNotPlaylistBody,
            icon: AppIcons.link,
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
          icon: AppIcons.hourglassEmpty,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: Row(
            children: [
              ArtworkBox(
                image: state.thumbnailUrl == null
                    ? null
                    : NetworkImage(state.thumbnailUrl!),
                size: 72,
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
                    const SizedBox(height: AppSpacing.hair),
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
        const SizedBox(height: AppSpacing.md),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppDivider(),
        ),
        // 고른 수는 왼쪽, 전체 선택 · 해제는 곡 목록의 체크 표시와 같은 오른쪽.
        Padding(
          padding: AppSpacing.screen.copyWith(top: AppSpacing.sm, bottom: 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.playlistImportSelectedCount(
                    state.selected.length,
                    state.entries.length,
                  ),
                  style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                ),
              ),
              // 체크 표시가 지금 상태: 모두 골랐으면 켜진 체크, 아니면 빈 동그라미 (누르면 바뀐다).
              PlainButton(
                label: l10n.playlistImportSelectAll,
                icon: state.allSelected
                    ? AppIcons.checkCircle
                    : AppIcons.radioOff,
                accent: state.allSelected,
                onPressed: cubit.toggleAll,
              ),
            ],
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
      subtitle: hit.uploader,
      detail: hit.duration == null ? null : formatDuration(hit.duration!),
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
