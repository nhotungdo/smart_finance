import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';

// Provider for AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// StreamProvider to listen to auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Provider to get the current user synchronously
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) return null;
  return ref.watch(authRepositoryProvider).getProfileForAuthUser(authUser);
});

// Notifier to handle auth operations with loading state
class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is nothing
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signInWithEmailPassword(email, password);
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserProfileProvider);
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
  }) async {
    var requiresEmailConfirmation = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signUpWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
        businessName: businessName,
      );
      requiresEmailConfirmation = response.session == null;
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserProfileProvider);
    });
    return requiresEmailConfirmation;
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(email);
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentUserProfileProvider);
    });
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});
