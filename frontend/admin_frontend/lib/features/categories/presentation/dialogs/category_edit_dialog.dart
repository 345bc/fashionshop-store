import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';

class CategoryEditDialog extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryEditDialog({super.key, required this.category});

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _parentIdController;
  
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category['name']?.toString() ?? '');
    _slugController = TextEditingController(text: widget.category['slug']?.toString() ?? '');
    _parentIdController = TextEditingController(text: widget.category['parent_id']?.toString() ?? '');
    _isActive = widget.category['is_active'] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with API Call
      await Future.delayed(const Duration(seconds: 1)); // Mock API delay
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật danh mục thành công')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: ZellaFormDialog(
          title: 'Sửa danh mục',
          formKey: _formKey,
          isLoading: _isLoading,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _submit,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Tên danh mục', 'Nhập tên danh mục...', _nameController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Đường dẫn (Slug)', 'vd: ao-khoac-nam', _slugController, required: true),
              const SizedBox(height: 16),
              _buildTextField('ID Danh mục cha', 'Tuỳ chọn (Để trống nếu là cấp 1)', _parentIdController, isNumber: true, required: false),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trạng thái', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_isActive ? 'Hoạt động' : 'Ẩn', style: const TextStyle(fontSize: 14)),
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool required = true, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
            if (required) 
              const Text(' *', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
          validator: required ? (value) {
            if (value == null || value.isEmpty) {
              return 'Bắt buộc';
            }
            if (isNumber && double.tryParse(value) == null) {
              return 'Phải là số';
            }
            return null;
          } : (value) {
             if (value != null && value.isNotEmpty && isNumber && double.tryParse(value) == null) {
               return 'Phải là số';
             }
             return null;
          },
        ),
      ],
    );
  }
}
