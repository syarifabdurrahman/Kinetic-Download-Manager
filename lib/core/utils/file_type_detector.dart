import 'package:dio/dio.dart';

enum FileCategory { video, audio, document, image, archive, executable, other }

class FileTypeDetector {
  final Dio _dio = Dio();

  static final Map<RegExp, FileCategory> _extensionMap = {
    RegExp(r'\.(mp4|mkv|avi|mov|wmv|flv|webm|m4v)$', caseSensitive: false): FileCategory.video,
    RegExp(r'\.(mp3|wav|flac|aac|ogg|wma|m4a|opus)$', caseSensitive: false): FileCategory.audio,
    RegExp(r'\.(pdf|doc|docx|xls|xlsx|ppt|pptx|txt|csv|epub)$', caseSensitive: false): FileCategory.document,
    RegExp(r'\.(jpg|jpeg|png|gif|bmp|webp|svg|ico)$', caseSensitive: false): FileCategory.image,
    RegExp(r'\.(zip|rar|7z|tar|gz|bz2|xz|iso)$', caseSensitive: false): FileCategory.archive,
    RegExp(r'\.(exe|msi|apk|dmg|deb|rpm|bin)$', caseSensitive: false): FileCategory.executable,
  };

  static final Map<FileCategory, String> _categoryLabels = {
    FileCategory.video: 'VIDEO',
    FileCategory.audio: 'AUDIO',
    FileCategory.document: 'DOCUMENT',
    FileCategory.image: 'IMAGE',
    FileCategory.archive: 'ARCHIVE',
    FileCategory.executable: 'APP',
    FileCategory.other: 'FILE',
  };

  static final Map<String, FileCategory> _mimeMap = {
    'video/mp4': FileCategory.video,
    'video/x-matroska': FileCategory.video,
    'video/avi': FileCategory.video,
    'video/quicktime': FileCategory.video,
    'video/x-ms-wmv': FileCategory.video,
    'video/webm': FileCategory.video,
    'audio/mpeg': FileCategory.audio,
    'audio/wav': FileCategory.audio,
    'audio/flac': FileCategory.audio,
    'audio/aac': FileCategory.audio,
    'audio/ogg': FileCategory.audio,
    'application/pdf': FileCategory.document,
    'application/msword': FileCategory.document,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': FileCategory.document,
    'application/vnd.ms-excel': FileCategory.document,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': FileCategory.document,
    'text/plain': FileCategory.document,
    'text/csv': FileCategory.document,
    'image/jpeg': FileCategory.image,
    'image/png': FileCategory.image,
    'image/gif': FileCategory.image,
    'image/webp': FileCategory.image,
    'image/svg+xml': FileCategory.image,
    'application/zip': FileCategory.archive,
    'application/x-rar-compressed': FileCategory.archive,
    'application/x-7z-compressed': FileCategory.archive,
    'application/gzip': FileCategory.archive,
    'application/x-tar': FileCategory.archive,
  };

  String getCategoryLabel(FileCategory category) => _categoryLabels[category] ?? 'FILE';

  String? extractFileName(String url, String? contentDisposition) {
    if (contentDisposition != null) {
      final regex = RegExp(r'filename[^;=\n]*=([^;\n]+)');
      final match = regex.firstMatch(contentDisposition);
      if (match != null) {
        var name = match.group(1)?.trim() ?? '';
        if (name.startsWith('"') && name.endsWith('"')) {
          name = name.substring(1, name.length - 1);
        } else if (name.startsWith("'") && name.endsWith("'")) {
          name = name.substring(1, name.length - 1);
        }
        return name;
      }
    }
    try {
      final uri = Uri.parse(url);
      final path = uri.pathSegments.where((s) => s.isNotEmpty);
      return path.isNotEmpty ? path.last : null;
    } catch (_) {
      return null;
    }
  }

  FileCategory categoryFromExtension(String url) {
    for (final entry in _extensionMap.entries) {
      if (entry.key.hasMatch(url)) return entry.value;
    }
    return FileCategory.other;
  }

  FileCategory categoryFromMime(String mime) {
    return _mimeMap[mime] ?? FileCategory.other;
  }

  Future<UrlInfo> detectFromUrl(String url) async {
    final extCategory = categoryFromExtension(url);
    String? fileName = extractFileName(url, null);
    String? mimeType;

    try {
      final response = await _dio.head(
        Uri.encodeFull(url),
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      mimeType = response.headers.value('content-type')?.split(';').first;
      final disposition = response.headers.value('content-disposition');
      if (disposition != null) {
        fileName ??= extractFileName(url, disposition);
      }
    } catch (_) {}

    final mimeCategory = mimeType != null ? categoryFromMime(mimeType) : null;
    final category = mimeCategory ?? extCategory;

    if (fileName == null && url.isNotEmpty) {
      fileName = 'download_${DateTime.now().millisecondsSinceEpoch}';
      final ext = _extensionForCategory(category);
      if (ext != null) fileName += ext;
    }

    return UrlInfo(
      fileName: fileName!,
      category: category,
      mimeType: mimeType,
    );
  }

  String? _extensionForCategory(FileCategory category) {
    switch (category) {
      case FileCategory.video: return '.mp4';
      case FileCategory.audio: return '.mp3';
      case FileCategory.document: return '.pdf';
      case FileCategory.image: return '.jpg';
      case FileCategory.archive: return '.zip';
      case FileCategory.executable: return '.bin';
      case FileCategory.other: return null;
    }
  }
}

class UrlInfo {
  final String fileName;
  final FileCategory category;
  final String? mimeType;

  const UrlInfo({
    required this.fileName,
    required this.category,
    this.mimeType,
  });
}
