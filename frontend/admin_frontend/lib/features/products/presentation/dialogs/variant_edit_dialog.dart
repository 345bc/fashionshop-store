import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/dialogs/zella_form_dialog.dart';

class VariantEditDialog extends StatefulWidget {
  final Map<String, dynamic> variant;

  const VariantEditDialog({super.key, required this.variant});

  @override
  State<VariantEditDialog> createState() => _VariantEditDialogState();
}

class _VariantEditDialogState extends State<VariantEditDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _skuController;
  late TextEditingController _sizeIdController;
  late TextEditingController _colorIdController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _stockQuantityController;
  late TextEditingController _reservedQuantityController;
  late TextEditingController _model3dUrlController;
  
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.variant['sku']?.toString() ?? '');
    _sizeIdController = TextEditingController(text: widget.variant['size_id']?.toString() ?? '');
    _colorIdController = TextEditingController(text: widget.variant['color_id']?.toString() ?? '');
    _priceController = TextEditingController(text: widget.variant['price']?.toString() ?? '');
    _costPriceController = TextEditingController(text: widget.variant['cost_price']?.toString() ?? '');
    _stockQuantityController = TextEditingController(text: widget.variant['stock_quantity']?.toString() ?? '');
    _reservedQuantityController = TextEditingController(text: widget.variant['reserved_quantity']?.toString() ?? '');
    _model3dUrlController = TextEditingController(text: widget.variant['model_3d_url']?.toString() ?? '');
    _isActive = widget.variant['is_active'] == true;
  }

  @override
  void dispose() {
    _skuController.dispose();
    _sizeIdController.dispose();
    _colorIdController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockQuantityController.dispose();
    _reservedQuantityController.dispose();
    _model3dUrlController.dispose();
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
          const SnackBar(content: Text('Cập nhật biến thể thành công')),
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
        width: 600,
        padding: const EdgeInsets.all(24),
        child: ZellaFormDialog(
          title: 'Cập nhật biến thể',
          formKey: _formKey,
          isLoading: _isLoading,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: _submit,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField('SKU', 'Mã SKU duy nhất', _skuController, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Size ID', 'Nhập ID Size', _sizeIdController, isNumber: true, required: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField('Color ID', 'Nhập ID Color', _colorIdController, isNumber: true, required: true)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Trạng thái', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_isActive ? 'Đang hoạt động' : 'Ngừng hoạt động', style: const TextStyle(fontSize: 14)),
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeThumbColor: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField('Giá bán (VNĐ)', 'Nhập giá bán', _priceController, isNumber: true, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Giá vốn (VNĐ)', 'Nhập giá vốn', _costPriceController, isNumber: true, required: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField('Tồn kho', 'Số lượng hiện có', _stockQuantityController, isNumber: true, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField('Đã đặt trước', 'Số lượng reserved', _reservedQuantityController, isNumber: true, required: true)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('Model 3D URL', 'Link file .glb hoặc .gltf (Tuỳ chọn)', _model3dUrlController, required: false),
              ],
            ),
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
