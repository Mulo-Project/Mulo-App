import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/cover_cubit.dart';

/// 커버 이미지 바꾸기 시트: 미리보기 · 사진에서 고르기 · 기본 이미지로.
Future<void> showCoverSheet(
  BuildContext context, {
  required String coverKey,
  required String title,
  GlowTone tone = GlowTone.primary,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: context.palette.surface,
  showDragHandle: true,
  isScrollControlled: true,
  // 탭 틀(미니 플레이어 · 탭 바) 위에 뜨도록 최상위 내비게이터에서 연다.
  useRootNavigator: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
  ),
  builder: (_) => _CoverSheet(coverKey: coverKey, title: title, tone: tone),
);

class _CoverSheet extends StatelessWidget {
  const _CoverSheet({
    required this.coverKey,
    required this.title,
    required this.tone,
  });

  final String coverKey;
  final String title;
  final GlowTone tone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final image = coverImageOf(context, coverKey);
    final ctrl = context.read<CoverCubit>();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.coverTitle, style: text.titleLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                title,
                style: text.bodyMedium?.copyWith(
                  color: context.palette.onSurfaceMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.lg),
              ArtworkBox(image: image, tone: tone, size: 160, radius: 28),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: PillButton(
                  label: l10n.coverPick,
                  icon: Icons.photo_library_rounded,
                  onPressed: () async {
                    final picked = await ctrl.pickFromDevice(coverKey);
                    if (picked && context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
              if (image != null) ...[
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: PillButton(
                    label: l10n.coverReset,
                    icon: Icons.restart_alt_rounded,
                    variant: PillVariant.tonal,
                    onPressed: () {
                      ctrl.clear(coverKey);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
