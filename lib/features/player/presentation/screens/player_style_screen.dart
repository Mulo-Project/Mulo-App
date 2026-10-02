import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/player_style_cubit.dart';
import '../widgets/player_style_preview.dart';

/// 설정 > 플레이어 테마: 옆으로 넘기며 재생 화면 모양을 미리 보고 "사용"으로 고른다.
class PlayerStyleScreen extends StatefulWidget {
  const PlayerStyleScreen({super.key});

  @override
  State<PlayerStyleScreen> createState() => _PlayerStyleScreenState();
}

class _PlayerStyleScreenState extends State<PlayerStyleScreen> {
  late final PageController _pages;
  late PlayerStyle _shown;

  @override
  void initState() {
    super.initState();
    _shown = context.read<PlayerStyleCubit>().state;
    _pages = PageController(
      viewportFraction: .66,
      initialPage: PlayerStyle.values.indexOf(_shown),
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final current = context.watch<PlayerStyleCubit>().state;
    final inUse = _shown == current;

    return Scaffold(
      backgroundColor: p.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.playerStyleTitle,
                leading: CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: l10n.actionBack,
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: PlayerStyle.values.length,
                  onPageChanged: (i) =>
                      setState(() => _shown = PlayerStyle.values[i]),
                  itemBuilder: (context, i) {
                    final style = PlayerStyle.values[i];
                    return AnimatedScale(
                      scale: style == _shown ? 1 : .88,
                      duration: AppMotion.medium,
                      curve: AppMotion.standard,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.md,
                        ),
                        child: PlayerStylePreview(style: style),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final style in PlayerStyle.values)
                    AnimatedContainer(
                      duration: AppMotion.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: style == _shown ? 18 : 6,
                      height: 6,
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: style == _shown
                            ? p.accent
                            : p.onSurface.withValues(alpha: .25),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: AppSpacing.screen,
                child: Column(
                  children: [
                    Text(
                      playerStyleName(l10n, _shown),
                      style: text.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      playerStyleDescription(l10n, _shown),
                      style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PillButton(
                      label: inUse
                          ? l10n.playerStyleInUse
                          : l10n.playerStyleUse,
                      icon: inUse ? Icons.check_rounded : null,
                      variant: inUse ? PillVariant.tonal : PillVariant.accent,
                      onPressed: inUse
                          ? null
                          : () =>
                                context.read<PlayerStyleCubit>().select(_shown),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String playerStyleName(AppLocalizations l10n, PlayerStyle style) =>
    switch (style) {
      PlayerStyle.vinyl => l10n.playerStyleVinyl,
      PlayerStyle.square => l10n.playerStyleSquare,
      PlayerStyle.fullBleed => l10n.playerStyleFullBleed,
      PlayerStyle.arc => l10n.playerStyleArc,
    };

String playerStyleDescription(AppLocalizations l10n, PlayerStyle style) =>
    switch (style) {
      PlayerStyle.vinyl => l10n.playerStyleVinylDesc,
      PlayerStyle.square => l10n.playerStyleSquareDesc,
      PlayerStyle.fullBleed => l10n.playerStyleFullBleedDesc,
      PlayerStyle.arc => l10n.playerStyleArcDesc,
    };
