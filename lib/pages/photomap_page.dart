import 'dart:convert';
import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:exif/exif.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PhotoMapScreen extends StatefulWidget {
  const PhotoMapScreen({super.key});

  @override
  _PhotoMapScreenState createState() => _PhotoMapScreenState();
}

class _PhotoMapScreenState extends State<PhotoMapScreen> {
  List<Map<String, dynamic>> photoMarkers = [];
  List<String> folderPaths = [];
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
      print(folderPaths);
      _loadPhotosFromFolders();
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  // 扫描所有文件夹
  Future<void> _loadPhotosFromFolders() async {
    List<Map<String, dynamic>> allPhotos = [];
    for (String folder in folderPaths) {
      List<Map<String, dynamic>> photos = await _getPhotosWithGPS(folder);
      allPhotos.addAll(photos);
    }
    setState(() {
      photoMarkers = allPhotos;
    });
  }

  bool _isImage(String path) {
    return path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.heic') ||
        path.toLowerCase().endsWith('.dng') ||
        path.toLowerCase().endsWith('.cr2') ||
        path.toLowerCase().endsWith('.nef');
  }

  Future<List<Map<String, dynamic>>> _getPhotosWithGPS(String folderPath) async {
    List<Map<String, dynamic>> markers = [];
    Directory dir = Directory(folderPath);
    if (!dir.existsSync()) return markers;
    List<FileSystemEntity> files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file is File && _isImage(file.path)) {
        var gpsData = await _getGPSFromExif(file);
        if (gpsData != null) {
          markers.add({'file': file.path, 'latlng': gpsData});
        }
      }
    }
    return markers;
  }
  String _cleanGpsString(String input) {
    var cleaned = input.replaceAll('[', '').replaceAll(']', '');
    cleaned = cleaned
        .replaceAll(' deg ', ' ')
        .replaceAll("'", ' ')
        .replaceAll('"', ' ')
        .trim();
    return cleaned;
  }
  double parseGpsValue(String s) {
    if (s.contains('/')) {
      var fractionParts = s.split('/');
      var numerator = double.parse(fractionParts[0]);
      var denominator = double.parse(fractionParts[1]);
      return numerator / denominator;
    } else {
      return double.parse(s);
    }
  }
  double _parseDmsToDecimal(String dmsString) {
    final parts = dmsString.split(RegExp(r'[, ]+'));
    if (parts.length < 3) {
      throw FormatException("GPS string format error: $dmsString");
    }
    final deg = parseGpsValue(parts[0]);
    final min = parseGpsValue(parts[1]);
    final sec = parseGpsValue(parts[2]);
    return deg + (min / 60.0) + (sec / 3600.0);
  }
  Future<LatLng?> _getGPSFromExif(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.containsKey('GPS GPSLatitude') && data.containsKey('GPS GPSLongitude')) {
        String rawLat = data['GPS GPSLatitude']!.printable;
        String rawLon = data['GPS GPSLongitude']!.printable;
        logger.e(rawLat);
        logger.e(rawLon);

        rawLat = _cleanGpsString(rawLat);
        rawLon = _cleanGpsString(rawLon);
        double lat = _parseDmsToDecimal(rawLat);
        double lon = _parseDmsToDecimal(rawLon);
        if (data.containsKey('GPS GPSLatitudeRef') &&
            data['GPS GPSLatitudeRef']!.printable == 'S') {
          lat = -lat;
        }
        if (data.containsKey('GPS GPSLongitudeRef') &&
            data['GPS GPSLongitudeRef']!.printable == 'W') {
          lon = -lon;
        }
        print("获取到经纬度$lat $lon ");
        return LatLng(lat, lon);
      }
    } catch (e) {
      print("Error reading EXIF: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(39.9042, 116.4074),
                initialZoom: 5,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                MarkerLayer(
                  markers: photoMarkers.map((photo) {
                    return Marker(
                      width: 40.0,
                      height: 40.0,
                      point: photo['latlng'],
                      child: GestureDetector(
                        onTap: () => _showPhotoDialog(photo['file']),
                        child: Icon(
                          FluentIcons.location_circle,
                          color: Colors.red.lighter,
                          size: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示照片对话框
  void _showPhotoDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text("照片"),
        content: Image.file(File(filePath)),
        actions: [
          Button(
            child: const Text("关闭"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
