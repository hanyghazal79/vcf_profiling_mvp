// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'results_page.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  _AnalysisPageState createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // State variables
  bool _isAnalyzing = false;
  String _analysisMode = 'offline'; // 'offline' or 'online'
  String? _selectedFilePath;
  String _patientId = 'P001';
  // ignore: unused_field
  Map<String, dynamic>? _analysisResults;
  String _apiUrl =
      'https://hanyghazal79.pythonanywhere.com'; // Change to your API URL

  // Text controllers
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _patientIdController.text = _patientId;
    _apiUrlController.text = _apiUrl;
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickVcfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['vcf', 'vcf.gz'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
        _showSnackBar('File selected: ${result.files.single.name}');
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e');
    }
  }

  Future<void> _performAnalysis() async {
    if (_selectedFilePath == null) {
      _showSnackBar('Please select a VCF file first');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResults = null;
    });

    try {
      Map<String, dynamic> results;

      if (_analysisMode == 'online') {
        // Online analysis via API
        results = await _analyzeOnline();
      } else {
        // Offline analysis (local Python script)
        results = await _analyzeOffline();
      }

      setState(() {
        _analysisResults = results;
      });

      // Navigate to results page
      if (results.isNotEmpty) {
        _navigateToResultsPage(results: results, patientId: _patientId);
      } else {
        _showSnackBar('Analysis completed but no results were returned');
      }
    } catch (e) {
      _showSnackBar('Analysis failed: $e');
      if (kDebugMode) {
        print('Analysis error: $e');
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _navigateToResultsPage({
    required Map<String, dynamic> results,
    required String patientId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResultsPage(analysisResults: results, patientId: patientId),
      ),
    );
  }

  Future<Map<String, dynamic>> _analyzeOnline() async {
    try {
      // Read file - handle potential large files
      File file = File(_selectedFilePath!);

      // Check file size (max 50MB for online analysis)
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        throw Exception('File too large for online analysis (max 50MB)');
      }

      // Read file content
      String vcfContent;
      try {
        vcfContent = await file.readAsString();
      } catch (e) {
        // Try reading as bytes and decoding
        final bytes = await file.readAsBytes();
        vcfContent = utf8.decode(bytes);
      }

      // Validate VCF content
      if (!vcfContent.contains('#CHROM') &&
          !vcfContent.contains('#fileformat=VCF')) {
        // Check first few lines
        final lines = vcfContent.split('\n').take(10).toList();
        bool hasVcfHeader = false;
        for (var line in lines) {
          if (line.contains('#CHROM') || line.contains('#fileformat=VCF')) {
            hasVcfHeader = true;
            break;
          }
        }

        if (!hasVcfHeader) {
          throw Exception(
            'Invalid VCF file format. File should contain VCF headers.',
          );
        }
      }

      // Prepare multipart request with timeout
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiUrl/api/analyze-direct'), // Use direct endpoint
      );

      request.fields['patient_id'] = _patientId;
      request.fields['mode'] = 'online';

      // FIXED: Use the correct way to create MultipartFile
      request.files.add(
        http.MultipartFile.fromString(
          'file',
          vcfContent,
          filename: 'sample.vcf',
        ),
      );

      // Send request with timeout
      var response = await request.send().timeout(Duration(seconds: 120));

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        return json.decode(responseBody);
      } else {
        String errorBody = await response.stream.bytesToString();
        throw Exception(
          'API request failed with status: ${response.statusCode}\n$errorBody',
        );
      }
    } catch (e) {
      // If online fails, fall back to offline with better error message
      if (kDebugMode) {
        print('Online analysis failed: $e');
      }

      // Show user-friendly error
      _showSnackBar('Online analysis failed. Trying offline mode...');

      return await _analyzeOffline();
    }
  }

  Future<Map<String, dynamic>> _analyzeOffline() async {
    try {
      if (kDebugMode) {
        print('Starting offline analysis for: $_selectedFilePath');
      }

      // Check file
      File file = File(_selectedFilePath!);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      // Get project root directory (go up from ui folder)
      String projectRoot = Directory.current.path;
      if (projectRoot.endsWith('ui')) {
        projectRoot = Directory(projectRoot).parent.path;
      }

      // Path to Python script
      String pythonScript = '$projectRoot/analysis/genetic_analyzer.py';
      File scriptFile = File(pythonScript);

      if (!await scriptFile.exists()) {
        // Try alternative location
        pythonScript = '$projectRoot/analysis/genetic_analyzer.py';
        scriptFile = File(pythonScript);

        if (!await scriptFile.exists()) {
          throw Exception(
            'Python analysis script not found. Expected at: $pythonScript',
          );
        }
      }

      if (kDebugMode) {
        print('Python script found at: $pythonScript');
      }

      // Read VCF to check format
      String vcfContent = await file.readAsString();
      if (!vcfContent.contains('#CHROM')) {
        // Try to fix common VCF issues
        if (kDebugMode) {
          print('Warning: #CHROM not found, checking file format...');
        }

        // Check if file has data
        List<String> lines = vcfContent.split('\n');
        bool hasData = false;
        for (String line in lines) {
          if (line.isNotEmpty && !line.startsWith('#') && line.contains('\t')) {
            hasData = true;
            break;
          }
        }

        if (!hasData) {
          throw Exception('VCF file appears empty or malformed');
        }
      }

      // Run Python analysis
      if (kDebugMode) {
        print('Running Python analysis...');
      }
      final result = await Process.run(
        'python3', // or 'python' depending on your system
        [pythonScript, _selectedFilePath!, _patientId],
        workingDirectory: projectRoot,
      );

      if (kDebugMode) {
        print('Python stdout: ${result.stdout}');
      }
      if (result.stderr.toString().isNotEmpty) {
        if (kDebugMode) {
          print('Python stderr: ${result.stderr}');
        }
      }

      if (result.exitCode != 0) {
        String errorMsg = result.stderr.toString();
        if (errorMsg.isEmpty) errorMsg = result.stdout.toString();
        if (errorMsg.length > 100) {
          errorMsg = '${errorMsg.substring(0, 100)}...';
        }
        throw Exception('Analysis failed: $errorMsg');
      }

      // Look for results file
      String resultsFile = '$projectRoot/${_patientId}_analysis_results.json';
      File resultsFileObj = File(resultsFile);

      if (!await resultsFileObj.exists()) {
        // Try alternative location
        resultsFile = '${_patientId}_analysis_results.json';
        resultsFileObj = File(resultsFile);

        if (!await resultsFileObj.exists()) {
          // Try to parse JSON from stdout
          String stdoutStr = result.stdout.toString();
          if (stdoutStr.contains('{') && stdoutStr.contains('}')) {
            try {
              int start = stdoutStr.indexOf('{');
              int end = stdoutStr.lastIndexOf('}') + 1;
              String jsonStr = stdoutStr.substring(start, end);
              return json.decode(jsonStr);
            } catch (e) {
              if (kDebugMode) {
                print('Could not parse JSON from stdout: $e');
              }
            }
          }
          throw Exception('Results file not found and cannot parse stdout');
        }
      }

      // Read and parse results
      String jsonContent = await resultsFileObj.readAsString();
      Map<String, dynamic> results = json.decode(jsonContent);

      if (kDebugMode) {
        print(
          'Analysis successful! Found ${results['variant_count']} variants',
        );
      }
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Offline analysis error: $e');
      }

      // Return meaningful error results
      return {
        'patient_id': _patientId,
        'analysis_date': DateTime.now().toIso8601String(),
        'overall_risk': 'Analysis Error',
        'variant_count': 0,
        'pathogenic_count': 0,
        'vus_count': 0,
        'variants': [],
        'summary': {
          'risk_interpretation':
              'Analysis failed: ${e.toString().split('\n').first}',
          'clinical_implications': [
            'Please check VCF file format and try again',
          ],
          'high_risk_genes': [],
          'genes_with_variants': [],
          'total_genes_analyzed': 10,
        },
        'recommendations': [
          {
            'priority': 'high',
            'recommendation': 'Check VCF file format',
            'rationale': 'The VCF file may be malformed or in incorrect format',
          },
          {
            'priority': 'medium',
            'recommendation': 'Try with test VCF file',
            'rationale':
                'Use the provided test_brca.vcf to verify the system works',
          },
        ],
        'plots': {
          'risk_distribution': {'High Risk': 0, 'VUS': 0, 'Low Risk': 0},
          'gene_distribution': {},
        },
      };
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Breast Cancer Genetic Risk'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About'),
                  content: Text(
                    'Breast Cancer Genetic Risk Assessment Tool\n\n'
                    'This tool analyzes VCF files for genetic variants associated with hereditary breast cancer risk.\n\n'
                    'Features:\n'
                    '• Real VCF file analysis using cyvcf2\n'
                    '• 15 breast cancer risk genes analyzed\n'
                    '• Clinical variant classification\n'
                    '• Risk assessment and recommendations\n\n'
                    'Upload a VCF file to begin analysis.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeaderSection(),
            SizedBox(height: 24),

            // File Selection
            _buildFileSelectionSection(),
            SizedBox(height: 24),

            // Analysis Mode
            _buildAnalysisModeSection(),
            SizedBox(height: 24),

            // Patient Info
            _buildPatientInfoSection(),
            SizedBox(height: 32),

            // Action Buttons (Only Start Analysis - Demo button removed)
            _buildActionButtons(),

            // Analysis Status
            if (_isAnalyzing) _buildAnalysisProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, size: 40, color: Colors.blue),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Breast Cancer Genetic Risk Assessment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Upload a VCF file to analyze genetic variants in 15 breast cancer risk genes (BRCA1, BRCA2, PALB2, TP53, etc.) using real VCF analysis.',
              style: TextStyle(color: Colors.black54),
            ),
            SizedBox(height: 8),
            Chip(
              label: Text(
                'Real VCF Analysis • Clinical Reporting • HIPAA Compliant',
              ),
              backgroundColor: Colors.blue.shade50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Select VCF File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(Icons.insert_drive_file, color: Colors.blue),
                title: Text(
                  _selectedFilePath != null
                      ? _selectedFilePath!.split('/').last
                      : 'No file selected',
                  style: TextStyle(
                    color: _selectedFilePath != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
                subtitle: _selectedFilePath != null
                    ? Text('Ready for analysis')
                    : Text('Supported: .vcf, .vcf.gz'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedFilePath != null)
                      IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedFilePath = null;
                          });
                        },
                      ),
                    ElevatedButton.icon(
                      onPressed: _pickVcfFile,
                      icon: Icon(Icons.upload_file, size: 18),
                      label: Text('Browse'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Note: VCF files should contain variants from a clinical-grade sequencing panel.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisModeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2. Analysis Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    title: 'Local Analysis',
                    subtitle: 'Fast, runs on your device',
                    icon: Icons.computer,
                    isSelected: _analysisMode == 'offline',
                    onTap: () {
                      setState(() {
                        _analysisMode = 'offline';
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildModeCard(
                    title: 'Cloud Analysis',
                    subtitle: 'Uses latest databases',
                    icon: Icons.cloud,
                    isSelected: _analysisMode == 'online',
                    onTap: () {
                      setState(() {
                        _analysisMode = 'online';
                      });
                    },
                  ),
                ),
              ],
            ),
            if (_analysisMode == 'online') ...[
              SizedBox(height: 16),
              TextField(
                controller: _apiUrlController,
                decoration: InputDecoration(
                  labelText: 'API Endpoint',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                  hintText: 'http://localhost:8000',
                ),
                onChanged: (value) {
                  setState(() {
                    _apiUrl = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.blue : Colors.grey),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. Patient Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _patientIdController,
              decoration: InputDecoration(
                labelText: 'Patient ID',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                hintText: 'Enter patient identifier',
                helperText: 'Used for report generation',
              ),
              onChanged: (value) {
                setState(() {
                  _patientId = value.isNotEmpty ? value : 'P001';
                });
              },
            ),
            SizedBox(height: 12),
            Text(
              'Privacy Note: Patient data is processed locally when using Local Analysis mode.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isAnalyzing ? null : _performAnalysis,
          icon: Icon(Icons.analytics, size: 24),
          label: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'START GENETIC ANALYSIS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Analysis includes: 15 breast cancer genes • Variant classification • Risk assessment • Clinical recommendations',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalysisProgress() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(top: 24),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Analyzing VCF File...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Processing variants in breast cancer genes:\nBRCA1, BRCA2, PALB2, TP53, PTEN, CHEK2, ATM, CDH1, STK11, NF1, BRIP1, RAD51C, RAD51D, BARD1, NBN',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: null,
              backgroundColor: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }
}
