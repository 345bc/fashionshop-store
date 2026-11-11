import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zella_admin_flutter/features/users/data/api/users_repository.dart';
import 'package:zella_admin_flutter/features/users/presentation/providers/users_provider.dart';

class FilterRepository extends UsersRepository {
  final calls = <({int page, String? query, String? role, bool? active})>[];
  final pending = <Completer<Map<String, dynamic>>>[];
  bool delay = false;
  @override
  Future<Map<String, dynamic>> getAll({
    int page = 0,
    int size = 15,
    String? query,
    String? role,
    bool? active,
  }) async {
    calls.add((page: page, query: query, role: role, active: active));
    if (delay) {
      final completer = Completer<Map<String, dynamic>>();
      pending.add(completer);
      return completer.future;
    }
    return {'content': [], 'totalElements': 0, 'number': page};
  }
}

void main() {
  setUpAll(
    () => dotenv.loadFromString(
      envString: 'API_BASE_URL=http://localhost:8080/api/v1',
    ),
  );
  test(
    'search, role and status persist across pages and reset independently',
    () async {
      final repository = FilterRepository();
      final provider = UsersProvider(repository: repository);
      await provider.loadItems(query: 'tuan', role: 'ADMIN', status: 'LOCKED');
      await provider.loadItems(page: 2);
      expect(repository.calls.last, (
        page: 2,
        query: 'tuan',
        role: 'ADMIN',
        active: false,
      ));
      await provider.loadItems(status: 'ALL');
      expect(repository.calls.last, (
        page: 0,
        query: 'tuan',
        role: 'ADMIN',
        active: null,
      ));
      await provider.loadItems(role: 'ALL', status: 'ACTIVE');
      expect(repository.calls.last, (
        page: 0,
        query: 'tuan',
        role: null,
        active: true,
      ));
      provider.dispose();
    },
  );
  test('older filter requests cannot overwrite newer results', () async {
    final repository = FilterRepository()..delay = true;
    final provider = UsersProvider(repository: repository);
    final first = provider.loadItems(status: 'ACTIVE');
    final second = provider.loadItems(status: 'LOCKED');
    repository.pending[1].complete({
      'content': [],
      'totalElements': 4,
      'number': 0,
    });
    await second;
    repository.pending[0].complete({
      'content': [],
      'totalElements': 9,
      'number': 0,
    });
    await first;
    expect(provider.totalElements, 4);
    expect(provider.currentStatus, 'LOCKED');
    expect(provider.isLoading, false);
    provider.dispose();
  });
}
