import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database.dart';

class BackupService {
  static Future<String?> export() async {
    final data = await AppDatabase.exportAll();
    final json = jsonEncode(data);

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/walletmanage_backup_$timestamp.json');
    await file.writeAsString(json);

    await Share.shareXFiles([XFile(file.path)], text: '资产管家备份文件');
    return file.path;
  }

  static Future<bool> import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return false;

    final content = await File(result.files.single.path!).readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (data['assets'] == null || data['transactions'] == null) return false;

    await AppDatabase.importAll(data);
    return true;
  }
}
