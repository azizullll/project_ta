import 'package:flutter/foundation.dart';

class StatisticsController extends ChangeNotifier {
  // Data untuk grafik Lampu & Kipas (dalam jam)
  final Map<String, List<double>> lampAndFanData = {
    'Lampu': [10, 18, 12, 18, 14, 10, 8], // Sen, Sel, Rab, Kam, Jum, Sab, Min
    'Kipas': [14, 20, 16, 8, 22, 18, 12],
  };

  // Data untuk grafik Listrik & Aki (dalam jam)
  final Map<String, List<double>> powerAndBatteryData = {
    'Listrik': [12, 18, 16, 20, 18, 14, 8], // Sen, Sel, Rab, Kam, Jum, Sab, Min
    'Aki': [6, 8, 6, 10, 10, 6, 2],
  };

  // Method untuk update data jika diperlukan di masa depan
  void updateData() {
    notifyListeners();
  }
}
