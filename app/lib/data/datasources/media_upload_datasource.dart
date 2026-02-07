import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';
import 'package:path/path.dart' as path;

/// Media upload remote datasource - implements Matrix Media Repository API
/// See: https://spec.matrix.org/v1.11/client-server-api/#uploading-content
@injectable
class MediaUploadDataSource {
  const MediaUploadDataSource(this._logger);

  final Logger _logger;

  /// Get the _matrix media URL for a homeserver
  String _getMediaUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/media/v3';
  }

  /// Upload a file to the media repository
  /// POST /_matrix/media/v3/upload
  Future<Either<Failure, MediaUploadResponse>> uploadFile({
    required String homeserver,
    required String accessToken,
    required File file,
    String? fileName,
    String? contentType,
  }) async {
    try {
      final baseUrl = _getMediaUrl(homeserver);
      final uri = Uri.parse('$baseUrl/upload');

      final name = fileName ?? path.basename(file.path);
      final bytes = await file.readAsBytes();

      // Create multipart request
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: name,
            contentType: contentType != null
                ? http_parser.MediaType.parse(contentType)
                : _getContentType(name),
          ),
        );

      // Add filename to query parameters
      request.fields['filename'] = name;

      _logger.i('Uploading file: $name (${bytes.length} bytes)');

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final uploadResponse = MediaUploadResponse(
          contentUri: data['content_uri'] as String,
        );
        _logger.i('File uploaded: ${uploadResponse.contentUri}');
        return Right(uploadResponse);
      } else if (response.statusCode == 401) {
        throw AuthException(
          message: 'Access token expired or invalid',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 413) {
        throw ServerException(
          message: 'File too large',
          statusCode: response.statusCode,
        );
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(
          message: error['error'] as String? ?? 'Failed to upload file',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e, stackTrace) {
      _logger.e('Error uploading file', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get the download URL for a Matrix media URI (mxc://)
  String getDownloadUrl({
    required String homeserver,
    required String mxcUri,
    bool allowDownload = true,
  }) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(mxcUri);
    final serverName = uri.authority;
    final mediaId = uri.path.substring(1); // Remove leading slash

    return '$cleanUrl/_matrix/media/v3/download/$serverName/$mediaId'
        '${allowDownload ? '?allow_download=true' : ''}';
  }

  /// Get the thumbnail URL for a Matrix media URI
  String getThumbnailUrl({
    required String homeserver,
    required String mxcUri,
    int width = 256,
    int height = 256,
    String method = 'scale',
  }) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(mxcUri);
    final serverName = uri.authority;
    final mediaId = uri.path.substring(1);

    return '$cleanUrl/_matrix/media/v3/thumbnail/$serverName/$mediaId'
        '?width=$width&height=$height&method=$method';
  }

  http_parser.MediaType _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return http_parser.MediaType('image', 'jpeg');
      case '.png':
        return http_parser.MediaType('image', 'png');
      case '.gif':
        return http_parser.MediaType('image', 'gif');
      case '.webp':
        return http_parser.MediaType('image', 'webp');
      case '.mp4':
        return http_parser.MediaType('video', 'mp4');
      case '.webm':
        return http_parser.MediaType('video', 'webm');
      case '.mp3':
        return http_parser.MediaType('audio', 'mpeg');
      case '.wav':
        return http_parser.MediaType('audio', 'wav');
      case '.ogg':
        return http_parser.MediaType('audio', 'ogg');
      case '.pdf':
        return http_parser.MediaType('application', 'pdf');
      case '.txt':
        return http_parser.MediaType('text', 'plain');
      default:
        return http_parser.MediaType('application', 'octet-stream');
    }
  }
}

/// Response from media upload
class MediaUploadResponse {
  const MediaUploadResponse({
    required this.contentUri,
  });

  /// The MXC URI of the uploaded content
  final String contentUri;
}
