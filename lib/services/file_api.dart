import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'api_models.dart';
import 'auth_api.dart';

class FileApi {
  final ApiClient _client;
  FileApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// Upload file ke API, kembalikan FileModel (berisi id dan file_url).
  ///
  /// [fileType] harus salah satu dari:
  ///   check_in | check_out | profile_picture | sick | extra_off | overtime | leave
  Future<FileModel> upload(XFile file, String fileType) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
        'file_type': fileType,
      });
      final res = await _client.dio.post(
        '/files',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return FileModel.fromJson(unwrap(res));
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> delete(String fileId) async {
    try {
      await _client.dio.delete('/files/$fileId');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
