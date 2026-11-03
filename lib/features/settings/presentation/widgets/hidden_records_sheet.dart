import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../library/domain/entities/track.dart';

/// 폴더를 빼서 숨겨 둔 곡의 목록 (바텀 시트). "기록 지우기"를 누르면 true.
Future<bool> showHiddenRecordsSheet(BuildContext context, List<Track> tracks) async {
  final purge = await showAppSheet<bool>(
    context,
    isScrollControlled: true,
    builder: (_) => _HiddenRecordsSheet(tracks: tracks),
  );
  return purge ?? false;
}

class _HiddenRecordsSheet extends StatelessWidget {
  const _HiddenRecordsSheet({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = context.palette.onSurfaceMuted;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: Padding(
          padding: appSheetPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              AppSheetTitle(
                l10n.settingsPurgeHidden,
                subtitle: l10n.hiddenRecordsHint,
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final t in tracks)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyLarge,
                            ),
                            Text(
                              t.artist.isEmpty ? l10n.unknownArtist : t.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(color: muted),
                            ),
                            if (t.folder.isNotEmpty)
                              Text(
                                t.folder,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall?.copyWith(color: muted),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: PlainButton(
                  label: l10n.hiddenRecordsPurge,
                  accent: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
