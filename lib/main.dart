import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const ScrapTrackApp());
}

class ScrapTrackApp extends StatelessWidget {
  const ScrapTrackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScrapTrack Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF004D40), // Dark Teal
        scaffoldBackgroundColor: const Color(0xFFF5F5DC), // Cream Background
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF004D40),
          secondary: const Color(0xFF00796B),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  
  String selectedWasteType = 'Carton';
  final List<String> wasteTypes = ['Carton', 'Heavy Carton', 'Mixed Paper', 'Plastic Bottles', 'Scrap Metal'];
  
  List<Map<String, dynamic>> currentBatch = [];
  List<Map<String, dynamic>> historyLogs = [];
  
  double defaultRate = 100.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultRate = prefs.getDouble('default_rate') ?? 100.0;
      _rateController.text = defaultRate.toString();
      
      String? savedHistory = prefs.getString('history_logs');
      if (savedHistory != null) {
        historyLogs = List<Map<String, dynamic>>.from(json.decode(savedHistory));
      }
    });
  }

  Future<void> _saveDefaultRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_rate', rate);
    setState(() {
      defaultRate = rate;
    });
  }

  void _addItem() {
    if (_weightController.text.isEmpty) return;
    double weight = double.tryParse(_weightController.text) ?? 0.0;
    double rate = double.tryParse(_rateController.text) ?? defaultRate;
    
    if (rate != defaultRate) {
      _saveDefaultRate(rate);
    }

    setState(() {
      currentBatch.add({
        'type': selectedWasteType,
        'weight': weight,
        'rate': rate,
        'total': weight * rate,
      });
      _weightController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      currentBatch.removeAt(index);
    });
  }

  Future<void> _saveBatchRecord() async {
    if (currentBatch.isEmpty) return;

    double grandTotal = currentBatch.fold(0.0, (sum, item) => sum + item['total']);
    String timestamp = DateTime.now().toString().substring(0, 16);

    Map<String, dynamic> record = {
      'date': timestamp,
      'grandTotal': grandTotal,
      'items': List.from(currentBatch),
    };

    setState(() {
      historyLogs.insert(0, record);
      currentBatch.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_logs', json.encode(historyLogs));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch record saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double activeTotal = currentBatch.fold(0.0, (sum, item) => sum + item['total']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScrapTrack Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF004D40),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen(historyLogs: historyLogs)),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Card
                    Card(
                      elevation: 3,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('New Intake Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF004D40))),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedWasteType,
                              items: wasteTypes.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (val) => setState(() => selectedWasteType = val!),
                              decoration: InputDecoration(
                                labelText: 'Waste Type',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _weightController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Weight (KG)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _rateController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Rate (₦/KG)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00796B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _addItem,
                                child: const Text('Add to Batch List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Batch Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Batch Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF004D40))),
                        Text('${currentBatch.length} items', style: const TextStyle(color: Color(0xFF557A6E), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dynamic List View Container
                    currentBatch.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: const Text('No items added to this batch yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentBatch.length,
                            itemBuilder: (context, index) {
                              final item = currentBatch[index];
                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  title: Text('${item['type']} (${item['weight']} KG)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text('Rate: ₦${item['rate']} /kg', style: const TextStyle(fontSize: 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('₦${item['total'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40), fontSize: 14)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        onPressed: () => _removeItem(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    
                    const SizedBox(height: 20),

                    // Total & Save Section
                    if (currentBatch.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004D40),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Batch Value', style: TextStyle(color: Color(0xFFE0F2F1), fontSize: 11)),
                                const SizedBox(height: 2),
                                Text('₦${activeTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _saveBatchRecord,
                              child: const Text('Calculate & Save', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> historyLogs;
  const HistoryScreen({Key? key, required this.historyLogs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF004D40),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: historyLogs.isEmpty
          ? const Center(child: Text('No transaction history saved yet.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: historyLogs.length,
              itemBuilder: (context, index) {
                var log = historyLogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text('Date: ${log['date']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    trailing: Text('₦${log['grandTotal'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40), fontSize: 14)),
                    children: (log['items'] as List).map<Widget>((item) {
                      return ListTile(
                        dense: true,
                        title: Text('${item['type']} - ${item['weight']} KG @ ₦${item['rate']}', style: const TextStyle(fontSize: 13)),
                        trailing: Text('₦${item['total'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
