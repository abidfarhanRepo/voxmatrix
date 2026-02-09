import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service for managing media upload progress and retries
@injectable
class UploadProgressService {
  UploadProgressService(this._logger);

  final Logger _logger;

  final Map<String, UploadProgress> _uploads = {};
  final _progressController = StreamController<Map<String, UploadProgress>>.broadcast();

  /// Stream of upload progress updates
  Stream<Map<String, UploadProgress>> get progressStream => _progressController.stream;

  /// Start tracking upload
  void startUpload(String uploadId, String fileName, int totalBytes) {
    _uploads[uploadId] = UploadProgress(
      uploadId: uploadId,
      fileName: fileName,
      totalBytes: totalBytes,
      uploadedBytes: 0,
      status: UploadStatus.uploading,
      startTime: DateTime.now(),
    );
    _notifyUpdate();
    _logger.d('Started upload: $uploadId');
  }

  /// Update upload progress
  void updateProgress(String uploadId, int uploadedBytes) {
    final upload = _uploads[uploadId];
    if (upload == null) return;

    _uploads[uploadId] = upload.copyWith(uploadedBytes: uploadedBytes);
    _notifyUpdate();
  }

  /// Mark upload as complete
  void completeUpload(String uploadId, String mxcUri) {
    final upload = _uploads[uploadId];
    if (upload == null) return;

    _uploads[uploadId] = upload.copyWith(
      status: UploadStatus.completed,
      mxcUri: mxcUri,
      endTime: DateTime.now(),
    );
    _notifyUpdate();
    _logger.i('Upload completed: $uploadId');

    // Remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _uploads.remove(uploadId);
      _notifyUpdate();
    });
  }

  /// Mark upload as failed
  void failUpload(String uploadId, String error, {int retryCount = 0}) {
    final upload = _uploads[uploadId];
    if (upload == null) return;

    _uploads[uploadId] = upload.copyWith(
      status: UploadStatus.failed,
      errorMessage: error,
      retryCount: retryCount,
      endTime: DateTime.now(),
    );
    _notifyUpdate();
    _logger.e('Upload failed: $uploadId - $error');
  }

  /// Retry failed upload
  void retryUpload(String uploadId) {
    final upload = _uploads[uploadId];
    if (upload == null || upload.status != UploadStatus.failed) return;

    _uploads[uploadId] = upload.copyWith(
      status: UploadStatus.uploading,
      uploadedBytes: 0,
      retryCount: upload.retryCount + 1,
      errorMessage: null,
      startTime: DateTime.now(),
      endTime: null,
    );
    _notifyUpdate();
    _logger.i('Retrying upload: $uploadId (attempt ${upload.retryCount + 1})');
  }

  /// Get upload progress
  UploadProgress? getProgress(String uploadId) => _uploads[uploadId];

  /// Get all active uploads
  List<UploadProgress> get activeUploads =>
      _uploads.values.where((u) => u.status == UploadStatus.uploading).toList();

  /// Get failed uploads
  List<UploadProgress> get failedUploads =>
      _uploads.values.where((u) => u.status == UploadStatus.failed).toList();

  void _notifyUpdate() {
    _progressController.add(Map.from(_uploads));
  }

  Future<void> dispose() async {
    await _progressController.close();
  }
}

/// Upload progress data
class UploadProgress {
  final String uploadId;
  final String fileName;
  final int totalBytes;
  final int uploadedBytes;
  final UploadStatus status;
  final String? mxcUri;
  final String? errorMessage;
  final int retryCount;
  final DateTime startTime;
  final DateTime? endTime;

  UploadProgress({
    required this.uploadId,
    required this.fileName,
    required this.totalBytes,
    required this.uploadedBytes,
    required this.status,
    this.mxcUri,
    this.errorMessage,
    this.retryCount = 0,
    required this.startTime,
    this.endTime,
  });

  double get progress => totalBytes > 0 ? uploadedBytes / totalBytes : 0.0;
  
  int get percentComplete => (progress * 100).round();

  Duration get uploadDuration => 
      (endTime ?? DateTime.now()).difference(startTime);

  UploadProgress copyWith({
    String? uploadId,
    String? fileName,
    int? totalBytes,
    int? uploadedBytes,
    UploadStatus? status,
    String? mxcUri,
    String? errorMessage,
    int? retryCount,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return UploadProgress(
      uploadId: uploadId ?? this.uploadId,
      fileName: fileName ?? this.fileName,
      totalBytes: totalBytes ?? this.totalBytes,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      status: status ?? this.status,
      mxcUri: mxcUri ?? this.mxcUri,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

enum UploadStatus {
  uploading,
  completed,
  failed,
}
