import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

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
  Map<String, double?> wasteTypes = {'Carton': null, 'Nylon': null};

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
        onPressed: onTap,
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
  final TextEditingController _priceCtrl = TextEditingController();
  List<Map<String, dynamic>> currentBatch = [];
  bool isPriceLocked = true;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    String? draft = prefs.getString('calculator_draft');
    if (draft != null) {
      setState(() => currentBatch = List<Map<String, dynamic>>.from(json.decode(draft)));
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calculator_draft', json.encode(currentBatch));
  }

  void _addItem() {
    double? price = widget.wasteTypes[selectedWaste];
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set a price first.')));
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
        'time': "${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}"
      });
      _weightCtrl.clear();
      _saveDraft();
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  void _showReceiptAndSave() async {
    if (_weightCtrl.text.isNotEmpty) {
      _addItem();
    }
    if (currentBatch.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> savedSellers = prefs.getStringList('saved_sellers') ?? [];
    TextEditingController sellerCtrl = TextEditingController();

    double totalAmount = currentBatch.fold(0.0, (sum, item) => sum + (item['total'] as num).toDouble());
    double totalKg = currentBatch.fold(0.0, (sum, item) => sum + (item['weight'] as num).toDouble());
    String formulaStr = currentBatch.map((e) => "${e['weight']}").join(" + ") + " KG";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFDFADB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Confirm Receipt', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: sellerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Seller Name (e.g. Mama Sikiru)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (savedSellers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Saved Sellers:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: savedSellers.map((seller) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ActionChip(
                            label: Text(seller, style: const TextStyle(fontSize: 12)),
                            backgroundColor: const Color(0xFFE8F5E9),
                            onPressed: () {
                              setDialogState(() {
                                sellerCtrl.text = seller;
                              });
                            },
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text('Waste: $selectedWaste', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Bundles: ${currentBatch.length}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text('Weight Formula:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(formulaStr, style: const TextStyle(fontSize: 13, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Total Weight: ${totalKg.toStringAsFixed(2)} KG', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('Grand Total: ₦${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Add Photo'),
                        onPressed: () async {
                          await _pickImage();
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      if (_imagePath != null)
                        const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    ],
                  ),
                  if (_imagePath != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(_imagePath!), height: 80, width: 80, fit: BoxFit.cover),
                    )
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                onPressed: () async {
                  String seller = sellerCtrl.text.trim();
                  if (seller.isEmpty) seller = "Batch Purchase";
                  
                  if (seller != "Batch Purchase" && !savedSellers.contains(seller)) {
                    savedSellers.add(seller);
                    await prefs.setStringList('saved_sellers', savedSellers);
                  }
                  
                  Navigator.pop(context);
                  _saveBatch(seller, formulaStr);
                },
                child: const Text('Save to History'),
              )
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveBatch(String sellerName, String formulaStr) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedHistory = prefs.getString('history_logs');
    List<dynamic> history = savedHistory != null ? json.decode(savedHistory) : [];

    DateTime now = DateTime.now();
    String dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    double totalAmount = currentBatch.fold(0.0, (sum, item) => sum + (item['total'] as num).toDouble());
    double totalKg = currentBatch.fold(0.0, (sum, item) => sum + (item['weight'] as num).toDouble());
    int totalBundles = currentBatch.length;

    Map<String, dynamic> newReceipt = {
      'receiptId': DateTime.now().millisecondsSinceEpoch.toString(),
      'sellerName': sellerName,
      'wasteType': selectedWaste,
      'formulaStr': formulaStr,
      'imagePath': _imagePath,
      'grandTotal': totalAmount,
      'totalKg': totalKg,
      'totalBundles': totalBundles,
      'timestamp': now.toIso8601String(),
      'items': List.from(currentBatch),
    };

    int existingIndex = history.indexWhere((log) => log['dateKey'] == dateKey);
    
    if (existingIndex >= 0) {
      history[existingIndex]['grandTotal'] += totalAmount;
      history[existingIndex]['totalKg'] += totalKg;
      history[existingIndex]['totalBundles'] += totalBundles;
      (history[existingIndex]['receipts'] as List).insert(0, newReceipt);
    } else {
      history.insert(0, {
        'dateKey': dateKey,
        'timestamp': now.toIso8601String(),
        'grandTotal': totalAmount,
        'totalKg': totalKg,
        'totalBundles': totalBundles,
        'receipts': [newReceipt],
      });
    }

    await prefs.setString('history_logs', json.encode(history));
    await prefs.remove('calculator_draft');
    setState(() { 
      currentBatch.clear(); 
      _imagePath = null;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt Saved to Daily Schedule!')));
  }

  @override
  Widget build(BuildContext context) {
    double? currentPrice = widget.wasteTypes[selectedWaste];
    if (isPriceLocked && currentPrice != null) {
      _priceCtrl.text = currentPrice.toString();
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFFFDFADB),
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Select Waste', style: TextStyle(fontSize: 24, color: Color(0xFF2E7D32)))),
            ...widget.wasteTypes.keys.map((waste) => ListTile(
              title: Text(waste, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                setState(() {
                  selectedWaste = waste;
                  isPriceLocked = true;
                });
                Navigator.pop(context);
              },
            )).toList()
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(selectedWaste.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Price ₦/KG', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        isPriceLocked 
                          ? Text(currentPrice == null ? 'Not Set' : currentPrice.toString(), style: const TextStyle(fontSize: 18, color: Colors.grey))
                          : TextField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                              style: const TextStyle(fontSize: 18),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(isPriceLocked ? Icons.lock : Icons.lock_open, color: Colors.orange, size: 30),
                  onPressed: () async {
                    if (!isPriceLocked) {
                      double? newPrice = double.tryParse(_priceCtrl.text);
                      widget.wasteTypes[selectedWaste] = newPrice;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('waste_types', json.encode(widget.wasteTypes));
                    }
                    setState(() => isPriceLocked = !isPriceLocked);
                  },
                )
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
            Text('Current Draft: ${currentBatch.length} Bundles', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            Expanded(
              child: ListView.builder(
                itemCount: currentBatch.length,
                itemBuilder: (context, index) {
                  var item = currentBatch[index];
                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      title: Text('${item['weight']} KG'),
                      subtitle: Text('₦${item['rate']}/KG'),
                      trailing: Text('₦${(item['total'] as num).toDouble().toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _showReceiptAndSave,
              child: const Text('CALCULATE & SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  String selectedWasteFilter = 'All';

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
        weeklyKg += (log['totalKg'] as num).toDouble();
        weeklyAmount += (log['grandTotal'] as num).toDouble();
        weeklyBundles += (log['totalBundles'] as num).toInt(); 
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
    DateTime checkDate = DateTime(date.year, date.month, date.day);

    List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String formatted = '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';

    if (checkDate == today) return 'Today, $formatted';
    if (checkDate == myYesterday(today)) return 'Yesterday, $formatted';
    return formatted;
  }

  DateTime myYesterday(DateTime today) => today.subtract(const Duration(days: 1));

  void _showGainCalculator(Map<String, dynamic> receipt) {
    TextEditingController sellPriceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFADB),
        title: Text('Calculate Gain: ${receipt['sellerName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Bought: ${(receipt['totalKg'] as num).toDouble().toStringAsFixed(2)} KG'),
            Text('Amount Spent: ₦${(receipt['grandTotal'] as num).toDouble().toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(controller: sellPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Your Selling Price ₦/KG')),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            onPressed: () {
              double sellPrice = double.tryParse(sellPriceCtrl.text) ?? 0;
              double totalKg = (receipt['totalKg'] as num).toDouble();
              double grandTotal = (receipt['grandTotal'] as num).toDouble();
              
              double revenue = sellPrice * totalKg;
              double profit = revenue - grandTotal;
              
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFFFDFADB),
                  title: const Text('Gain Receipt', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seller: ${receipt['sellerName']}'),
                      Text('Total KG: ${totalKg.toStringAsFixed(2)} KG'),
                      Text('Total Spent: ₦${grandTotal.toStringAsFixed(2)}'),
                      Text('Total Revenue: ₦${revenue.toStringAsFixed(2)}'),
                      const Divider(),
                      Text('Net Profit: ₦${profit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))
                  ],
                ),
              );
            },
            child: const Text('Calculate'),
          )
        ],
      ),
    );
  }

  void _showDayGainCalculator(Map<String, dynamic> dayLog) {
    TextEditingController sellPriceCtrl = TextEditingController();
    double totalKg = (dayLog['totalKg'] as num).toDouble();
    double grandTotal = (dayLog['grandTotal'] as num).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFADB),
        title: Text('Gain for Entire Day (${_formatDate(dayLog['timestamp'])})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Day KG: ${totalKg.toStringAsFixed(2)} KG'),
            Text('Total Day Spent: ₦${grandTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(controller: sellPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Selling Price ₦/KG')),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
            onPressed: () {
              double sellPrice = double.tryParse(sellPriceCtrl.text) ?? 0;
              double revenue = sellPrice * totalKg;
              double profit = revenue - grandTotal;
              
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFFFDFADB),
                  title: const Text('Daily Gain Summary', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${_formatDate(dayLog['timestamp'])}'),
                      Text('Total KG Sold: ${totalKg.toStringAsFixed(2)} KG'),
                      Text('Total Cost: ₦${grandTotal.toStringAsFixed(2)}'),
                      Text('Total Revenue: ₦${revenue.toStringAsFixed(2)}'),
                      const Divider(),
                      Text('Net Daily Profit: ₦${profit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
                ),
              );
            },
            child: const Text('Calculate Day Profit'),
          )
        ],
      ),
    );
  }

  void _shareReceipt(Map<String, dynamic> receipt) {
    String text = "=== MARKET RECEIPT ===\n"
        "Seller: ${receipt['sellerName']}\n"
        "Waste: ${receipt['wasteType']}\n"
        "Formula: ${receipt['formulaStr']}\n"
        "Total Weight: ${receipt['totalKg']} KG\n"
        "Total Amount: ₦${receipt['grandTotal']}\n"
        "Time: ${receipt['timestamp']}";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFADB),
        title: const Text('Shareable Receipt Text'),
        content: SelectableText(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Set<String> wasteCategories = {'All'};
    for (var day in historyLogs) {
      List receipts = day['receipts'] ?? [];
      for (var r in receipts) {
        if (r['wasteType'] != null) wasteCategories.add(r['wasteType']);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Schedule')),
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
          
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: wasteCategories.map((cat) {
                bool isSelected = selectedWasteFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                    selectedColor: const Color(0xFF2E7D32),
                    backgroundColor: const Color(0xFFE0E0E0),
                    onSelected: (bool selected) {
                      setState(() => selectedWasteFilter = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: historyLogs.length,
              itemBuilder: (context, index) {
                var dayLog = historyLogs[index];
                List receipts = dayLog['receipts'] ?? [];

                List filteredReceipts = selectedWasteFilter == 'All'
                    ? receipts
                    : receipts.where((r) => r['wasteType'] == selectedWasteFilter).toList();

                if (filteredReceipts.isEmpty) return const SizedBox.shrink();

                return Card(
                  color: const Color(0xFFF3E5F5),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(dayLog['timestamp']), style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteDay(index)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${(dayLog['totalKg'] as num).toDouble().toStringAsFixed(2)} KG | ₦${(dayLog['grandTotal'] as num).toDouble().toStringAsFixed(0)} | ${dayLog['totalBundles']} Bundles'),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _showDayGainCalculator(dayLog),
                          child: const Text('📊 Calculate Gain for Today', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                        )
                      ],
                    ),
                    children: filteredReceipts.map<Widget>((receipt) {
                      return Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: ExpansionTile(
                          leading: const Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${receipt['sellerName']} (${receipt['wasteType']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                              IconButton(
                                icon: const Icon(Icons.share, size: 18, color: Colors.blue),
                                onPressed: () => _shareReceipt(receipt),
                              )
                            ],
                          ),
                          subtitle: Text('Formula: ${receipt['formulaStr'] ?? ''}\nTotal: ₦${(receipt['grandTotal'] as num).toDouble().toStringAsFixed(0)}'),
                          children: [
                            if (receipt['imagePath'] != null && File(receipt['imagePath']).existsSync()) ...[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(receipt['imagePath']), height: 120, width: double.infinity, fit: BoxFit.cover),
                                ),
                              ),
                            ],
                            ...(receipt['items'] as List).map<Widget>((item) {
                              return ListTile(
                                leading: const Icon(Icons.shopping_bag, color: Color(0xFF4CAF50), size: 18),
                                title: Text('1 Bundle (${item['weight']} KG)'),
                                subtitle: Text('Price: ₦${item['rate']}/KG @ ${item['time']}'),
                                trailing: Text('₦${(item['total'] as num).toDouble().toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            TextButton.icon(
                              icon: const Icon(Icons.calculate, color: Color(0xFF2E7D32)),
                              label: const Text('Calculate Gain for this Batch', style: TextStyle(color: Color(0xFF2E7D32))),
                              onPressed: () => _showGainCalculator(receipt),
                            )
                          ],
                        ),
                      );
                    }).toList(),
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
