import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/analysis_data.dart';
import '../models/motion_capture.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/sensor_card.dart';
import '../widgets/analysis_list_item.dart';
import '../widgets/motion_alert_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notifService = NotificationService();
  
  SensorData? _oldData;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _notifService.initNotifications(context);
  }

  void _onFabPressed() async {
    setState(() => _isAnalyzing = true);
    try {
      await _dbService.triggerAnalysis();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text("📸 Kamera tetiklendi! Analiz bekleniyor..."),
             backgroundColor: Colors.purpleAccent,
             behavior: SnackBarBehavior.floating,
           )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text('Dijital Çiftçim'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAnalyzing ? null : _onFabPressed,
        backgroundColor: _isAnalyzing ? Colors.grey : Colors.purpleAccent,
        icon: _isAnalyzing 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.camera_alt),
        label: Text(_isAnalyzing ? "İstek Gönderiliyor..." : "AI Analiz Et", style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            StreamBuilder<MotionCapture?>(
              stream: _dbService.getLatestMotionStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox.shrink();
                }

                final motion = snapshot.data!;
                
                bool isRecentHour = DateTime.now().difference(motion.timestamp).inHours < 1;
                
                if (!isRecentHour) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Son Hareket Uyarısı",
                          style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MotionAlertCard(data: motion),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
            
            const Text("Canlı Veriler", style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            StreamBuilder<SensorData>(
              stream: _dbService.getSensorStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Hata: ${snapshot.error}");
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.green));

                final newData = snapshot.data!;
                
                int lightPercent = (newData.light / 4095 * 100).toInt().clamp(0, 100);
                double? oldLightPercent;
                if (_oldData?.light != null) {
                  oldLightPercent = (_oldData!.light / 4095 * 100);
                }

                Widget content = Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SensorCard(
                            title: "Sıcaklık",
                            valueText: "${newData.temp}°",
                            icon: Icons.thermostat,
                            baseColor: Colors.orange,
                            currentValue: newData.temp,
                            oldValue: _oldData?.temp,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SensorCard(
                            title: "Nem",
                            valueText: "%${newData.humidity}",
                            icon: Icons.water_drop,
                            baseColor: Colors.blue,
                            currentValue: newData.humidity.toDouble(),
                            oldValue: _oldData?.humidity.toDouble(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SensorCard(
                            title: "Toprak",
                            valueText: "%${newData.soil}",
                            icon: Icons.grass,
                            baseColor: Colors.green,
                            currentValue: newData.soil.toDouble(),
                            oldValue: _oldData?.soil.toDouble(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SensorCard(
                            title: "Işık",
                            valueText: "%$lightPercent",
                            icon: Icons.wb_sunny,
                            baseColor: Colors.amber,
                            currentValue: lightPercent.toDouble(),
                            oldValue: oldLightPercent,
                          ),
                        ),
                      ],
                    )
                  ],
                );

                Future.microtask(() => _oldData = newData);
                return content;
              },
            ),

            const SizedBox(height: 30),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, color: Colors.purpleAccent, size: 20),
                    SizedBox(width: 8),
                    Text("AI Analizleri", style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("Detay için dokun →", style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<AnalysisData>>(
              stream: _dbService.getAnalysisListStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white54),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Henüz yapılmış bir analiz yok.\nAI Analiz butonuna basarak bitkinizi analiz edin.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final analyses = snapshot.data!;
                return Column(
                  children: analyses.map((analysis) => AnalysisListItem(data: analysis)).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
