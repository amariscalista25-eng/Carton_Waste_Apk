import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MarketLedgerApp());
}

class MarketLedgerApp extends StatelessWidget {
  const MarketLedgerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market Ledger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDFADB), // Cream background
        primaryColor: const Color(0xFF2E7D32), // Green
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ======================= HOME SCREEN =======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double?> wasteTypes = {'Carton': null};

  @override
  void initState() {
    super.initState();
    _loadWasteTypes();
  }

  Future<void> _loadWasteTypes() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedWastes = prefs.getString('waste_types');
    if (savedWastes != null) {
      Map<String, dynamic> decoded = json.decode(savedWastes);
      setState(() {
        wasteTypes = decoded.map((key, value) => MapEntry(key, value != null ? (value as num).toDouble() : null));
      });
    } else {
      _saveWasteTypes();
    }
  }

  Future<void> _saveWasteTypes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('waste_types', json.encode(wasteTypes));
  }

  void _addNewWasteType(String name, double? price) {
    setState(() {
      wasteTypes[name] = price;
    });
    _saveWasteTypes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: WasteManagerDrawer(
        wasteTypes: wasteTypes,
        onWasteAdded: _addNewWasteType,
        onPriceUpdated: _addNewWasteType,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFFFDFADB)),
            ),
            const SizedBox(height: 20),
            const Text(
              'MARKET LEDGER',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 50),
            _buildMenuButton(
              title: 'Calculator',
              icon: Icons.calculate,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CalculatorScreen(wasteTypes: wasteTypes))),
            ),
            const SizedBox(height: 20),
            _buildMenuButton(
              title: 'Daily Schedule',
              icon: Icons.calendar_month,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 50),
        ),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF7E57C2)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

// ======================= DRAWER (WASTE MANAGER) =======================
class WasteManagerDrawer extends StatelessWidget {
  final Map<String, double?> wasteTypes;
  final Function(String, double?) onWasteAdded;
  final Function(String, double) onPriceUpdated;

