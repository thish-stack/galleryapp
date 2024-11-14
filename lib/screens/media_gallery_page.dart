import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_file.dart';
import '../services/media_service.dart';
import '../services/storage_service.dart';
import 'media_detail_screen.dart';

class MediaGalleryPage extends StatefulWidget {
  const MediaGalleryPage({Key? key}) : super(key: key);

  @override
  _MediaGalleryPageState createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage> {
  final MediaService _mediaService = MediaService();
  final StorageService _storageService = StorageService();

  List<MediaFile> _mediaFiles = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
  List<File> files = await _storageService.loadMediaFiles();
  List<MediaFile> loadedMedia = [];

  for (File file in files) {
    bool isVideo = file.path.endsWith('.mp4') || file.path.endsWith('.mkv');
    String? thumbnail = isVideo ? await _mediaService.generateThumbnail(file) : null;
    loadedMedia.add(MediaFile(file: file, isVideo: isVideo, thumbnailPath: thumbnail));
  }

  // Remove duplicates by file name and update the state
  _mediaFiles = _removeDuplicateMedia(loadedMedia);
  setState(() {});
}

Future<void> _pickMedia() async {
  List<File> files = await _mediaService.pickMediaFiles();

  for (File file in files) {
    // Check for duplicates by file name (not full path)
    String fileName = file.uri.pathSegments.last;
    if (_mediaFiles.any((media) => media.file.uri.pathSegments.last == fileName)) continue;

    bool isVideo = file.path.endsWith('.mp4') || file.path.endsWith('.mkv');
    String? thumbnail = isVideo ? await _mediaService.generateThumbnail(file) : null;
    _mediaFiles.add(MediaFile(file: file, isVideo: isVideo, thumbnailPath: thumbnail));
  }

  // Save the updated list and refresh UI
  await _storageService.saveMediaFiles(_mediaFiles.map((m) => m.file).toList());
  setState(() {});
}

List<MediaFile> _removeDuplicateMedia(List<MediaFile> mediaFiles) {
  Map<String, MediaFile> uniqueMedia = {};
  
  for (var media in mediaFiles) {
    // Use the file name to identify duplicates
    String fileName = media.file.uri.pathSegments.last;
    uniqueMedia[fileName] = media; // If a duplicate file name exists, it will overwrite the previous entry
  }

  return uniqueMedia.values.toList();
}

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Media'),
        content: const Text('Are you sure you want to delete all media files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteAllMedia();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllMedia() async {
    await _storageService.clearMediaFiles();
    setState(() {
      _mediaFiles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
      ),
      body: ReorderableBuilder(
        scrollController: _scrollController,
        onReorder: (reorderFunction) {
          setState(() {
            _mediaFiles = reorderFunction(_mediaFiles) as List<MediaFile>;
          });
          _storageService.saveMediaFiles(_mediaFiles.map((m) => m.file).toList());
        },
        builder: (children) {
          return GridView(
            key: _gridViewKey,
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            children: children,
          );
        },
        children: List.generate(_mediaFiles.length, (index) {
          final media = _mediaFiles[index];
          return GestureDetector(
            key: ValueKey(media.file.path),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediaDetailScreen(mediaFile: media),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: media.isVideo && media.thumbnailPath != null
                      ? Image.file(File(media.thumbnailPath!), fit: BoxFit.cover)
                      : Image.file(media.file, fit: BoxFit.cover),
                ),
                if (media.isVideo)
                  const Center(
                    child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                  ),
              ],
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickMedia,
        child: const Icon(Icons.add),
      ),
    );
  }
}
