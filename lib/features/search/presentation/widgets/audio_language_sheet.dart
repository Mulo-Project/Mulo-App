import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../downloads/presentation/widgets/subtitle_language_label.dart';
import '../../domain/entities/audio_language.dart';
import '../bloc/audio_language_cubit.dart';

/// 오디오 언어를 사람이 읽는 이름으로 (코드를 아는 언어는 앱 언어로, 그 밖에는 유튜브가 준 이름).
String audioLanguageLabel(BuildContext context, AudioLanguage language) {
  final korean = Localizations.localeOf(context).languageCode == 'ko';
  final byCode = subtitleLanguageLabel(language.id, korean: korean);
  return byCode == language.id ? language.name : byCode;
}

/// 영상 정보 · 받기 화면의 "오디오 언어" 줄. 트랙이 둘 이상일 때만 보이고, 누르면 시트를 연다.
/// 위쪽에 같은 [AudioLanguageCubit]이 있어야 한다.
class AudioLanguageRow extends StatelessWidget {
  const AudioLanguageRow({super.key, this.onChanged});

  /// 시트에서 다른 언어를 골랐을 때 (미리 듣기를 새 언어로 다시 틀 때 쓴다).
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AudioLanguageCubit>().state;
    final current = state.current;
    if (!state.choosable || current == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('audio-language-row'),
        onTap: () => showAudioLanguageSheet(context, onChanged: onChanged),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                AppIcons.headphones,
                size: AppSizes.iconMd,
                color: p.onSurfaceMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.audioLanguageRow, style: text.bodyMedium),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  audioLanguageLabel(context, current),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: p.accent),
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: AppSizes.iconMd,
                color: p.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "오디오 언어" 시트: 플레이어 테마 시트처럼 고르면 바로 적용되고, 시트가 떠 있어도 뒤 화면이
/// 가려지지 않아 미리 듣기를 들으며 언어를 바꿔 볼 수 있다. 카드 없이 줄로만 보여 준다.
Future<void> showAudioLanguageSheet(
  BuildContext context, {
  ValueChanged<String>? onChanged,
}) {
  final cubit = context.read<AudioLanguageCubit>();
  return showAppSheet<void>(
    context,
    barrierColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _AudioLanguageSheet(onChanged: onChanged),
    ),
  );
}

class _AudioLanguageSheet extends StatelessWidget {
  const _AudioLanguageSheet({this.onChanged});

  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final state = context.watch<AudioLanguageCubit>().state;
    final current = state.current;
    return SafeArea(
      child: Padding(
        padding: appSheetPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetTitle(
              l10n.audioLanguageTitle,
              subtitle: l10n.audioLanguageHint,
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final language in state.languages)
                    InkWell(
                      key: ValueKey('audio-language-${language.id}'),
                      onTap: () {
                        if (language.id == current?.id) return;
                        context.read<AudioLanguageCubit>().select(language.id);
                        onChanged?.call(language.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm + AppSpacing.xxs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                audioLanguageLabel(context, language),
                                style: text.bodyLarge?.copyWith(
                                  color: language.id == current?.id
                                      ? p.accent
                                      : p.onSurface,
                                ),
                              ),
                            ),
                            if (language.isDefault)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.audioLanguageOriginal,
                                  style: text.bodySmall,
                                ),
                              ),
                            SizedBox(
                              width: AppSizes.iconMd,
                              child: language.id == current?.id
                                  ? Icon(
                                      AppIcons.check,
                                      size: AppSizes.iconMd,
                                      color: p.accent,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
