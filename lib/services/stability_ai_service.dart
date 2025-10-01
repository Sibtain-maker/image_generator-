// Non-functional change: Added this comment to enable a Git commit. No logic or behavior was modified.
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/stability_ai_models.dart';

class StabilityAIService {
  static const String baseUrl =
      'https://api.stability.ai/v2beta/stable-image/generate';
  static const String coreEndpoint = '/core';

  final Dio _dio;
  final String _apiKey;

  StabilityAIService({required String apiKey})
    : _apiKey = apiKey,
      _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Authorization': 'Bearer $_apiKey',
      'Accept': 'image/*',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 2);
  }

  Future<StabilityAIResponse> generateImage(StabilityAIRequest request) async {
    try {
      final formData = FormData.fromMap(request.toFormData());

      final response = await _dio.post(
        coreEndpoint,
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.data;
        final String base64Image = base64Encode(imageBytes);

        return StabilityAIResponse(
          imageBase64: base64Image,
          seed: request.seed,
        );
      } else {
        throw StabilityAIError(
          message: 'Failed to generate image: ${response.statusCode}',
          code: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          final errorData = json.decode(e.response!.data);
          throw StabilityAIError.fromJson(errorData);
        } catch (_) {
          throw StabilityAIError(
            message: 'Network error: ${e.message}',
            code: e.response?.statusCode,
          );
        }
      } else {
        throw StabilityAIError(
          message: 'Network error: ${e.message ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw StabilityAIError(message: 'Unexpected error: ${e.toString()}');
    }
  }

  static List<String> getAvailableAspectRatios() {
    return ['21:9', '16:9', '3:2', '5:4', '1:1', '4:5', '2:3', '9:16', '9:21'];
  }

  static List<String> getOutputFormats() {
    return ['png', 'jpeg'];
  }
}
