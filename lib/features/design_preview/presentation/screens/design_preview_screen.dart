import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../theme/presentation/bloc/theme_cubit.dart';

/// 디자인 시스템 미리보기. 실제 홈 화면이 생기기 전까지 첫 화면으로 쓴다.
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  bool _playing = true;
  double _progress = .62;

  @override
  Widget build(BuildContext context) {
    final sourceId = context.select((ThemeCubit c) => c.state.sourceId);
    final controller = context.read<ThemeCubit>();
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  children: [
                    _Header(
                      isDefault: sourceId == ThemePreset.violet.id,
                      onDefault: controller.reset,
                      onAlternate: () => controller.apply(ThemePreset.coral),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _Swatches(),
                    const SizedBox(height: AppSpacing.lg),
                    _HeroCard(progress: _progress),
                    const SizedBox(height: AppSpacing.sm),
                    const Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            tone: GlowTone.secondary,
                            label: '다운로드',
                            value: '12',
                            unit: '곡 대기 중',
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _StatCard(
                            tone: GlowTone.tertiary,
                            label: '오늘 재생',
                            value: '4.2',
                            unit: '시간',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle('버튼'),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        PillButton(
                          label: '다운로드',
                          icon: Icons.download_rounded,
                          onPressed: () {},
                        ),
                        PillButton(
                          label: '재생목록',
                          variant: PillVariant.primary,
                          onPressed: () {},
                        ),
                        PillButton(
                          label: '셔플',
                          variant: PillVariant.tonal,
                          icon: Icons.shuffle_rounded,
                          onPressed: () {},
                        ),
                        PillButton(
                          label: '취소',
                          variant: PillVariant.outline,
                          onPressed: () {},
                        ),
                        const PillButton(label: '비활성', onPressed: null),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        CircleIconButton(
                          icon: Icons.skip_previous_rounded,
                          tooltip: '이전 곡',
                          onPressed: () {},
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        CircleIconButton(
                          icon: _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          tooltip: '재생',
                          emphasized: true,
                          size: AppSizes.circleButtonLarge,
                          onPressed: _togglePlay,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        CircleIconButton(
                          icon: Icons.skip_next_rounded,
                          tooltip: '다음 곡',
                          onPressed: () {},
                        ),
                        const Spacer(),
                        CircleIconButton(
                          icon: Icons.favorite_border_rounded,
                          tooltip: '좋아요',
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle('진행 표시'),
                    ProgressLine(value: _progress),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text('-10%', style: text.labelSmall),
                        const Spacer(),
                        PillButton(
                          label: '-',
                          compact: true,
                          variant: PillVariant.tonal,
                          onPressed: () => _nudge(-.1),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        PillButton(
                          label: '+',
                          compact: true,
                          variant: PillVariant.tonal,
                          onPressed: () => _nudge(.1),
                        ),
                        const Spacer(),
                        Text('+10%', style: text.labelSmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle('글자'),
                    Text('Display', style: text.displaySmall),
                    Text('Headline 제목', style: text.headlineSmall),
                    Text('Title 곡 제목', style: text.titleMedium),
                    Text('Body 본문 텍스트입니다.', style: text.bodyMedium),
                    Text('Caption 보조 설명', style: text.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    const StatNumber('0123456789:.-/%', size: 22),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: MiniPlayerBar(
                  title: 'Midnight Signal',
                  artist: 'Sample Artist',
                  progress: _progress,
                  isPlaying: _playing,
                  playLabel: '재생',
                  pauseLabel: '일시정지',
                  nextLabel: '다음 곡',
                  onPlayPause: _togglePlay,
                  onNext: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePlay() => setState(() => _playing = !_playing);

  void _nudge(double d) =>
      setState(() => _progress = (_progress + d).clamp(0, 1));
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isDefault,
    required this.onDefault,
    required this.onAlternate,
  });

  final bool isDefault;
  final VoidCallback onDefault;
  final VoidCallback onAlternate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Navigator.of(context).canPop()) ...[
          CircleIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text('DESIGN SYSTEM', style: text.labelSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text('미리보기', style: text.headlineLarge),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            PillButton(
              label: '기본',
              compact: true,
              variant: PillVariant.tonal,
              selected: isDefault,
              onPressed: onDefault,
            ),
            const SizedBox(width: AppSpacing.xs),
            PillButton(
              label: '대체 팔레트',
              compact: true,
              variant: PillVariant.tonal,
              selected: !isDefault,
              onPressed: onAlternate,
            ),
          ],
        ),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entries = [
      ('BG', p.background),
      ('Surface', p.surfaceHigh),
      ('Primary', p.primary),
      ('Accent', p.accent),
      ('On', p.onSurface),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (label, color) in entries)
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.outline),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final percent = (progress * 100).round();

    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('보관함', style: text.titleMedium),
                const SizedBox(height: AppSpacing.md),
                const StatNumber('128', size: 56),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '곡 · 9.4 GB',
                  style: text.bodySmall?.copyWith(color: p.onSurface),
                ),
                const SizedBox(height: AppSpacing.md),
                PillButton(
                  label: '전체 재생',
                  icon: Icons.play_arrow_rounded,
                  compact: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          ProgressRing(
            value: progress,
            size: 132,
            child: StatNumber('$percent%', size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.tone,
    required this.label,
    required this.value,
    required this.unit,
  });

  final GlowTone tone;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      tone: tone,
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.titleSmall),
          const SizedBox(height: AppSpacing.lg),
          StatNumber(value, size: 40),
          const SizedBox(height: AppSpacing.xs),
          Text(
            unit,
            style: text.bodySmall?.copyWith(color: context.palette.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    ),
  );
}
