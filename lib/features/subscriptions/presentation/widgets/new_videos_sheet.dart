import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/feed_video.dart';
import '../bloc/new_videos_cubit.dart';
import 'subscription_sheet.dart';

var _open = false;

/// 구독 채널의 새 영상 목록을 바텀시트로 연다. 채널별로 묶어 평평하게 보여 주고, 골라서 한꺼번에 받는다.
/// 시트를 닫으면 확인한 채널은 여기까지 본 것으로 표시한다 (받지 않은 영상은 다시 뜨지 않는다).
/// 이미 열려 있으면 다시 열지 않는다.
Future<void> showNewVideosSheet(BuildContext context) async {
  if (_open) return;
  _open = true;
  final cubit = sl<NewVideosCubit>();
  try {
    await showSubscriptionSheet<void>(
      context,
      builder: (_) => const _NewVideosSheet(),
    );
  } finally {
    _open = false;
    await cubit.markSeen();
  }
}

class _NewVideosSheet extends StatefulWidget {
  const _NewVideosSheet();

  @override
  State<_NewVideosSheet> createState() => _NewVideosSheetState();
}

class _NewVideosSheetState extends State<_NewVideosSheet> {
  late final NewVideosCubit _cubit = sl<NewVideosCubit>();

  @override
  void initState() {
    super.initState();
    // 앱을 켤 때 확인한 결과가 있으면 그대로 보여 주고, 없으면 지금 확인한다.
    if (_cubit.state.checked.isEmpty) _cubit.check();
  }

  Future<void> _start() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final queued = await _cubit.startSelected();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          queued == 0 ? l10n.newVideosSkipped : l10n.newVideosStarted(queued),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return BlocProvider.value(
      value: _cubit,
      child: SizedBox(
        height: height * .75,
        child: Column(
          children: [
            const _Header(),
            const Expanded(child: _Body()),
            _Footer(onStart: _start),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<NewVideosCubit>().state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.xxs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.newVideosTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (state.count > 0)
            PlainButton(
              label: state.allSelected
                  ? l10n.newVideosSelectNone
                  : l10n.newVideosSelectAll,
              accent: true,
              onPressed: context.read<NewVideosCubit>().toggleAll,
            ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final state = context.watch<NewVideosCubit>().state;
    final cubit = context.read<NewVideosCubit>();
    final groups = state.groups;

    if (groups.isEmpty) {
      final busy = state.status == NewVideosStatus.checking || state.resolving;
      return Center(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                busy ? l10n.newVideosChecking : l10n.newVideosEmptyTitle,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (!busy) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.newVideosEmptyBody,
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xxs,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    g.channel.name,
                    style: text.labelLarge?.copyWith(color: p.onSurfaceMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PlainButton(
                  label: g.videos.every((v) => state.selected.contains(v.id))
                      ? l10n.newVideosSelectNone
                      : l10n.newVideosSelectAll,
                  onPressed: () => cubit.toggleChannel(g.channel.id),
                ),
              ],
            ),
          ),
          for (final v in g.videos)
            _Row(
              video: v,
              selected: state.selected.contains(v.id),
              locale: locale,
              onTap: () => cubit.toggle(v.id),
            ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.video,
    required this.selected,
    required this.locale,
    required this.onTap,
  });

  final FeedVideo video;
  final bool selected;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final thumb = video.thumbnailUrl;
    return TrackTile(
      title: video.title,
      subtitle: DateFormat.yMMMd(locale)
          .add_Hm()
          .format(video.publishedAt.toLocal()),
      tone: toneFor(video.id),
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
  const _Footer({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final count = context.select(
      (NewVideosCubit c) =>
          c.state.selected.intersection(c.state.visibleIds).length,
    );
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: count == 0
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: context.l10n.newVideosStart(count),
                  icon: AppIcons.download,
                  onPressed: onStart,
                ),
              ),
            ),
    );
  }
}
