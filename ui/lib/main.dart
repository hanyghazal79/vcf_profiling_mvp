import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'analysis_page.dart';
import 'themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(BreastCancerRiskApp());
}

class BreastCancerRiskApp extends StatelessWidget {
  const BreastCancerRiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breast Cancer Genetic Risk',
      debugShowCheckedModeBanner: false,
      theme: ThemeManager.defaultTheme.lightTheme,
      home: AnalysisPage(),
    );
  }
}
