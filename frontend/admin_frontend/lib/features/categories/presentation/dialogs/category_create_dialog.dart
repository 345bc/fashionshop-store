import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';

class CategoryCreateDialog extends StatefulWidget {
  const CategoryCreateDialog({super.key});

  @override
  State<CategoryCreateDialog> createState() => _CategoryCreateDialogState();
}

class _CategoryCreateDialogState extends State<CategoryCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _parentIdController = TextEditingController();
  
  bool _isActive = true;
  bool _isLoading = false;

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
          const SnackBar(content: Text('Thêm danh mục thành công')),
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
          title: 'Thêm danh mục mới',
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
