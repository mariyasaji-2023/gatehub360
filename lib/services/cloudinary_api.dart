import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart' show ApiException;

/// Uploads property videos straight from the phone to Cloudinary, bypassing
/// our own backend entirely - see the comment on [cloudinaryCloudName] for
/// why. Only the returned hosted URL ever reaches the database.
class CloudinaryApi {
  CloudinaryApi._();

  static Future<String> uploadVideo(File file) async {
    if (cloudinaryCloudName == 'YOUR_CLOUD_NAME' || cloudinaryUploadPreset == 'YOUR_UPLOAD_PRESET') {
      throw ApiException('Video upload isn\'t set up yet — add your Cloudinary cloud name and upload preset in api_config.dart');
    }

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/video/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException('Video upload failed. Please try again.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (data['error'] as Map<String, dynamic>?)?['message'] as String?;
      throw ApiException(message ?? 'Video upload failed. Please try again.');
    }

    return data['secure_url'] as String;
  }
}
