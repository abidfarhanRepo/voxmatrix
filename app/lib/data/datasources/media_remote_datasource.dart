import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:injectable/injectable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxmatrix/core/error/exceptions.dart';
import 'package:voxmatrix/core/error/failures.dart';

/// Media remote datasource - handles Matrix Media Repository API
/// See: https://spec.matrix.org/v1.11/client-server-api/#content-repository
@injectable
class MediaRemoteDataSource {
  const MediaRemoteDataSource(this._logger);

  final Logger _logger;
  ImagePicker get _imagePicker => ImagePicker();

  /// Get the _matrix media URL for a homeserver
  String _getMediaUrl(String homeserver) {
    final cleanUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl/_matrix/media/v3';
  }

  /// Convert mxc:// URL to http:// URL
  String mxcToHttp(String mxcUrl, String homeserver) {
    if (!mxcUrl.startsWith('mxc://')) {
      return mxcUrl;
    }

    final parts = mxcUrl.substring(6).split('/');
    if (parts.length != 2) {
      return mxcUrl;
    }

    final server = parts[0];
    final mediaId = parts[1];

    final baseUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$baseUrl/_matrix/media/v3/download/$server/$mediaId';
  }

  /// Convert mxc:// URL to http:// thumbnail URL
  String mxcToThumbnail(
    String mxcUrl,
    String homeserver, {
    int width = 256,
    int height = 256,
    String method = 'scale',
  }) {
    if (!mxcUrl.startsWith('mxc://')) {
      return mxcUrl;
    }

    final parts = mxcUrl.substring(6).split('/');
    if (parts.length != 2) {
      return mxcUrl;
    }

    final server = parts[0];
    final mediaId = parts[1];

    final baseUrl = homeserver.replaceAll(RegExp(r'/+$'), '');
    return '$baseUrl/_matrix/media/v3/thumbnail/$server/$mediaId?width=$width&height=$height&method=$method';
  }

  /// Pick an image from gallery or camera
  Future<Either<Failure, File>> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        return const Left(ValidationFailure(
          message: 'No image selected',
          statusCode: 400,
        ));
      }

      final file = File(pickedFile.path);
      return Right(file);
    } catch (e, stackTrace) {
      _logger.e('Error picking image', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to pick image'));
    }
  }

  /// Pick multiple images
  Future<Either<Failure, List<File>>> pickMultipleImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();

      if (pickedFiles.isEmpty) {
        return const Left(ValidationFailure(
          message: 'No images selected',
          statusCode: 400,
        ));
      }

      final files = pickedFiles.map((xfile) => File(xfile.path)).toList();
      return Right(files);
    } catch (e, stackTrace) {
      _logger.e('Error picking images', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to pick images'));
    }
  }

  /// Pick a video
  Future<Either<Failure, File>> pickVideo({
    required ImageSource source,
  }) async {
    try {
      final pickedFile = await _imagePicker.pickVideo(source: source);

      if (pickedFile == null) {
        return const Left(ValidationFailure(
          message: 'No video selected',
          statusCode: 400,
        ));
      }

      final file = File(pickedFile.path);
      return Right(file);
    } catch (e, stackTrace) {
      _logger.e('Error picking video', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: 'Failed to pick video'));
    }
  }

  /// Upload a file to Matrix content repository
  /// POST /_matrix/media/v3/upload
  Future<Either<Failure, Map<String, dynamic>>> uploadFile({
    required String homeserver,
    required String accessToken,
    required File file,
    String? filename,
    String? contentType,
  }) async {
    try {
      final baseUrl = _getMediaUrl(homeserver);
      final uri = Uri.parse('$baseUrl/upload');

      // Read file bytes
      final bytes = await file.readAsBytes();

      // Determine content type
      final mimeType = contentType ?? _getMimeType(file.path);

      // Determine filename
      final name = filename ?? file.path.split('/').last;

      _logger.i('Uploading file: $name (${bytes.length} bytes)');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: name,
          contentType: http_parser.MediaType.parse(mimeType),
        ));

      final response = await request.send().timeout(
        const Duration(minutes: 5),
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        _logger.i('File uploaded: ${data['content_uri']}');
        return Right(data);
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
        throw ServerException(
          message: 'Upload failed',
          statusCode: response.statusCode,
        );
      }
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error uploading file', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Download a file from Matrix content repository
  /// GET /_matrix/media/v3/download/{serverName}/{mediaId}
  Future<Either<Failure, File>> downloadFile({
    required String homeserver,
    required String mxcUrl,
    String? savePath,
  }) async {
    try {
      final downloadUrl = mxcToHttp(mxcUrl, homeserver);
      final uri = Uri.parse(downloadUrl);

      _logger.i('Downloading file from: $downloadUrl');

      final response = await http.get(uri).timeout(
        const Duration(minutes: 5),
      );

      if (response.statusCode == 200) {
        // Determine save path
        String path = savePath ?? await _getTemporaryFilePath(mxcUrl);

        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);

        _logger.i('File downloaded to: $path');
        return Right(file);
      } else if (response.statusCode == 404) {
        throw ServerException(
          message: 'File not found',
          statusCode: response.statusCode,
        );
      } else {
        throw ServerException(
          message: 'Download failed',
          statusCode: response.statusCode,
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on http.ClientException catch (e) {
      return Left(NetworkFailure(message: 'Network error: ${e.message}'));
    } catch (e, stackTrace) {
      _logger.e('Error downloading file', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get file info from mxc:// URL
  Future<Either<Failure, Map<String, dynamic>>> getFileInfo({
    required String homeserver,
    required String mxcUrl,
  }) async {
    try {
      // Use the thumbnail endpoint to get info
      final thumbnailUrl = mxcToThumbnail(
        mxcUrl,
        homeserver,
        width: 32,
        height: 32,
      );
      final uri = Uri.parse(thumbnailUrl);

      final response = await http.head(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        final contentLength = response.headers['content-length'];

        return Right({
          'mimeType': contentType,
          'size': contentLength != null ? int.tryParse(contentLength) : null,
          'url': mxcToHttp(mxcUrl, homeserver),
        });
      } else {
        return const Left(ServerFailure(message: 'Failed to get file info'));
      }
    } catch (e, stackTrace) {
      _logger.e('Error getting file info', error: e, stackTrace: stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    const mimeTypes = {
      // Images
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'bmp': 'image/bmp',
      // Videos
      'mp4': 'video/mp4',
      'webm': 'video/webm',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      // Audio
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'flac': 'audio/flac',
      'm4a': 'audio/mp4',
      // Documents
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'json': 'application/json',
      'xml': 'application/xml',
      // Archives
      'zip': 'application/zip',
      'rar': 'application/vnd.rar',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  /// Get a temporary file path for download
  Future<String> _getTemporaryFilePath(String mxcUrl) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = mxcUrl.replaceAll('/', '_').replaceAll(':', '_');
    return '${tempDir.path}/$fileName';
  }

  /// Get cached file path
  Future<String> getCachedFilePath(String mxcUrl) async {
    final cacheDir = await getTemporaryDirectory();
    final cacheSubDir = Directory('${cacheDir.path}/matrix_cache');
    if (!await cacheSubDir.exists()) {
      await cacheSubDir.create(recursive: true);
    }

    final fileName = mxcUrl.replaceAll('/', '_').replaceAll(':', '_');
    return '${cacheSubDir.path}/$fileName';
  }

  /// Check if file is cached
  Future<bool> isFileCached(String mxcUrl) async {
    try {
      final path = await getCachedFilePath(mxcUrl);
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }
}
