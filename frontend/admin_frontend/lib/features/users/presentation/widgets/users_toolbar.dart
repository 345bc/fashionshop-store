// GENERATED FROM TEMPLATE: templates/feature_toolbar.dart.template
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../providers/users_provider.dart';
import 'dart:async';

class UsersToolbar extends StatefulWidget {
  const UsersToolbar({super.key});

  @override
  State<UsersToolbar> createState() => _UsersToolbarState();
}

class _UsersToolbarState extends State<UsersToolbar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  static const Map<String, String> _roleMap = {
    'Tất cả': 'ALL',
    'Super Admin': 'SUPER_ADMIN',
    'Admin': 'ADMIN',
    'Manager': 'EMPLOYEE',
    'Viewer': 'USER',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final provider = context.read<UsersProvider>();
      provider.loadItems(query: query, role: provider.currentRole, page: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();
    
    // Sync search controller if needed
    if (_searchController.text != (provider.currentQuery ?? '')) {
      _searchController.text = provider.currentQuery ?? '';
    }

    String currentRoleName = 'Tất cả';
    _roleMap.forEach((key, value) {
      if (value == provider.currentRole || (value == 'ALL' && provider.currentRole == null)) {
        currentRoleName = key;
      }
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc email...',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filters
          _buildFilterDropdown(
            'Vai trò', 
            _roleMap.keys.toList(),
            currentRoleName,
            (String? newValue) {
              if (newValue != null) {
                provider.loadItems(
                  role: _roleMap[newValue],
                  query: provider.currentQuery,
                  page: 0,
                );
              }
            }
          ),
          const SizedBox(width: 16),
          // Reset Filter
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              provider.loadItems(query: '', role: 'ALL', page: 0);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Làm mới'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> options, String currentValue, ValueChanged<String?> onChanged) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textSecondary),
          style: const TextStyle(color: AppTheme.text, fontSize: 14, fontWeight: FontWeight.w500),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

