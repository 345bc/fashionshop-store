import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../main.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 80,
                color: AppTheme.danger,
              ),
              const SizedBox(height: 24),
              Text(
                'Từ chối truy cập',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn không có quyền truy cập vào chức năng này.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  MainScreen.of(context).navigate('/');
                },
                icon: const Icon(Icons.home),
                label: const Text('Về trang chủ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
