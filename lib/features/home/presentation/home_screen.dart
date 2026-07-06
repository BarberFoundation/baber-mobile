import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/tenancy/tenant_storage.dart';

class HomeScreen extends StatelessWidget {
  final TokenStorage tokenStorage;
  final TenantStorage tenantStorage;
  final String? userName;

  const HomeScreen({
    super.key,
    required this.tokenStorage,
    required this.tenantStorage,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await tokenStorage.clear();
              await tenantStorage.clear();
              if (context.mounted) context.go('/tenant-selection');
            },
          ),
        ],
      ),
      body: Center(child: Text('Bem-vindo, ${userName ?? ''}')),
    );
  }
}
