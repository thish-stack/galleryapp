import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveMediaFiles(List<File> files) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> filePaths = files.map((file) => file.path).toList();
    await prefs.setStringList('mediaFiles', filePaths);
  }

  Future<List<File>> loadMediaFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? filePaths = prefs.getStringList('mediaFiles');
    return filePaths?.map((path) => File(path)).toList() ?? [];
  }

  Future<void> clearMediaFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('mediaFiles');
  }
}
