import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/feed_video.dart';
import '../bloc/new_videos_cubit.dart';

/// 구독 채널의 새 영상 목록. 채널별로 묶어 평평하게 보여 주고, 골라서 한꺼번에 받는다.
/// 화면을 나가면 확인한 채널은 여기까지 본 것으로 표시한다 (받지 않은 영상은 다시 뜨지 않는다).
class NewVideosScreen extends StatefulWidget {
  const NewVideosScreen({super.key});

  @override
  State<NewVideosScreen> createState() => _NewVideosScreenState();
}

class _NewVideosScreenState extends State<NewVideosScreen> {
  late final NewVideosCubit _cubit = sl<NewVideosCubit>();

  @override
  void initState() {
    super.initState();
    // 앱을 켤 때 확인한 결과가 있으면 그대로 보여 주고, 없으면 지금 확인한다.
    if (_cubit.state.checked.isEmpty) _cubit.check();
  }

  @override
  void dispose() {
    _cubit.markSeen();
    super.dispose();
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
                  title: l10n.newVideosTitle,
                  leading: CircleIconButton(
                    icon: AppIcons.back,
                    tooltip: l10n.actionBack,
                    onPressed: () => context.pop(),
                  ),
                ),
                const Expanded(child: _Body()),
                _Footer(onStart: _start),
              ],
            ),
          ),
        ),
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
    final state = context.watch<NewVideosCubit>().state;
    final cubit = context.read<NewVideosCubit>();
    final groups = state.groups;

    Widget message(String title, String? body) => Center(
      child: Padding(
        padding: AppSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(body, style: text.bodySmall, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );

    if (groups.isEmpty) {
      return state.status == NewVideosStatus.checking || state.resolving
          ? message(l10n.newVideosChecking, null)
          : message(l10n.newVideosEmptyTitle, l10n.newVideosEmptyBody);
    }
    final locale = Localizations.localeOf(context).toString();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: [
        Padding(
          padding: AppSpacing.screen,
          child: Align(
            alignment: Alignment.centerRight,
            child: PlainButton(
              label: state.allSelected
                  ? l10n.newVideosSelectNone
                  : l10n.newVideosSelectAll,
              accent: true,
              onPressed: cubit.toggleAll,
            ),
          ),
        ),
        for (final g in groups) ...[
          Padding(
            padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    g.channel.name,
                    style: text.titleSmall,
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
    if (count == 0) return const SizedBox.shrink();
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
          label: context.l10n.newVideosStart(count),
          icon: AppIcons.download,
          onPressed: onStart,
        ),
      ),
    );
  }
}
