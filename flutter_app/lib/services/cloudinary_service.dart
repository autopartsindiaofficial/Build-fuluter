import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'rqf1hlrx';
  // Working verified preset in Cloudinary account rqf1hlrx
  static const String primaryPreset = 'autoparts_upload';
  static const List<String> fallbackPresets = [
    'autoparts_upload',
    'auto_parts_preset',
    'autoparts_unsigned',
  ];

  // Instance method accepting either a File or String file path
  Future<String?> uploadImage(dynamic imageInput) async {
    return upload(imageInput);
  }

  // Static upload method accepting File, String path, or base64
  static Future<String?> upload(dynamic imageInput) async {
    try {
      if (imageInput == null) return null;

      // If it is already a remote URL, return it directly
      if (imageInput is String && (imageInput.startsWith('http://') || imageInput.startsWith('https://'))) {
        return imageInput;
      }

      String? filePath;
      if (imageInput is File) {
        filePath = imageInput.path;
      } else if (imageInput is String) {
        filePath = imageInput;
      }

      if (filePath == null) return null;

      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      // Try presets in order
      for (final preset in fallbackPresets) {
        try {
          final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
          final request = http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = preset
            ..files.add(await http.MultipartFile.fromPath('file', filePath));

          final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
          if (streamedResponse.statusCode == 200) {
            final responseData = await streamedResponse.stream.toBytes();
            final responseString = utf8.decode(responseData);
            final jsonMap = jsonDecode(responseString) as Map<String, dynamic>;
            final secureUrl = jsonMap['secure_url'] as String?;
            if (secureUrl != null && secureUrl.isNotEmpty) {
              return secureUrl;
            }
          }
        } catch (_) {
          // Continue to next preset fallback
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Extract public_id from a Cloudinary image URL
  static String? extractPublicId(String url) {
    if (!url.contains('cloudinary.com')) return null;
    try {
      final uploadIndex = url.indexOf('/image/upload/');
      if (uploadIndex == -1) return null;
      final pathAfterUpload = url.substring(uploadIndex + '/image/upload/'.length);
      final segments = pathAfterUpload.split('/').where((s) => s.isNotEmpty).toList();

      final cleanSegments = <String>[];
      for (final s in segments) {
        if (s.contains(',') ||
            RegExp(r'^(c|w|h|q|f|e|b|r|a|dpr|fl|co|l|u|pg|so|eo|s|bo|o|x|y|g|p|m|t|ar|cs|d|ki|dl)_').hasMatch(s) ||
            RegExp(r'^v\d+$').hasMatch(s)) {
          continue;
        }
        cleanSegments.add(s);
      }

      if (cleanSegments.isEmpty) return null;
      var publicId = cleanSegments.join('/');
      final lastDot = publicId.lastIndexOf('.');
      if (lastDot != -1) {
        publicId = publicId.substring(0, lastDot);
      }
      return publicId.isNotEmpty ? publicId : null;
    } catch (_) {
      return null;
    }
  }

  // Delete a single image from Cloudinary / backend storage
  static Future<bool> deleteImage(String urlOrPublicId) async {
    return deleteImages([urlOrPublicId]);
  }

  // Delete multiple images from Cloudinary / backend storage
  static Future<bool> deleteImages(List<String> urlsOrPublicIds) async {
    if (urlsOrPublicIds.isEmpty) return true;

    final publicIds = <String>[];
    for (final item in urlsOrPublicIds) {
      if (item.isEmpty) continue;
      final extracted = extractPublicId(item) ?? item;
      if (extracted.isNotEmpty && !publicIds.contains(extracted)) {
        publicIds.add(extracted);
      }
    }

    if (publicIds.isEmpty) return true;

    try {
      // Direct call to local/proxy backend delete route
      final endpoints = [
        'http://localhost:3000/api/delete-cloudinary-image',
        'http://10.0.2.2:3000/api/delete-cloudinary-image',
        '/api/delete-cloudinary-image',
      ];

      for (final ep in endpoints) {
        try {
          final uri = Uri.tryParse(ep);
          if (uri == null) continue;
          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'publicIds': publicIds}),
          ).timeout(const Duration(seconds: 4));
          if (response.statusCode == 200) {
            return true;
          }
        } catch (_) {
          // Try next endpoint
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}
