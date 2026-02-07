/// Media Manager for Matrix file upload/download
///
/// Handles uploading and downloading media files for Matrix messages
/// See: https://spec.matrix.org/v1.11/client-server-api/#module-content

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:voxmatrix/core/matrix/src/matrix_client.dart';
import 'package:voxmatrix/core/matrix/src/models/event.dart';

/// Media Manager for file upload/download
class MediaManager {
  /// Create a new media manager
  MediaManager({
    required this.client,
    required Logger logger,
  }) : _logger = logger;

  /// The Matrix client
  final MatrixClient client;

  /// Logger instance
  final Logger _logger;

  /// Upload a file to the Matrix homeserver
  ///
  /// [file] The file to upload
  /// [filename] Optional filename (defaults to the file's basename)
  /// [contentType] Optional content type (auto-detected if not provided)
  ///
  /// Returns the MXC URI of the uploaded file
  Future<String> uploadFile(
    File file, {
    String? filename,
    String? contentType,
  }) async {
    _logger.i('Uploading file: ${file.path}');

    final actualFilename = filename ?? path.basename(file.path);
    final actualContentType = contentType ?? _getContentType(actualFilename);

    // First, create a unique upload ID
    final uploadUrl = Uri.parse('${client.homeserver}/_matrix/media/v3/upload?filename=${Uri.encodeComponent(actualFilename)}');

    // Read the file
    final bytes = await file.readAsBytes();
    final fileRequest = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: actualFilename,
      contentType: http.MediaType.parse(actualContentType),
    );

    // Upload the file
    final request = http.MultipartRequest('POST', uploadUrl)
      ..files.add(fileRequest)
      ..headers['Authorization'] = 'Bearer ${client.accessToken}';

    final response = await request.send().timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final mxcUri = data['content_uri'] as String;
      _logger.i('File uploaded successfully: $mxcUri');
      return mxcUri;
    } else {
      throw MatrixException('Failed to upload file: ${response.statusCode}');
    }
  }

  /// Download a file from the Matrix homeserver
  ///
  /// [mxcUri] The MXC URI of the file (e.g., 'mxc://server.com/mediaId')
  /// [outputPath] The path to save the downloaded file
  Future<File> downloadFile(String mxcUri, String outputPath) async {
    _logger.i('Downloading file: $mxcUri');

    if (!mxcUri.startsWith('mxc://')) {
      throw ArgumentError('Invalid MXC URI: $mxcUri');
    }

    // Convert MXC to HTTP URL
    final httpUrl = _mxcToHttp(mxcUri);

    // Download the file
    final response = await http.get(Uri.parse(httpUrl)).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final file = File(outputPath);
      await file.writeAsBytes(response.bodyBytes);
      _logger.i('File downloaded successfully: $outputPath');
      return file;
    } else {
      throw MatrixException('Failed to download file: ${response.statusCode}');
    }
  }

  /// Get the HTTP URL for an MXC URI
  ///
  /// [mxcUri] The MXC URI (e.g., 'mxc://server.com/mediaId')
  String _mxcToHttp(String mxcUri) {
    if (!mxcUri.startsWith('mxc://')) {
      return mxcUri;
    }
    final parts = mxcUri.substring(6).split('/');
    if (parts.length >= 2) {
      return 'https://${parts[0]}/_matrix/media/v3/download/${parts[0]}/${parts[1]}';
    }
    return mxcUri;
  }

  /// Convert MXC URI to HTTP URL
  String mxcToHttp(String mxcUri) => _mxcToHttp(mxcUri);

  /// Upload image data
  Future<String> uploadImage(
    List<int> bytes, {
    required String filename,
    String? contentType,
  }) async {
    _logger.i('Uploading image: $filename');

    final actualContentType = contentType ?? 'image/jpeg';
    final uploadUrl = Uri.parse('${client.homeserver}/_matrix/media/v3/upload?filename=${Uri.encodeComponent(filename)}');

    final fileRequest = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: http.MediaType.parse(actualContentType),
    );

    final request = http.MultipartRequest('POST', uploadUrl)
      ..files.add(fileRequest)
      ..headers['Authorization'] = 'Bearer ${client.accessToken}';

    final response = await request.send().timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final mxcUri = data['content_uri'] as String;
      _logger.i('Image uploaded successfully: $mxcUri');
      return mxcUri;
    } else {
      throw MatrixException('Failed to upload image: ${response.statusCode}');
    }
  }

  /// Send an image message to a room
  Future<String> sendImageMessage(
    String roomId,
    String mxcUri, {
    String? filename,
    int? width,
    int? height,
    int? size,
  }) async {
    _logger.i('Sending image message to room: $roomId');

    final event = MatrixEvent(
      type: 'm.room.message',
      roomId: roomId,
      content: {
        'msgtype': 'm.image',
        'body': filename ?? 'Image',
        'url': mxcUri,
        'info': {
          'mimetype': 'image/jpeg',
          if (width != null) 'w': width,
          if (height != null) 'h': height,
          if (size != null) 'size': size,
          'thumbnail_url': mxcUri, // Use same URL for now
        },
      },
      txnId: client.generateTxnId(),
    );

    await client.sendEvent(event);
    // Note: The eventId will be assigned by the server after sending
    // We return the txnId as a fallback
    return event.eventId ?? event.txnId ?? '';
  }

  /// Get the content type for a file
  String _getContentType(String filename) {
    final extension = path.extension(filename).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.mp4':
        return 'video/mp4';
      case '.webm':
        return 'video/webm';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.ogg':
        return 'audio/ogg';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.json':
        return 'application/json';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  /// Dispose of the media manager
  Future<void> dispose() async {
    _logger.i('Media manager disposed');
  }
}
