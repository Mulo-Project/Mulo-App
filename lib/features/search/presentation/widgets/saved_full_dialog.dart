import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/format/format_bytes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../settings/presentation/widgets/stream_cache_row.dart'
    show streamCacheLimits;
import '../bloc/stream_cache_cubit.dart';
import 'video_quality_sheet.dart' show ChoiceChipItem, ChoiceChips;

/// 임시 저장 공간이 가득 찼을 때 알리고, 그 자리에서 한도를 고르게 한다 (가로로 넘기는 선택 칩).
/// 한도를 바꿨으면 true, 그냥 닫았으면 false. [cubit]은 이 대화상자가 쓰는 용량 상태다.
Future<bool> showSavedFullDialog(
  BuildContext context,
  StreamCacheCubit cubit,
) async {
  final changed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _SavedFullDialog(),
    ),
  );
  return changed ?? false;
}

class _SavedFullDialog extends StatelessWidget {
  const _SavedFullDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<StreamCacheCubit>();
    final info = context.watch<StreamCacheCubit>().state;
    return AppDialog(
      title: l10n.settingsStreamCache,
      body: l10n.savedVideosFull,
      closeTooltip: l10n.actionCancel,
      content: ChoiceChips(
        items: [
          for (final limit in streamCacheLimits)
            ChoiceChipItem(
              key: ValueKey('saved-full-limit-$limit'),
              label: formatBytes(limit),
              selected: info.limitBytes == limit,
              onTap: () async {
                final navigator = Navigator.of(context);
                await cubit.setLimit(limit);
                navigator.pop(true);
              },
            ),
        ],
      ),
      actions: [
        PillButton(
          label: l10n.actionCancel,
          variant: PillVariant.tonal,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
