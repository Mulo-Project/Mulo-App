import 'package:flutter/material.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/sample/sample_data.dart';

/// 재생목록 (상세 기능: 재생목록 관리 #20, 유튜브 재생목록 가져오기 #22). 자리 표시 데이터.
class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lists = SampleData.playlists;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AppTopBar(
            large: true,
            title: l10n.navPlaylists,
            subtitle: l10n.playlistsSubtitle,
            actions: [
              CircleIconButton(
                icon: Icons.add_rounded,
                tooltip: l10n.playlistsNew,
                emphasized: true,
                onPressed: () {},
              ),
            ],
          ),
          Padding(
            padding: AppSpacing.screen,
            child: PillButton(
              label: l10n.playlistsImport,
              icon: Icons.link_rounded,
              variant: PillVariant.tonal,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: AppSpacing.screen,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var i = 0; i < lists.length; i++)
                      SizedBox(
                        width: w,
                        child: _PlaylistCard(
                          name: lists[i].$1,
                          count: lists[i].$2,
                          tone: GlowTone.values[i % GlowTone.values.length],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.name,
    required this.count,
    required this.tone,
  });

  final String name;
  final int count;
  final GlowTone tone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AspectRatio(
      aspectRatio: .82,
      child: GlassCard(
        tone: tone,
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: text.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            StatNumber('$count', size: 40),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.unitSongs,
              style: text.bodySmall?.copyWith(color: context.palette.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
