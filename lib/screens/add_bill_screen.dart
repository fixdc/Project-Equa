import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddBillScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? scannedItems; 
  final double? scannedTax; // KODE BARU: Menerima titipan pajak dari AI

  const AddBillScreen({super.key, this.scannedItems, this.scannedTax});

  @override
  State<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends State<AddBillScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0'); 
  bool _isTaxPercentage = true; 
  
  List<String> _participants = [];
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // KODE DIPERBAIKI: Hanya masukkan "You", hilangkan username asli.
    _participants.add('You');

    // Jika ada data barang dari hasil scan, masukkan otomatis
    if (widget.scannedItems != null) {
      _items.addAll(widget.scannedItems!);
    }

    // Jika ada data pajak dari hasil scan, masukkan otomatis
    if (widget.scannedTax != null && widget.scannedTax! > 0) {
      _isTaxPercentage = false; // Ubah otomatis ke mode 'Rp' (Nominal)
      _taxController.text = widget.scannedTax!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  double get _subTotal {
    double total = 0;
    for (var item in _items) { total += (item['price'] as int) * (item['qty'] as int); }
    return total;
  }

  double get _taxAmount {
    double taxInput = double.tryParse(_taxController.text) ?? 0;
    return _isTaxPercentage ? _subTotal * (taxInput / 100) : taxInput;
  }

  double get _grandTotal => _subTotal + _taxAmount;

  Map<String, double> get _calculateSplit {
    Map<String, double> splitResult = {};
    for (var person in _participants) { splitResult[person] = 0.0; }

    for (var item in _items) {
      double lineTotal = (item['price'] * item['qty']).toDouble();
      List<String> assigned = List<String>.from(item['assignedTo']);
      if (assigned.isNotEmpty) {
        double splitPerPerson = lineTotal / assigned.length;
        for (var person in assigned) { splitResult[person] = (splitResult[person] ?? 0) + splitPerPerson; }
      }
    }

    double currentTax = _taxAmount;
    double currentSubTotal = _subTotal;
    if (currentTax > 0 && currentSubTotal > 0) {
      splitResult.forEach((person, amount) {
        double taxShare = (amount / currentSubTotal) * currentTax;
        splitResult[person] = amount + taxShare;
      });
    }
    return splitResult;
  }

  void _showAddParticipantDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Orang'),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Nama teman (mis: Andi)'), textCapitalization: TextCapitalization.words),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() { _participants.add(nameController.text.trim()); });
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambah orang dulu ya!')));
      return;
    }

    TextEditingController itemNameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController qtyController = TextEditingController(text: '0'); 
    List<String> selectedPersons = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Tambah Pesanan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: itemNameController, decoration: const InputDecoration(labelText: 'Nama Barang (mis: Kopi)'), textCapitalization: TextCapitalization.words),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(flex: 2, child: TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Satuan (Rp)'))),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah'))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Siapa yang pesan ini?', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._participants.map((person) {
                      return CheckboxListTile(
                        title: Text(person), value: selectedPersons.contains(person), contentPadding: EdgeInsets.zero, dense: true, activeColor: Colors.blueAccent,
                        onChanged: (bool? value) {
                          setStateDialog(() {
                            if (value == true) { selectedPersons.add(person); } else { selectedPersons.remove(person); }
                            qtyController.text = selectedPersons.length.toString();
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () {
                    int price = int.tryParse(priceController.text) ?? 0;
                    int qty = int.tryParse(qtyController.text) ?? 0;
                    if (itemNameController.text.isEmpty || price <= 0 || qty <= 0 || selectedPersons.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nama, harga, dan pilih minimal 1 orang!')));
                      return;
                    }
                    setState(() { _items.add({'name': itemNameController.text.trim(), 'price': price, 'qty': qty, 'assignedTo': selectedPersons}); });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), child: const Text('Simpan Barang', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveBill() async {
    if (_titleController.text.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi judul acara dan minimal 1 pesanan!')));
      return;
    }

    bool hasUnassigned = _items.any((item) => (item['assignedTo'] as List).isEmpty);
    if (hasUnassigned) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ada pesanan yang belum dipilih siapa yang bayar!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('bills').add({
        'title': _titleController.text.trim(),
        'subTotal': _subTotal,
        'taxType': _isTaxPercentage ? 'percent' : 'nominal', 
        'taxInput': double.tryParse(_taxController.text) ?? 0, 
        'taxAmount': _taxAmount,
        'totalAmount': _grandTotal,
        'participants': _participants,
        'items': _items,
        'splitResult': _calculateSplit, 
        'createdBy': user?.uid,
        'creatorName': user?.displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Aktif',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tagihan berhasil dibuat! 🎉'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> splitPreview = _calculateSplit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Buat Tagihan', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black87)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: _titleController, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: 'Nama Acara (mis: Nongkrong...)', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey))),
                  const Divider(), const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Partisipan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(onPressed: _showAddParticipantDialog, icon: const Icon(Icons.person_add, size: 18), label: const Text('Tambah Orang'))
                    ],
                  ),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _participants.map((person) => Chip(
                      label: Text(person), backgroundColor: Colors.blue.shade50, deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _participants.remove(person);
                          for (var item in _items) { (item['assignedTo'] as List).remove(person); }
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rincian Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton.icon(onPressed: _showAddItemDialog, icon: const Icon(Icons.add_shopping_cart, size: 18), label: const Text('Tambah Pesanan'))
                    ],
                  ),
                  if (_items.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Belum ada pesanan.', style: TextStyle(color: Colors.grey)))),
                    
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final lineTotal = item['price'] * item['qty'];
                      final assignedList = (item['assignedTo'] as List).join(', ');
                      final isUnassigned = (item['assignedTo'] as List).isEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12), color: isUnassigned ? Colors.red.shade50 : Colors.grey.shade50, elevation: 0,
                        shape: RoundedRectangleBorder(side: BorderSide(color: isUnassigned ? Colors.red.shade200 : Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text('${item['qty']}x ${item['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isUnassigned ? 'Klik untuk pilih orang ➔' : 'Patungan: $assignedList', style: TextStyle(color: isUnassigned ? Colors.redAccent : Colors.blueAccent, fontWeight: isUnassigned ? FontWeight.bold : FontWeight.normal)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rp $lineTotal', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () { setState(() { _items.removeAt(index); }); })
                            ],
                          ),
                          onTap: () {
                            List<String> tempSelected = List<String>.from(item['assignedTo']);
                            showDialog(
                              context: context,
                              builder: (context) {
                                return StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    return AlertDialog(
                                      title: Text('Siapa yang pesan ${item['name']}?'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: _participants.map((person) {
                                            return CheckboxListTile(
                                              title: Text(person), value: tempSelected.contains(person),
                                              onChanged: (bool? value) {
                                                setStateDialog(() { if (value == true) { tempSelected.add(person); } else { tempSelected.remove(person); } });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _items[index]['assignedTo'] = tempSelected;
                                              if (tempSelected.isNotEmpty) { _items[index]['qty'] = tempSelected.length; }
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Simpan'),
                                        )
                                      ],
                                    );
                                  }
                                );
                              }
                            );
                          },
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.receipt, color: Colors.grey), const SizedBox(width: 8),
                      const Expanded(child: Text('Pajak / Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      Container(
                        height: 40, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                        child: ToggleButtons(
                          isSelected: [_isTaxPercentage, !_isTaxPercentage],
                          onPressed: (index) { setState(() { _isTaxPercentage = index == 0; }); },
                          borderRadius: BorderRadius.circular(8), fillColor: Colors.blueAccent.withOpacity(0.1), selectedColor: Colors.blueAccent, color: Colors.grey,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          children: const [Text('%', style: TextStyle(fontWeight: FontWeight.bold)), Text('Rp', style: TextStyle(fontWeight: FontWeight.bold))],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: _taxController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                          decoration: InputDecoration(hintText: '0', contentPadding: const EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          onChanged: (value) { setState(() {}); },
                        ),
                      )
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  if (_items.isNotEmpty) ...[
                    const Text('Siapa Bayar Berapa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: splitPreview.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 16)),
                                Text('Rp ${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grand Total', style: TextStyle(color: Colors.grey)),
                      if (_taxAmount > 0) Text('+ Rp ${_taxAmount.toStringAsFixed(0)} (Pajak)', style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('Rp ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveBill,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}