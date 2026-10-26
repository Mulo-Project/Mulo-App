import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_download_play_app/features/account/data/datasources/google_auth_source.dart';
import 'package:music_download_play_app/features/account/data/repositories/google_account_repository.dart';
import 'package:music_download_play_app/features/account/domain/entities/google_account.dart';

class _Auth implements GoogleAuthSource {
  @override
  Future<String> accessToken() async => 't';
  @override
  Future<GoogleAccount?> restore() async => null;
  @override
  Future<GoogleAccount> signIn() async =>
      const GoogleAccount(id: 'u', email: 'a@b.c');
  @override
  Future<void> signOut() async {}
}

void main() {
  test('구독이 500개를 넘어도 nextPageToken을 끝까지 따라 모두 읽는다', () async {
    const total = 1234;
    final calls = <String?>[];
    final repo = GoogleAccountRepository(
      auth: _Auth(),
      get: (uri, headers) async {
        final token = uri.queryParameters['pageToken'];
        calls.add(token);
        final start = token == null ? 0 : int.parse(token);
        final end = (start + 50).clamp(0, total);
        return (
          status: 200,
          body: jsonEncode({
            'items': [
              for (var i = start; i < end; i++)
                {
                  'snippet': {
                    'title': 'c$i',
                    'resourceId': {'channelId': 'UC$i'},
                  },
                },
            ],
            'nextPageToken': ?(end < total ? '$end' : null),
          }),
        );
      },
    );
    final progress = <int>[];
    final all = await repo.mySubscriptions(onProgress: progress.add);
    expect(all, hasLength(total));
    expect(calls, hasLength(25));
    expect(progress.last, total);
  });
}
