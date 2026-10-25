import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/account/domain/entities/google_account.dart';
import 'package:music_download_play_app/features/account/domain/usecases/account_usecases.dart';
import 'package:music_download_play_app/features/subscriptions/domain/entities/channel_hit.dart';
import 'package:music_download_play_app/features/subscriptions/presentation/bloc/my_subscriptions_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  const a = ChannelHit(id: 'UCa', name: 'A');
  const b = ChannelHit(id: 'UCb', name: 'B');
  const c = ChannelHit(id: 'UCc', name: 'C');
  const me = GoogleAccount(id: 'u', email: 'a@b.c');

  MySubscriptionsCubit cubit(FakeAccountRepository repo) =>
      MySubscriptionsCubit(FetchMySubscriptions(repo));

  test('로그인한 계정의 구독 채널을 불러온다', () async {
    final cubit0 = cubit(
      FakeAccountRepository(account: me, subscriptions: [a, b]),
    );
    await cubit0.load();
    expect(cubit0.state.status, MySubscriptionsStatus.done);
    expect(cubit0.state.channels, [a, b]);
  });

  test('로그인이 풀렸으면 로그인이 필요하다고 알린다', () async {
    final cubit0 = cubit(FakeAccountRepository(subscriptions: [a]));
    await cubit0.load();
    expect(cubit0.state.status, MySubscriptionsStatus.failed);
    expect(cubit0.state.failure, AccountFailure.unauthorized);
  });

  test('채널을 눌러 고르고 풀며, 이미 구독한 채널은 골라낸 목록에서 뺀다', () async {
    final cubit0 = cubit(
      FakeAccountRepository(account: me, subscriptions: [a, b, c]),
    );
    await cubit0.load();
    cubit0
      ..toggle('UCa')
      ..toggle('UCb')
      ..toggle('UCa');
    expect(cubit0.state.picked, {'UCb'});
    expect(cubit0.pickedChannels({'UCb'}), isEmpty);
    expect(cubit0.pickedChannels({}), [b]);
  });

  test('새 채널 모두 선택은 이미 구독한 채널을 고르지 않는다', () async {
    final cubit0 = cubit(
      FakeAccountRepository(account: me, subscriptions: [a, b, c]),
    );
    await cubit0.load();
    cubit0.pickAllNew({'UCb'});
    expect(cubit0.state.picked, {'UCa', 'UCc'});
    cubit0.clearPicked();
    expect(cubit0.state.picked, isEmpty);
  });
}
