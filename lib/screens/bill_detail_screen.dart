import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillDetailScreen extends StatelessWidget {
  final Map<String, dynamic> billData;
  final String billId;

  const BillDetailScreen({super.key, required this.billData, required this.billId});

  @override
  Widget build(BuildContext context) {
    // 1. Ekstrak data dari database dengan tipe data yang lebih aman
    String title = billData['title'] ?? 'Detail Tagihan';
    double grandTotal = (billData['totalAmount'] ?? 0).toDouble();
    double subTotal = (billData['subTotal'] ?? 0).toDouble();
    double taxAmount = (billData['taxAmount'] ?? 0).toDouble();
    List items = billData['items'] as List? ?? [];
    
    // Perbaikan keamanan konversi tipe data Map agar bebas error
    Map<String, dynamic> splitResult = Map<String, dynamic>.from(billData['splitResult'] ?? {});
    
    // 2. Format Waktu
    Timestamp? t = billData['createdAt'] as Timestamp?;
    String dateString = '-';
    if (t != null) {
      DateTime d = t.toDate();
      dateString = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Struk Tagihan', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER TAGIHAN ---
            Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 60, color: Colors.blueAccent),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(dateString, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      'Grand Total: Rp ${grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
            
            // ERROR SUDAH DIPERBAIKI DI BAWAH INI
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(thickness: 2), // <- Atribut style dihapus
            ),

            // --- RINCIAN PESANAN ---
            const Text('Rincian Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...items.map((item) {
              int qty = item['qty'] ?? 1;
              int price = item['price'] ?? 0;
              int lineTotal = qty * price;
              List assigned = item['assignedTo'] ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${qty}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? 'Barang', style: const TextStyle(fontSize: 16)),
                          Text(assigned.join(', '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('Rp $lineTotal', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),

            const Divider(),
            
            // --- SUBTOTAL & PAJAK ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                  Text('Rp ${subTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (taxAmount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pajak / Service', style: TextStyle(color: Colors.grey)),
                    Text('Rp ${taxAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(thickness: 2),
            ),

            // --- SIAPA BAYAR BERAPA ---
            const Text('Pembagian Tagihan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: splitResult.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text(
                          'Rp ${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}