  const WasteManagerDrawer({Key? key, required this.wasteTypes, required this.onWasteAdded, required this.onPriceUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFDFADB),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Waste Types & Prices', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: wasteTypes.keys.map((waste) {
                  double? price = wasteTypes[waste];
                  return ListTile(
                    title: Text(waste, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(price == null ? 'Price not set' : '₦$price / KG'),
                    trailing: const Icon(Icons.edit, color: Color(0xFF2E7D32), size: 20),
                    onTap: () => _showAddWasteDialog(context, wasteName: waste, currentPrice: price),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                icon: const Icon(Icons.add),
                label: const Text('Add New Waste'),
                onPressed: () => _showAddWasteDialog(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showAddWasteDialog(BuildContext context, {String? wasteName, double? currentPrice}) {
    TextEditingController nameCtrl = TextEditingController(text: wasteName);
    TextEditingController priceCtrl = TextEditingController(text: currentPrice?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFADB),
        title: Text(wasteName == null ? 'Add New Waste' : 'Edit $wasteName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (wasteName == null) TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Waste Name')),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per KG (₦)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            onPressed: () {
              String name = nameCtrl.text.trim();
              double? price = double.tryParse(priceCtrl.text);
              if (name.isNotEmpty) {
                onWasteAdded(name, price);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

// ======================= CALCULATOR SCREEN =======================
class CalculatorScreen extends StatefulWidget {
  final Map<String, double?> wasteTypes;
  const CalculatorScreen({Key? key, required this.wasteTypes}) : super(key: key);

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String selectedWaste = 'Carton';
  final TextEditingController _weightCtrl = TextEditingController();
  List<Map<String, dynamic>> currentBatch = [];

  void _addItem() {
    double? price = widget.wasteTypes[selectedWaste];
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User has not set a permanent price for this waste. Please set it in the sidebar.')));
      return;
    }
    if (_weightCtrl.text.isEmpty) return;
    
    double weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    
    setState(() {
      currentBatch.add({
        'type': selectedWaste,
        'weight': weight,
        'rate': price,
        'total': weight * price,
        'time': "${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} ${TimeOfDay.now().period == DayPeriod.am ? 'AM' : 'PM'}"
      });
      _weightCtrl.clear();
    });
  }

  Future<void> _saveBatch() async {
    if (currentBatch.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    String? savedHistory = prefs.getString('history_logs');
    List<dynamic> history = savedHistory != null ? json.decode(savedHistory) : [];

    DateTime now = DateTime.now();
    String dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    double totalAmount = currentBatch.fold(0.0, (sum, item) => sum + item['total']);
    double totalKg = currentBatch.fold(0.0, (sum, item) => sum + item['weight']);
    int totalBundles = currentBatch.length;

    // Check if today already exists in history
    int existingIndex = history.indexWhere((log) => log['dateKey'] == dateKey);
    
    if (existingIndex >= 0) {
      history[existingIndex]['grandTotal'] += totalAmount;
      history[existingIndex]['totalKg'] += totalKg;
      history[existingIndex]['totalBundles'] += totalBundles;
      (history[existingIndex]['items'] as List).addAll(currentBatch);
    } else {
      history.insert(0, {
        'dateKey': dateKey,
        'timestamp': now.toIso8601String(),
        'grandTotal': totalAmount,
        'totalKg': totalKg,
        'totalBundles': totalBundles,
        'items': List.from(currentBatch),
      });
    }

    await prefs.setString('history_logs', json.encode(history));
    setState(() { currentBatch.clear(); });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Daily Schedule!')));
  }

  @override
  Widget build(BuildContext context) {
    double? currentPrice = widget.wasteTypes[selectedWaste];

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: selectedWaste,
              items: widget.wasteTypes.keys.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: (val) => setState(() => selectedWaste = val!),
              decoration: const InputDecoration(labelText: 'Select Waste Type'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price ₦/KG', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(currentPrice == null ? 'Not Set' : currentPrice.toString(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(currentPrice == null ? Icons.lock_open : Icons.lock, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weight (KG)',
                      border: OutlineInputBorder(borderSide: const BorderSide(color: Colors.deepPurple), borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.deepPurple), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: _addItem,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Text('Current Batch: ${currentBatch.length} Bundles', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _saveBatch,
              child: const Text('CHECK PRICE & SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}

// ======================= DAILY SCHEDULE & HISTORY =======================
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> historyLogs = [];
  double weeklyKg = 0;
  double weeklyAmount = 0;
  int weeklyBundles = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedHistory = prefs.getString('history_logs');
    if (savedHistory != null) {
      setState(() {
        historyLogs = List<Map<String, dynamic>>.from(json.decode(savedHistory));
        _calculateWeeklySummary();
      });
    }
  }

  void _calculateWeeklySummary() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    weeklyKg = 0;
    weeklyAmount = 0;
    weeklyBundles = 0;

    for (var log in historyLogs) {
      DateTime logDate = DateTime.parse(log['timestamp']);
      if (logDate.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
        weeklyKg += log['totalKg'];
        weeklyAmount += log['grandTotal'];
        weeklyBundles += log['totalBundles'];
      }
    }
  }

  void _deleteDay(int index) async {
    setState(() { historyLogs.removeAt(index); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_logs', json.encode(historyLogs));
    _calculateWeeklySummary();
  }

  String _formatDate(String isoString) {
    DateTime date = DateTime.parse(isoString);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime checkDate = DateTime(date.year, date.month, date.day);

    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String formatted = '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';

    if (checkDate == today) return 'Today, $formatted';
    if (checkDate == yesterday) return 'Yesterday, $formatted';
    return formatted;
  }

  void _showGainCalculator(Map<String, dynamic> log) {
    TextEditingController sellPriceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFADB),
        title: Text('Calculate Gain: ${_formatDate(log['timestamp'])}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Bought: ${log['totalKg'].toStringAsFixed(2)} KG'),
            Text('Amount Spent: ₦${log['grandTotal'].toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(controller: sellPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Your Selling Price ₦/KG')),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            onPressed: () {
              double sellPrice = double.tryParse(sellPriceCtrl.text) ?? 0;
              double revenue = sellPrice * log['totalKg'];
              double profit = revenue - log['grandTotal'];
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Revenue: ₦${revenue.toStringAsFixed(2)} | Profit: ₦${profit.toStringAsFixed(2)}'), duration: const Duration(seconds: 5)),
              );
            },
            child: const Text('Calculate'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tap any day to calculate gain!'))),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFE8F5E9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [const Text('Week KG', style: TextStyle(color: Colors.grey)), Text(weeklyKg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                Column(children: [const Text('Week Spent', style: TextStyle(color: Colors.grey)), Text('₦${weeklyAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                Column(children: [const Text('Bundles', style: TextStyle(color: Colors.grey)), Text(weeklyBundles.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: historyLogs.length,
              itemBuilder: (context, index) {
                var log = historyLogs[index];
                return Card(
                  color: const Color(0xFFF3E5F5), // Light purple tint from screenshot
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(log['timestamp']), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteDay(index)),
                      ],
                    ),
                    subtitle: Text('${log['totalKg'].toStringAsFixed(2)} KG | ₦${log['grandTotal'].toStringAsFixed(0)} | ${log['totalBundles']} Bundles'),
                    children: [
                      Container(
                        color: const Color(0xFFFDFADB),
                        child: Column(
                          children: [
                            ...(log['items'] as List).map<Widget>((item) {
                              return ListTile(
                                leading: const Icon(Icons.shopping_bag, color: Color(0xFF4CAF50)),
                                title: Text('1 Bundle (${item['weight']} KG)'),
                                subtitle: Text('Price: ₦${item['rate']}/KG @ ${item['time']}'),
                                trailing: Text('₦${item['total'].toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            TextButton.icon(
                              icon: const Icon(Icons.calculate, color: Color(0xFF2E7D32)),
                              label: const Text('Calculate Gain for this Day', style: TextStyle(color: Color(0xFF2E7D32))),
                              onPressed: () => _showGainCalculator(log),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
