import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/feed_video.dart';
import '../bloc/new_videos_cubit.dart';

var _open = false;

/// 구독 채널의 새 영상 목록을 바텀시트로 연다. 채널별로 묶어 평평하게 보여 주고, 골라서 한꺼번에 받는다.
/// 시트를 닫아도 목록은 그대로이고, 위의 "비우기"를 눌러야 확인한 것으로 표시해 비운다
/// (받지 않은 영상은 그 뒤로 다시 뜨지 않는다). 이미 열려 있으면 다시 열지 않는다.
Future<void> showNewVideosSheet(BuildContext context) async {
  if (_open) return;
  _open = true;
  try {
    await showAppSheet<void>(
      context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _NewVideosSheet(),
    );
  } finally {
    _open = false;
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
    final cubit = context.read<NewVideosCubit>();
    // 제목 아래에 "채널 N개 · 영상 M개"로 한눈에 얼마나 있는지 보여 주고, 모두 선택은 같은 줄 오른쪽에 둔다.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AppSheetTitle(
              l10n.newVideosTitle,
              subtitle: state.count > 0
                  ? l10n.newVideosSummary(state.groups.length, state.count)
                  : null,
            ),
          ),
          if (state.count > 0) ...[
            PlainButton(
              label: l10n.newVideosClear,
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.newVideosClearTitle,
                  body: l10n.newVideosClearBody,
                  confirmLabel: l10n.newVideosClear,
                  cancelLabel: l10n.actionCancel,
                );
                if (ok) await cubit.markSeen();
              },
            ),
            PlainButton(
              label: state.allSelected
                  ? l10n.newVideosSelectNone
                  : l10n.newVideosSelectAll,
              accent: true,
              onPressed: cubit.toggleAll,
            ),
          ],
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
    final state = context.watch<NewVideosCubit>().state;
    final cubit = context.read<NewVideosCubit>();
    final groups = state.groups;

    if (groups.isEmpty) {
      final busy = state.status == NewVideosStatus.checking || state.resolving;
      if (busy) return LoadingState(label: l10n.newVideosChecking);
      return EmptyState(
        icon: AppIcons.checkCircle,
        title: l10n.newVideosEmptyTitle,
        body: l10n.newVideosEmptyBody,
      );
    }
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          // 채널 묶음 사이는 가는 선으로 나눈다.
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: AppDivider(),
            ),
          _ChannelHeader(
            group: groups[i],
            selected: state.selected,
            cubit: cubit,
          ),
          for (final v in groups[i].videos)
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

/// 채널 묶음 머리: 작은 이미지 · 이름 · 영상 수, 오른쪽에 그 채널만 선택 · 해제.
class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({
    required this.group,
    required this.selected,
    required this.cubit,
  });

  final NewVideosGroup group;
  final Set<String> selected;
  final NewVideosCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final channel = group.channel;
    final all = group.videos.every((v) => selected.contains(v.id));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          ArtworkBox(
            image: channel.thumbnailUrl == null
                ? null
                : NetworkImage(channel.thumbnailUrl!),
            size: 28,
            radius: 14,
            tone: toneFor(channel.id),
            icon: AppIcons.person,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              channel.name,
              style: text.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          PlainButton(
            label: all ? l10n.newVideosSelectNone : l10n.newVideosSelectAll,
            onPressed: () => cubit.toggleChannel(channel.id),
          ),
        ],
      ),
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
      // 오늘 · 올해 영상이 대부분이라 연도 없이 짧게.
      subtitle: DateFormat.MMMd(locale)
          .add_Hm()
          .format(video.publishedAt.toLocal()),
      // 영상은 가로로 긴 16:9 썸네일로 보여 곡 줄(정사각)과 구분한다.
      leading: ArtworkBox(
        image: thumb == null ? null : NetworkImage(thumb),
        width: 80,
        size: 45,
        radius: AppRadii.sm,
        tone: toneFor(video.id),
        icon: AppIcons.download,
      ),
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
