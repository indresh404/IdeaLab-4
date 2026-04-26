import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(authRepositoryProvider).watchUserProfile(user.uid);
  }
  return Stream.value(null);
});

final authControllerProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> signInWithOtp(String verificationId, String smsCode) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithOtp(verificationId, smsCode);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInWithCredential(PhoneAuthCredential credential) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithCredential(credential);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createUserProfile(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createUserProfile(user);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
