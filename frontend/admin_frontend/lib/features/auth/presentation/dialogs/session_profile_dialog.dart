import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../../core/security/role_access.dart';
import '../../../../widgets/dialogs/zella_dialog.dart';
import '../../data/models/user_model.dart';
import '../provider/auth_provider.dart';

class SessionProfileDialog extends StatefulWidget {
  const SessionProfileDialog({super.key});
  @override
  State<SessionProfileDialog> createState() => _SessionProfileDialogState();
}

class _SessionProfileDialogState extends State<SessionProfileDialog> {
  late Future<UserModel> _profile;
  @override
  void initState() {
    super.initState();
    _profile = context.read<AuthProvider>().loadSessionProfile();
  }

  Widget _field(String label, String value, {bool emphasized = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 5),
            SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => ZellaDialog(
    width: 460,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hồ sơ phiên làm việc',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Đóng',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Symbols.close, size: 20),
            ),
          ],
        ),
        const Divider(height: 24),
        Flexible(
          child: SingleChildScrollView(
            child: FutureBuilder<UserModel>(
              future: _profile,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Không tải được hồ sơ phiên làm việc.'),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        icon: const Icon(Symbols.refresh),
                        label: const Text('Thử lại'),
                        onPressed: () {
                          final profile = context.read<AuthProvider>().loadSessionProfile();
                          setState(() { _profile = profile; });
                        },
                      ),
                    ],
                  );
                }
                final user = snapshot.requireData;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field('Tên đăng nhập', user.username, emphasized: true),
                    _field('Email', user.email),
                    _field('Mã tài khoản', '${user.id}'),
                    const Divider(height: 20),
                    _field(
                      'Vai trò đang sử dụng',
                      RoleAccess.labels[user.activeRole] ??
                          user.activeRole ??
                          'Chưa chọn',
                      emphasized: true,
                    ),
                    _field(
                      'Vai trò được cấp',
                      user.roles
                          .map((role) => RoleAccess.labels[role] ?? role)
                          .join(', '),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
