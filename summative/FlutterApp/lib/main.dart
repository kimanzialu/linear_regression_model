import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ImihigoApp());
}

class ImihigoApp extends StatelessWidget {
  const ImihigoApp({super.key});

  static const Color fbBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Imihigo Score Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: fbBlue,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: fbBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: fbBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const PredictionPage(),
    );
  }
}

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final String apiUrl =
      'https://linear-regression-model-s8me.onrender.com/predict';

  final TextEditingController priorScoreController = TextEditingController();
  final TextEditingController yearNumberController = TextEditingController();

  String? selectedDistrict;
  String? selectedProvince;

  // Each district's most recent known Imihigo score (2024/2025) and province sourced from NISR's Imihigo evaluation reports

  final Map<String, Map<String, dynamic>> districtData = {
    'Bugesera': {'province': 'Eastern', 'score': 72.6},
    'Burera': {'province': 'Northern', 'score': 66.0},
    'City of Kigali': {'province': 'Kigali', 'score': 59.3},
    'Gakenke': {'province': 'Northern', 'score': 74.2},
    'Gatsibo': {'province': 'Eastern', 'score': 73.5},
    'Gicumbi': {'province': 'Northern', 'score': 73.0},
    'Gisagara': {'province': 'Southern', 'score': 76.6},
    'Huye': {'province': 'Southern', 'score': 68.8},
    'Kamonyi': {'province': 'Southern', 'score': 72.5},
    'Karongi': {'province': 'Western', 'score': 67.4},
    'Kayonza': {'province': 'Eastern', 'score': 65.8},
    'Kirehe': {'province': 'Eastern', 'score': 72.7},
    'Muhanga': {'province': 'Southern', 'score': 73.0},
    'Musanze': {'province': 'Northern', 'score': 64.1},
    'Ngoma': {'province': 'Eastern', 'score': 77.2},
    'Ngororero': {'province': 'Western', 'score': 65.0},
    'Nyabihu': {'province': 'Western', 'score': 54.4},
    'Nyagatare': {'province': 'Eastern', 'score': 74.3},
    'Nyamagabe': {'province': 'Southern', 'score': 73.5},
    'Nyamasheke': {'province': 'Western', 'score': 71.9},
    'Nyanza': {'province': 'Southern', 'score': 65.6},
    'Nyaruguru': {'province': 'Southern', 'score': 70.5},
    'Rubavu': {'province': 'Western', 'score': 62.6},
    'Ruhango': {'province': 'Southern', 'score': 68.4},
    'Rulindo': {'province': 'Northern', 'score': 59.1},
    'Rusizi': {'province': 'Western', 'score': 66.9},
    'Rutsiro': {'province': 'Western', 'score': 61.0},
    'Rwamagana': {'province': 'Eastern', 'score': 72.7},
  };
  final List<String> provinces = [
    'Eastern',
    'Kigali',
    'Northern',
    'Southern',
    'Western'
  ];

  String resultText = '';
  bool isLoading = false;

  Future<void> predictScore() async {
    // Making sure nothing is missing before calling the API
    if (priorScoreController.text.isEmpty ||
        yearNumberController.text.isEmpty ||
        selectedProvince == null) {
      setState(() {
        resultText = 'Please fill in all fields before predicting.';
      });
      return;
    }

    final double? priorScore = double.tryParse(priorScoreController.text);
    final int? yearNumber = int.tryParse(yearNumberController.text);

    if (priorScore == null || yearNumber == null) {
      setState(() {
        resultText = 'Prior score and year number must be valid numbers.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      resultText = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prior_score': priorScore,
          'year_number': yearNumber,
          'province': selectedProvince,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          resultText = 'Predicted Score: ${data['predicted_score']}%';
        });
      } else {
        // API sends back a validation error
        final data = jsonDecode(response.body);
        setState(() {
          resultText = 'Error: ${data['detail'].toString()}';
        });
      }
    } catch (e) {
      setState(() {
        resultText = 'Could not reach the server. Check your connection.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imihigo Score Predictor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter district details to predict its Imihigo score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF050505),
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedDistrict,
                decoration: const InputDecoration(
                  labelText: 'District',
                ),
                items: districtData.keys.map((district) {
                  return DropdownMenuItem(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final info = districtData[value]!;
                  setState(() {
                    selectedDistrict = value;
                    priorScoreController.text = info['score'].toString();
                    selectedProvince = info['province'] as String;
                  });
                },
              ),
              const SizedBox(height: 14),

              TextField(
                controller: priorScoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prior Year Score (0-100)',
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: yearNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year Number (0-10)',
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: selectedProvince,
                decoration: const InputDecoration(
                  labelText: 'Province',
                ),
                items: provinces.map((province) {
                  return DropdownMenuItem(
                    value: province,
                    child: Text(province),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProvince = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isLoading ? null : predictScore,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Predict'),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resultText.isEmpty
                      ? 'Prediction will appear here.'
                      : resultText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}