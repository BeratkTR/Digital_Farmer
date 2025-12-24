import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../models/analysis_data.dart';
import '../models/motion_capture.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static const String _serverUrl = 'http://34.165.138.144:4000';

  Stream<SensorData> getSensorStream() {
    return _db
        .collection('sensors')
        .doc('main_plant')
        .collection('readings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return SensorData.fromMap(snapshot.docs.first.data());
          } else {
            return SensorData(temp: 0, humidity: 0, soil: 0, light: 0);
          }
        });
  }

  Future<void> triggerAnalysis() async {
    try {
      final uri = Uri.parse('$_serverUrl/analyze');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        print("✅ Analiz isteği sunucuya iletildi.");
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Tetikleme Hatası: $e");
      throw Exception('Bağlantı hatası, sunucu açık mı?');
    }
  }

  Stream<AnalysisData?> getLatestAnalysisStream() {
    return _db
        .collection('analyses')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return AnalysisData.fromFirestore(snapshot.docs.first);
          } else {
            return null;
          }
        });
  }

  Stream<List<AnalysisData>> getAnalysisListStream() {
    return _db
        .collection('analyses')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AnalysisData.fromFirestore(doc))
              .toList();
        });
  }

  Stream<MotionCapture?> getLatestMotionStream() {
    return _db
        .collection('motion_captures')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return MotionCapture.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  Stream<List<MotionCapture>> getMotionListStream() {
    return _db
        .collection('motion_captures')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MotionCapture.fromFirestore(doc))
              .toList();
        });
  }
}
