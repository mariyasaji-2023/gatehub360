import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart' show ApiException;

/// A [MultipartRequest] that reports how many of its bytes have actually
/// been sent over the wire - the base class gives no way to observe this,
/// so this overrides the byte stream it hands to the client with one that
/// counts as it passes through. Used to show real upload progress for
/// property videos, which can take a while on mobile data.
class _ProgressMultipartRequest extends http.MultipartRequest {
  final void Function(double progress)? onProgress;
  _ProgressMultipartRequest(super.method, super.url, {this.onProgress});

  @override
  http.ByteStream finalize() {
    final total = contentLength;
    var sent = 0;
    final stream = super.finalize().transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (chunk, sink) {
          sent += chunk.length;
          if (total > 0) onProgress?.call(sent / total);
          sink.add(chunk);
        },
      ),
    );
    return http.ByteStream(stream);
  }
}

/// Uploads property videos straight from the phone to Cloudinary, bypassing
/// our own backend entirely - see the comment on [cloudinaryCloudName] for
/// why. Only the returned hosted URL ever reaches the database.
class CloudinaryApi {
  CloudinaryApi._();

  static Future<String> uploadVideo(File file, {void Function(double progress)? onProgress}) async {
    if (cloudinaryCloudName == 'YOUR_CLOUD_NAME' || cloudinaryUploadPreset == 'YOUR_UPLOAD_PRESET') {
      throw ApiException('Video upload isn\'t set up yet — add your Cloudinary cloud name and upload preset in api_config.dart');
    }

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/video/upload');
    final request = _ProgressMultipartRequest('POST', uri, onProgress: onProgress)
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
