import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/google_account.dart';
import '../../domain/usecases/account_usecases.dart';

class AccountState extends Equatable {
  const AccountState({
    this.support = AccountSupport.available,
    this.account,
    this.busy = false,
    this.failure,
  });

  final AccountSupport support;

  /// 로그인한 계정. 로그아웃 상태면 null.
  final GoogleAccount? account;
  final bool busy;

  /// 마지막 로그인 시도가 실패한 까닭 (취소는 실패로 치지 않는다).
  final AccountFailure? failure;

  bool get signedIn => account != null;

  @override
  List<Object?> get props => [support, account, busy, failure];
}

/// 구글 계정 로그인 상태 (앱 전체에서 하나). 설정과 재생목록 가져오기가 함께 쓴다.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._support, this._restore, this._signIn, this._signOut)
    : super(const AccountState());

  final GetAccountSupport _support;
  final RestoreAccount _restore;
  final SignInAccount _signIn;
  final SignOutAccount _signOut;

  Future<void> load() async {
    final support = await _support(const NoParams());
    emit(AccountState(support: support));
    final account = await _restore(const NoParams());
    if (!isClosed) emit(AccountState(support: support, account: account));
  }

  AccountState _busy() =>
      AccountState(support: state.support, account: state.account, busy: true);

  /// 로그인 창을 띄운다. 성공하면 계정을, 취소 · 실패면 null을 돌려준다.
  Future<GoogleAccount?> signIn() async {
    if (state.busy) return state.account;
    emit(_busy());
    try {
      final account = await _signIn(const NoParams());
      emit(AccountState(support: state.support, account: account));
      return account;
    } on AccountException catch (e) {
      emit(
        AccountState(
          support: state.support,
          account: state.account,
          failure: e.failure == AccountFailure.cancelled ? null : e.failure,
        ),
      );
      return null;
    }
  }

  Future<void> signOut() async {
    emit(_busy());
    try {
      await _signOut(const NoParams());
    } on Object {
      // 로그아웃은 실패해도 이 앱에서는 풀린 것으로 본다.
    }
    emit(AccountState(support: state.support));
  }
}
