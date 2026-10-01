import 'package:dio/dio.dart';

import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import 'attribute_kind.dart';

class AttributeRepository {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getAll(AttributeKind kind) async {
    try {
      final response = await _api.get(kind.path);
      return (response.data['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> getById(AttributeKind kind, int id) async {
    try {
      final response = await _api.get('${kind.path}/$id');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> create(
    AttributeKind kind,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _api.post(kind.path, data: data);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> uploadSizeGuideImage(
    int id,
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      final response = await _api.post(
        '/sizeguide/$id/image',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName),
        }),
      );
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<Map<String, dynamic>> removeSizeGuideImage(int id) async {
    try {
      final response = await _api.delete('/sizeguide/$id/image');
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<void> update(
    AttributeKind kind,
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _api.put('${kind.path}/$id', data: data);
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Future<void> delete(AttributeKind kind, int id) async {
    try {
      await _api.delete('${kind.path}/$id');
    } on DioException catch (error) {
      _throwMessage(error);
    }
  }

  Never _throwMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      throw Exception(data['message'] ?? data['error'] ?? error.message);
    }
    throw error;
  }
}
