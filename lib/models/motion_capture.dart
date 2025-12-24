import 'package:cloud_firestore/cloud_firestore.dart';

class MotionCapture {
  final String id;
  final String imageUrl;
  final DateTime timestamp;

  MotionCapture({
    required this.id,
    required this.imageUrl,
    required this.timestamp,
  });

  factory MotionCapture.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MotionCapture(
      id: doc.id,
      imageUrl: data['imageUrl'].toString().startsWith('http')
          ? data['imageUrl']
          : 'http://34.165.138.144:4000${data['imageUrl']}',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
