import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/analysis_data.dart';
import '../screens/analysis_detail_screen.dart';

class AnalysisListItem extends StatelessWidget {
  final AnalysisData data;

  const AnalysisListItem({super.key, required this.data});

  String _getShortSummary(String text) {
    String clean = text.replaceAll('\n', ' ').trim();
    
    if (clean.length > 80) {
      return '${clean.substring(0, 80)}...';
    }
    return clean;
  }

  Color _getStatusColor(String text) {
    String lower = text.toLowerCase();
    if (lower.contains('sağlıklı') || lower.contains('iyi') || lower.contains('güzel')) {
      return Colors.greenAccent;
    } else if (lower.contains('dikkat') || lower.contains('sorun') || lower.contains('hastalık')) {
      return Colors.orangeAccent;
    } else if (lower.contains('kötü') || lower.contains('tehlike') || lower.contains('acil')) {
      return Colors.redAccent;
    }
    return Colors.purpleAccent;
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('HH:mm - dd MMM', 'tr_TR').format(data.timestamp);
    Color statusColor = _getStatusColor(data.aiResult);
    String summary = _getShortSummary(data.aiResult);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisDetailScreen(data: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'analysis_image_${data.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: data.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[800],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.purpleAccent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    Text(
                      summary,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: Colors.white30),
            ),
          ],
        ),
      ),
    );
  }
}
