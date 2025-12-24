import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';

class AnalysisCard extends StatelessWidget {
  final AnalysisData data;

  const AnalysisCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('HH:mm - dd MMM', 'tr_TR').format(data.timestamp);

    return Card(
      color: const Color(0xFF2C2C2C),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Row(
                   children: [
                     Icon(Icons.smart_toy_outlined, color: Colors.purpleAccent),
                     SizedBox(width: 8),
                     Text("Yapay Zeka Analizi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ],
                 ),
                Text(formattedDate, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),

          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: CachedNetworkImage(
              imageUrl: data.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[800],
                child: const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[800],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.redAccent, size: 40),
                     SizedBox(height: 8),
                    Text("Resim Yüklenemedi", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              data.aiResult,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
