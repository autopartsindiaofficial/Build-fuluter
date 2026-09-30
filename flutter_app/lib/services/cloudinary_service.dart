import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'rqf1hlrx';
  static const String uploadPreset = 'autoparts_unsigned';

  // Instance method accepting either a File or String file path
  Future<String?> uploadImage(dynamic imageInput) async {
    return upload(imageInput);
  }

  // Static upload method accepting File, String path, or dynamic input
  static Future<String?> upload(dynamic imageInput) async {
    try {
      String filePath;
      if (imageInput is File) {
        filePath = imageInput.path;
      } else if (imageInput is String) {
        filePath = imageInput;
      } else {
        return null;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = utf8.decode(responseData);
        final jsonMap = jsonDecode(responseString) as Map<String, dynamic>;
        return jsonMap['secure_url'] as String?;
      } else {
        print('Cloudinary upload error with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Cloudinary upload exception: $e');
      return null;
    }
  }
}
