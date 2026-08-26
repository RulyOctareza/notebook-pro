import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:notebook_pro/core/auth/auth_providers.dart';
import 'package:notebook_pro/features/notes/presentation/providers/notes_providers.dart';

/// Compact account control: sign in with Google, or show email + sign out.
class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseReady = ref.watch(firebaseReadyProvider);
    if (!firebaseReady) {
      return const SizedBox.shrink();
    }

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const SizedBox(
        width: 32,
        height: 32,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      ),
      error: (_, __) => IconButton(
        tooltip: 'Sign in with Google',
        onPressed: () => _signIn(context, ref),
        icon: const Icon(Icons.login, size: 18),
        visualDensity: VisualDensity.compact,
      ),
      data: (user) {
        final signedIn = user != null && !user.isAnonymous;
        if (!signedIn) {
          return IconButton(
            tooltip: 'Sign in with Google',
            onPressed: () => _signIn(context, ref),
            icon: const Icon(Icons.login, size: 18),
            visualDensity: VisualDensity.compact,
          );
        }

        final email = user.email ?? user.displayName ?? 'Account';
        final photo = user.photoURL;
        return PopupMenuButton<String>(
          tooltip: email,
          onSelected: (value) async {
            if (value == 'signOut') {
              await ref.read(authServiceProvider).signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text(
                email,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'signOut',
              child: Text('Sign out'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CircleAvatar(
              radius: 12,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? Text(
                      _initial(user.displayName ?? email),
                      style: const TextStyle(fontSize: 11),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  static String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      await ref.read(syncServiceProvider).pushPendingChanges();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Signed in — notes syncing to your account'),
        ),
      );
    } catch (e) {
      final message = e.toString();
      final friendly = message.contains('keychain')
          ? 'Sign-in failed: macOS keychain access is missing. '
              'Rebuild the app after enabling Keychain Sharing '
              '(DebugProfile/Release.entitlements).'
          : 'Sign-in failed: $e';
      messenger.showSnackBar(SnackBar(content: Text(friendly)));
    }
  }
}