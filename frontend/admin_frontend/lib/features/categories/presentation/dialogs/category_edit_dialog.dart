import 'package:flutter/material.dart';

import '../../data/models/category_response_model.dart';
import 'category_form_dialog.dart';

class CategoryEditDialog extends StatelessWidget {
  final CategoryResponseModel category;
  const CategoryEditDialog({super.key, required this.category});

  @override
  Widget build(BuildContext context) => CategoryFormDialog(category: category);
}
