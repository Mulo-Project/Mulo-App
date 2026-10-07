import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/core/di/injector.dart';
import 'package:music_download_play_app/features/permissions/domain/repositories/permission_repository.dart';
import 'package:music_download_play_app/features/permissions/presentation/bloc/permissions_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakePermissionRepository repo;
  late PermissionsCubit cubit;

  setUp(() async {
    await setUpTestDependencies();
    repo = sl<PermissionRepository>() as FakePermissionRepository;
    cubit = sl<PermissionsCubit>();
    await cubit.refresh();
  });

  tearDown(() => cubit.close());

  test('권한마다 현재 상태를 불러온다', () {
    expect(cubit.state.levels.keys, AppPermission.values);
    expect(cubit.state.levels.values, everyElement(PermissionLevel.denied));
  });

  test('허용 안 한 권한을 켜면 요청 창을 띄우고 결과를 반영한다', () async {
    await cubit.toggle(AppPermission.notifications);
    expect(
      cubit.state.levels[AppPermission.notifications],
      PermissionLevel.granted,
    );
    expect(repo.openedSettings, 0);
  });

  test('이미 허용했거나 막힌 권한을 누르면 시스템 설정을 연다', () async {
    repo.levels[AppPermission.audio] = PermissionLevel.blocked;
    await cubit.refresh();
    await cubit.toggle(AppPermission.audio);
    expect(repo.openedSettings, 1);
    expect(cubit.state.levels[AppPermission.audio], PermissionLevel.blocked);
  });
}
