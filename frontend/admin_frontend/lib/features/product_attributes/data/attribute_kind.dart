import 'package:flutter/material.dart';

enum AttributeKind {
  color('Màu sắc', 'Màu', '/color', Icons.palette_outlined),
  size('Size', 'Size', '/size', Icons.straighten_outlined),
  sizeGuide('Size Guide', 'Size Guide', '/sizeguide', Icons.menu_book_outlined);

  const AttributeKind(this.title, this.singular, this.path, this.icon);
  final String title;
  final String singular;
  final String path;
  final IconData icon;
}
