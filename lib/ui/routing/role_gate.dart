import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/providers/auth_provider.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({super.key, required this.role, required this.child});

  final AppRole role;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);
    return profileState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Không thể xác định quyền: $error')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (profile.role == role) return child;

        final target = profile.isManager ? '/manager/approvals' : '/dashboard';
        return _RoleRedirect(target: target);
      },
    );
  }
}

class _RoleRedirect extends StatefulWidget {
  const _RoleRedirect({required this.target});

  final String target;

  @override
  State<_RoleRedirect> createState() => _RoleRedirectState();
}

class _RoleRedirectState extends State<_RoleRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(widget.target);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
