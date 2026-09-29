import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'rqf1hlrx';
  static const String uploadPreset = 'autoparts_unsigned';

  // Upload an image file directly to Cloudinary and return the secure HTTPS URL
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
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
