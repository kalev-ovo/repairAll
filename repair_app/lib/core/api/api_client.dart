import 'package:dio/dio.dart';
import 'package:repair_app/core/auth/auth_manager.dart';

class ApiClient {
  // Android 模拟器: http://10.0.2.2:8080
  // Chrome/Web:    http://localhost:8080
  // 真机:          通过 --dart-define=SERVER_URL=http://IP:8080 指定
  //                或修改下方 _defaultBaseUrl
  static const String _defaultBaseUrl = 'http://localhost:8080/api/v1';
  static const String _baseUrl = String.fromEnvironment('SERVER_URL', defaultValue: _defaultBaseUrl);

  late final Dio dio;

  ApiClient({required AuthManager authManager}) {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await authManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // 便捷方法
  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);

  // 上传文件（FormData multipart）
  Future<Response> upload(String path, {required String filePath, String fieldName = 'file'}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return dio.post(path, data: formData, options: Options(
      contentType: 'multipart/form-data',
    ));
  }
}
