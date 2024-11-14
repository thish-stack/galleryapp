import 'dart:io';

class MediaFile {
  final File file;
  final bool isVideo;
  final String? thumbnailPath;

  MediaFile({required this.file, required this.isVideo, this.thumbnailPath});
}
