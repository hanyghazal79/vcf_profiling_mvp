import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ResultsPage extends StatelessWidget {
  final Map<String, dynamic> analysisResults;
  final String patientId;

  const ResultsPage({
    super.key,
    required this.analysisResults,
    required this.patientId,
  });

  // Helper methods for type-safe data access
  Map<String, dynamic> _safeMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        if (kDebugMode) {
          print('Error converting map: $e');
        }
      }
    }
    return {};
  }

  List<Map<String, dynamic>> _safeListOfMaps(dynamic data) {
    final List<Map<String, dynamic>> result = [];

    if (data is List) {
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          result.add(item);
        } else if (item is Map) {
          try {
            result.add(Map<String, dynamic>.from(item));
          } catch (e) {
            if (kDebugMode) {
              print('Error converting list item to map: $e');
            }
          }
        } else if (item is String) {
          try {
            // Try to parse string as JSON
            final parsed = json.decode(item);
            if (parsed is Map<String, dynamic>) {
              result.add(parsed);
            } else if (parsed is Map) {
              result.add(Map<String, dynamic>.from(parsed));
            }
          } catch (e) {
            // If not JSON, create a simple map
            result.add({'value': item.toString()});
          }
        }
      }
    }

    return result;
  }

  List<String> _safeListOfStrings(dynamic data) {
    final List<String> result = [];

    if (data is List) {
      for (var item in data) {
        if (item is String) {
          result.add(item);
        } else {
          result.add(item.toString());
        }
      }
    }

    return result;
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getRiskColor() {
    final risk = _safeString(analysisResults['overall_risk']);
    if (risk.toLowerCase().contains('high')) return Colors.red;
    if (risk.toLowerCase().contains('moderate')) return Colors.orange;
    if (risk.toLowerCase().contains('increased')) return Colors.yellow.shade700;
    if (risk.toLowerCase().contains('vus') ||
        risk.toLowerCase().contains('uncertain')) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Color _getClinVarColor(String? significance) {
    final sig = _safeString(significance).toLowerCase();
    if (sig.contains('pathogenic')) return Colors.red;
    if (sig.contains('likely pathogenic')) return Colors.red.shade300;
    if (sig.contains('uncertain')) return Colors.orange;
    if (sig.contains('conflicting')) return Colors.purple;
    if (sig.contains('benign') || sig.contains('likely benign')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  Color _getRiskLevelColor(String? riskLevel) {
    final level = _safeString(riskLevel).toLowerCase();
    if (level.contains('high')) return Colors.red;
    if (level.contains('moderate')) return Colors.orange;
    if (level.contains('increased')) return Colors.yellow.shade700;
    if (level.contains('vus') || level.contains('uncertain')) {
      return Colors.orange;
    }
    return Colors.green;
  }

  Color _getPriorityColor(String? priority) {
    final prio = _safeString(priority).toLowerCase();
    if (prio.contains('high')) return Colors.red;
    if (prio.contains('medium')) return Colors.orange;
    if (prio.contains('low')) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analysis Results'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Export functionality
              _exportReport(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              // Print functionality
              _printReport(context);
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                  Tab(text: 'Variants', icon: Icon(Icons.table_chart)),
                  Tab(text: 'Charts', icon: Icon(Icons.pie_chart)),
                  Tab(text: 'Report', icon: Icon(Icons.description)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildVariantsTab(),
                  _buildChartsTab(),
                  _buildReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back),
        label: Text('New Analysis'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = _safeMap(analysisResults['summary']);
    final recommendations = _safeListOfMaps(analysisResults['recommendations']);

    final riskInterpretation = _safeString(summary['risk_interpretation']);
    final clinicalImplications = _safeListOfStrings(
      summary['clinical_implications'],
    );
    final highRiskGenes = _safeListOfStrings(summary['high_risk_genes']);
    final genesWithVariants = _safeListOfStrings(
      summary['genes_with_variants'],
    );
    final totalGenesAnalyzed = _safeInt(summary['total_genes_analyzed']);

    final variantCount = _safeInt(analysisResults['variant_count']);
    final pathogenicCount = _safeInt(analysisResults['pathogenic_count']);
    final vusCount = _safeInt(analysisResults['vus_count']);
    final overallRisk = _safeString(analysisResults['overall_risk']);
    final analysisDate = _formatDate(
      analysisResults['analysis_date']?.toString(),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Info Card
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getRiskColor(),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient: $patientId',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Analysis Date: $analysisDate',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      overallRisk,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getRiskColor(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Summary Cards Row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Variants Analyzed',
                  value: variantCount.toString(),
                  subtitle: '${genesWithVariants.length} genes',
                  color: Colors.blue,
                  icon: Icons.biotech,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Pathogenic',
                  value: pathogenicCount.toString(),
                  subtitle: '${highRiskGenes.length} high-risk genes',
                  color: Colors.red,
                  icon: Icons.warning,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  title: 'VUS',
                  value: vusCount.toString(),
                  subtitle: 'Uncertain significance',
                  color: Colors.orange,
                  icon: Icons.help,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Risk Interpretation
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assessment, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Risk Interpretation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    riskInterpretation,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Genes Analyzed
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.biotech, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Genes Analyzed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text('Total: $totalGenesAnalyzed genes'),
                        backgroundColor: Colors.blue.shade50,
                      ),
                      Chip(
                        label: Text(
                          'With Variants: ${genesWithVariants.length}',
                        ),
                        backgroundColor: Colors.green.shade50,
                      ),
                      if (highRiskGenes.isNotEmpty)
                        Chip(
                          label: Text('High-Risk: ${highRiskGenes.length}'),
                          backgroundColor: Colors.red.shade50,
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (genesWithVariants.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: genesWithVariants
                          .map(
                            (gene) => Chip(
                              label: Text(gene),
                              backgroundColor: highRiskGenes.contains(gene)
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              labelStyle: TextStyle(
                                color: highRiskGenes.contains(gene)
                                    ? Colors.red.shade900
                                    : Colors.blue.shade900,
                                fontWeight: highRiskGenes.contains(gene)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Clinical Implications
          if (clinicalImplications.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Clinical Implications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...clinicalImplications.map<Widget>(
                      (imp) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.blue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                imp,
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 16),

          // Recommendations
          if (recommendations.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.recommend, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...recommendations.map<Widget>(
                      (rec) => _buildRecommendationCard(rec),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final priority = _safeString(recommendation['priority']);
    final recText = _safeString(recommendation['recommendation']);
    final rationale = _safeString(recommendation['rationale']);

    Color priorityColor = _getPriorityColor(priority);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: priorityColor.withValues(alpha: 0.1),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recText,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 32),
              child: Text(
                rationale,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsTab() {
    final variants = _safeListOfMaps(analysisResults['variants']);

    if (variants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Variants Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No genetic variants were detected in the analyzed breast cancer genes.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Filter Variants:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Chip(
                label: Text('Total: ${variants.length}'),
                backgroundColor: Colors.blue.shade50,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Gene')),
                    DataColumn(label: Text('Position')),
                    DataColumn(label: Text('Change')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('ClinVar')),
                    DataColumn(label: Text('Risk')),
                    DataColumn(label: Text('AF')),
                  ],
                  rows: variants.map<DataRow>((variant) {
                    final gene = _safeString(variant['gene']);
                    final chromosome = _safeString(variant['chromosome']);
                    final position = _safeString(variant['position']);
                    final ref = _safeString(variant['ref']);
                    final alt = _safeString(variant['alt']);
                    final consequence = _safeString(variant['consequence']);
                    final clinvar = _safeString(
                      variant['clinvar_significance'],
                    );
                    final riskLevel = _safeString(variant['risk_level']);
                    final gnomadAf = variant['gnomad_af'];

                    // Format allele frequency
                    String afStr = 'N/A';
                    if (gnomadAf != null) {
                      final af = _safeDouble(gnomadAf);
                      if (af > 0) {
                        afStr = af < 0.001 ? '<0.001' : af.toStringAsFixed(4);
                      }
                    }

                    // Format variant change
                    String change = '$ref→$alt';
                    if (ref.length > 3 || alt.length > 3) {
                      change = ref.length > alt.length ? 'DEL' : 'INS';
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Chip(
                            label: Text(gene, style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.blue.shade50,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${chromosome.replaceAll('chr', '')}:$position',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        DataCell(
                          Text(
                            change,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            consequence.replaceAll('_variant', ''),
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getClinVarColor(
                                clinvar,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getClinVarColor(
                                  clinvar,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              clinvar.isNotEmpty ? clinvar : 'Unknown',
                              style: TextStyle(
                                fontSize: 10,
                                color: _getClinVarColor(clinvar),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRiskLevelColor(
                                riskLevel,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getRiskLevelColor(
                                  riskLevel,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              riskLevel.isNotEmpty ? riskLevel : 'Unknown',
                              style: TextStyle(
                                fontSize: 10,
                                color: _getRiskLevelColor(riskLevel),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            afStr,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartsTab() {
    final plots = _safeMap(analysisResults['plots']);
    final riskData = _safeMap(plots['risk_distribution']);
    final geneData = _safeMap(plots['gene_distribution']);
    final variantTypes = _safeMap(plots['variant_types']);

    // Prepare risk distribution chart data
    final List<Map<String, dynamic>> riskChartData = [];

    // Extract with fallbacks
    final highRisk =
        _safeDouble(riskData['High Risk']) + _safeDouble(riskData['High_Risk']);
    final vus =
        _safeDouble(riskData['VUS']) +
        _safeDouble(riskData['Variant of Uncertain Significance']);
    final lowRisk =
        _safeDouble(riskData['Low Risk']) +
        _safeDouble(riskData['Population Risk']);

    if (highRisk > 0) {
      riskChartData.add({
        'category': 'High Risk',
        'value': highRisk,
        'color': Colors.red,
      });
    }

    if (vus > 0) {
      riskChartData.add({
        'category': 'VUS',
        'value': vus,
        'color': Colors.orange,
      });
    }

    if (lowRisk > 0) {
      riskChartData.add({
        'category': 'Low Risk',
        'value': lowRisk,
        'color': Colors.green,
      });
    }

    // Prepare gene distribution data
    final List<Map<String, dynamic>> geneChartData = [];
    geneData.forEach((gene, count) {
      final geneCount = _safeDouble(count);
      if (geneCount > 0) {
        geneChartData.add({'gene': _safeString(gene), 'count': geneCount});
      }
    });

    // Sort by count descending
    geneChartData.sort((a, b) => b['count'].compareTo(a['count']));

    // Prepare variant types data
    final List<Map<String, dynamic>> variantTypeData = [];
    variantTypes.forEach((type, count) {
      final typeCount = _safeDouble(count);
      if (typeCount > 0) {
        variantTypeData.add({'type': _safeString(type), 'count': typeCount});
      }
    });

    variantTypeData.sort((a, b) => b['count'].compareTo(a['count']));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Risk Distribution Chart
          if (riskChartData.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variant Risk Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: SfCircularChart(
                        title: ChartTitle(text: 'Clinical Significance'),
                        legend: Legend(
                          isVisible: true,
                          position: LegendPosition.bottom,
                        ),
                        series: <CircularSeries>[
                          DoughnutSeries<Map<String, dynamic>, String>(
                            dataSource: riskChartData,
                            xValueMapper: (data, _) =>
                                data['category'] as String,
                            yValueMapper: (data, _) => data['value'] as double,
                            pointColorMapper: (data, _) =>
                                data['color'] as Color,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.outside,
                              textStyle: TextStyle(fontSize: 12),
                            ),
                            explode: true,
                            explodeAll: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (riskChartData.isNotEmpty) SizedBox(height: 16),

          // Gene Distribution Chart
          if (geneChartData.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variants by Gene',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 400,
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          labelRotation: geneChartData.length > 5 ? -45 : 0,
                          labelStyle: TextStyle(fontSize: 11),
                        ),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Number of Variants'),
                          minimum: 0,
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          ColumnSeries<Map<String, dynamic>, String>(
                            dataSource: geneChartData,
                            xValueMapper: (data, _) => data['gene'] as String,
                            yValueMapper: (data, _) => data['count'] as double,
                            color: Colors.blue,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                              textStyle: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (geneChartData.isNotEmpty) SizedBox(height: 16),

          // Variant Types Chart
          if (variantTypeData.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variant Types',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(
                          labelRotation: -45,
                          labelStyle: TextStyle(fontSize: 11),
                        ),
                        primaryYAxis: NumericAxis(
                          title: AxisTitle(text: 'Count'),
                          minimum: 0,
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          BarSeries<Map<String, dynamic>, String>(
                            dataSource: variantTypeData,
                            xValueMapper: (data, _) => data['type'] as String,
                            yValueMapper: (data, _) => data['count'] as double,
                            color: Colors.purple,
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.middle,
                              textStyle: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Summary Statistics
          Card(
            elevation: 2,
            margin: EdgeInsets.only(top: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildStatChip(
                        label: 'Total Variants',
                        value: _safeInt(
                          analysisResults['variant_count'],
                        ).toString(),
                        color: Colors.blue,
                      ),
                      _buildStatChip(
                        label: 'Pathogenic',
                        value: _safeInt(
                          analysisResults['pathogenic_count'],
                        ).toString(),
                        color: Colors.red,
                      ),
                      _buildStatChip(
                        label: 'VUS',
                        value: _safeInt(
                          analysisResults['vus_count'],
                        ).toString(),
                        color: Colors.orange,
                      ),
                      _buildStatChip(
                        label: 'Genes with Variants',
                        value: geneChartData.length.toString(),
                        color: Colors.green,
                      ),
                      if (riskChartData.isNotEmpty)
                        _buildStatChip(
                          label: 'High Risk Variants',
                          value: highRisk.toInt().toString(),
                          color: Colors.red,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    final summary = _safeMap(analysisResults['summary']);
    final variants = _safeListOfMaps(analysisResults['variants']);
    final recommendations = _safeListOfMaps(analysisResults['recommendations']);

    final riskInterpretation = _safeString(summary['risk_interpretation']);
    final clinicalImplications = _safeListOfStrings(
      summary['clinical_implications'],
    );
    final highRiskGenes = _safeListOfStrings(summary['high_risk_genes']);

    final variantCount = _safeInt(analysisResults['variant_count']);
    final pathogenicCount = _safeInt(analysisResults['pathogenic_count']);
    final vusCount = _safeInt(analysisResults['vus_count']);
    final overallRisk = _safeString(analysisResults['overall_risk']);
    final analysisDate = _formatDate(
      analysisResults['analysis_date']?.toString(),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Header
          Card(
            elevation: 2,
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'BREAST CANCER GENETIC RISK ASSESSMENT REPORT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Clinical Genetics Laboratory Report',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Patient Information
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PATIENT INFORMATION',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Divider(color: Colors.grey.shade300),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildReportField('Patient ID', patientId),
                            _buildReportField('Report Date', analysisDate),
                            _buildReportField('Overall Risk', overallRisk),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildReportField(
                              'Variants Analyzed',
                              variantCount.toString(),
                            ),
                            _buildReportField(
                              'Pathogenic Variants',
                              pathogenicCount.toString(),
                            ),
                            _buildReportField('VUS', vusCount.toString()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Executive Summary
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXECUTIVE SUMMARY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Divider(color: Colors.grey.shade300),
                  SizedBox(height: 12),
                  Text(
                    riskInterpretation,
                    style: TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // High-Risk Findings
          if (pathogenicCount > 0)
            Card(
              elevation: 2,
              color: Colors.red.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'HIGH-RISK FINDINGS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.red.shade200),
                    SizedBox(height: 12),
                    if (highRiskGenes.isNotEmpty)
                      Text(
                        'Pathogenic variants detected in: ${highRiskGenes.join(', ')}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade800,
                        ),
                      ),
                    SizedBox(height: 8),
                    ...variants
                        .where(
                          (v) => _safeString(
                            v['risk_level'],
                          ).toLowerCase().contains('high'),
                        )
                        .take(5) // Limit to 5 for report
                        .map<Widget>(
                          (variant) => Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              '• ${_safeString(variant['gene'])}: ${_safeString(variant['chromosome'])}:${_safeString(variant['position'])} '
                              '${_safeString(variant['ref'])}→${_safeString(variant['alt'])} '
                              '(${_safeString(variant['consequence'])})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ),

                    if (variants
                            .where(
                              (v) => _safeString(
                                v['risk_level'],
                              ).toLowerCase().contains('high'),
                            )
                            .length >
                        5)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '... and ${variants.where((v) => _safeString(v['risk_level']).toLowerCase().contains('high')).length - 5} more pathogenic variants',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          if (pathogenicCount > 0) SizedBox(height: 16),

          // Clinical Implications
          if (clinicalImplications.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLINICAL IMPLICATIONS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Divider(color: Colors.grey.shade300),
                    SizedBox(height: 12),
                    ...clinicalImplications.map<Widget>(
                      (imp) => Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.arrow_right,
                              size: 20,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                imp,
                                style: TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (clinicalImplications.isNotEmpty) SizedBox(height: 16),

          // Recommendations
          if (recommendations.isNotEmpty)
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLINICAL RECOMMENDATIONS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Divider(color: Colors.grey.shade300),
                    SizedBox(height: 12),
                    ...recommendations.map<Widget>(
                      (rec) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(rec['priority']),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _safeString(rec['priority']).toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _safeString(rec['recommendation']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Padding(
                              padding: EdgeInsets.only(left: 32),
                              child: Text(
                                _safeString(rec['rationale']),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Report Footer
          SizedBox(height: 24),
          Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '--- END OF REPORT ---',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This report is intended for clinical use only. '
                    'All findings should be interpreted by a qualified genetic counselor '
                    'or healthcare professional in the context of the patient\'s personal '
                    'and family history.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Report generated by Breast Cancer Genetic Risk Assessment Platform',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _exportReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _printReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Print functionality coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
