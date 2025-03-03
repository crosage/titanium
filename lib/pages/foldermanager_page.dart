import 'dart:convert';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class FolderManagerScreen extends StatefulWidget {
  const FolderManagerScreen({super.key});

  @override
  _FolderManagerScreenState createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends State<FolderManagerScreen> {
  List<String> folderPaths = [];
  TextEditingController _folderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFolderHistory();
  }

  Future<File> _getHistoryFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/folder_history.json');
  }

  Future<void> _loadFolderHistory() async {
    try {
      logger.i("尝试获取历史");
      File file = await _getHistoryFile();

      if (!await file.exists()) {
        logger.i("未存在历史config文件，正在创建");
        await file.writeAsString(json.encode([]));
      }

      String content = await file.readAsString();
      List<dynamic> jsonData = json.decode(content);
      setState(() {
        folderPaths = jsonData.cast<String>();
      });
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  Future<void> _saveFolderHistory() async {
    try {
      File file = await _getHistoryFile();
      await file.writeAsString(json.encode(folderPaths));
    } catch (e) {
      print("Error saving history: $e");
    }
  }

  void _addFolder() {
    String path = _folderController.text.trim();
    if (path.isNotEmpty && !folderPaths.contains(path)) {
      setState(() {
        folderPaths.add(path);
        _folderController.clear();
      });
      _saveFolderHistory();
    }
  }

  void _removeFolder(String path) {
    setState(() {
      folderPaths.remove(path);
    });
    _saveFolderHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text("管理文件夹")),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _folderController,
                    placeholder: "输入文件夹路径",
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(FluentIcons.add),
                  onPressed: _addFolder,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: folderPaths.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(folderPaths[index]),
                  trailing: IconButton(
                    icon: const Icon(FluentIcons.delete),
                    onPressed: () => _removeFolder(folderPaths[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
