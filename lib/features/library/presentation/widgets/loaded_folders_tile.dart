import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/design.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/l10n/l10n.dart';
import '../bloc/library_cubit.dart';
import '../bloc/loaded_folders_cubit.dart';
import 'loaded_folders_sheet.dart';

/// 설정의 "불러오는 폴더" 줄. 부제에 폴더 개수, 누르면 바텀 시트.
class LoadedFoldersTile extends StatelessWidget {
  const LoadedFoldersTile({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<LoadedFoldersCubit>()..load(),
    // 다운로드 · 삭제 · 스캔으로 보관함의 곡이 바뀌면 폴더별 곡 수를 다시 센다.
    child: BlocListener<LibraryCubit, LibraryState>(
      listenWhen: (a, b) => a.tracks != b.tracks,
      listener: (context, _) {
        final cubit = context.read<LoadedFoldersCubit>();
        if (!cubit.state.busy) cubit.load();
      },
      child: const _Tile(),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = context.select(
      (LoadedFoldersCubit c) => c.state.folders.length,
    );
    return SettingRow(
      title: l10n.settingsLoadedFolders,
      description: l10n.settingsLoadedFoldersCount(count == 0 ? 1 : count),
      trailing: Icon(
        AppIcons.chevronRight,
        color: context.palette.onSurfaceMuted,
      ),
      onTap: () => showLoadedFoldersSheet(context),
    );
  }
}
