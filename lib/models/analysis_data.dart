import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisData {
  final String id;
  final String imageUrl;
  final String aiResult;
  final DateTime timestamp;

  AnalysisData({
    required this.id,
    required this.imageUrl,
    required this.aiResult,
    required this.timestamp,
  });

  factory AnalysisData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return AnalysisData(
      id: doc.id,
      imageUrl: data['imageUrl'].toString().startsWith('http') 
          ? data['imageUrl'] 
          : 'http://34.165.138.144:4000${data['imageUrl']}',
      aiResult: data['aiResult'] ?? 'Analiz sonucu bekleniyor...',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
