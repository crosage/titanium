import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logger/logger.dart';
import 'package:photo_windows/pages/foldermanager_page.dart';
import 'package:photo_windows/pages/photomap_page.dart';

final logger = Logger();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) {
      return "PROXY 127.0.0.1:7890";
    };
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: '照片地图',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const PhotoMapScreen(),
    const FolderManagerScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text("照片管理"),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        displayMode: PaneDisplayMode.open,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.map_pin),
            title: const Text("照片地图"), body: _pages[0],
          ),
          PaneItem(
            icon: const Icon(FluentIcons.folder_open),
            title: const Text("管理文件夹"), body: _pages[1],
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text("设置"), body:_pages[2],
          ),
        ],
      ),
    );
  }
}


// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("设置界面"));
  }
}

