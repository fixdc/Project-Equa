import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPayment = 'GoPay';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'GoPay', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
    {'name': 'DANA', 'icon': Icons.account_balance_wallet_outlined, 'color': Colors.blueAccent},
    {'name': 'BCA Virtual Account', 'icon': Icons.food_bank, 'color': Colors.indigo},
    {'name': 'QRIS', 'icon': Icons.qr_code_2, 'color': Colors.redAccent},
  ];

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Sesi login tidak valid, coba relogin.';

      // 1. GANTI INI DENGAN URL VERCEL KAMU! 
      // (Pastikan tidak ada tanda '/' di paling akhir URL)
      const String backendUrl = 'https://project-63gs5.vercel.app/api/create-transaction';

      // 2. Minta Link Pembayaran ke Vercel
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'username': user.displayName ?? 'User Equa',
          'amount': 5000, 
        }),
      );

      // 3. Eksekusi Hasilnya
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String redirectUrl = data['redirect_url'];

        // Buka halaman Midtrans di Browser HP
        final Uri url = Uri.parse(redirectUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          // Tutup halaman Premium di aplikasi setelah browser terbuka
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Silakan selesaikan pembayaran di browser...'), backgroundColor: Colors.blueAccent)
            );
          }
        } else {
          throw 'Tidak dapat membuka halaman pembayaran';
        }
      } else {
        throw 'Server menolak: ${response.body}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Upgrade ke Premium', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER BANNER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text('Equa Premium', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Sekali bayar, nikmati selamanya.', style: TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- FITUR PREMIUM ---
            const Text('Keuntungan Premium', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.document_scanner, 'Scan Struk AI Tanpa Batas', 'Gunakan kecerdasan AI untuk scan struk sepuasnya tanpa batasan 3x seminggu.'),
            _buildFeatureItem(Icons.group_add, 'Buat Tagihan Tak Terbatas', 'Nongkrong tiap hari? Buat split bill sebanyak yang kamu mau.'),
            _buildFeatureItem(Icons.verified, 'Badge Premium', 'Pamerkan lencana Premium berkilau di profilmu.'),
            const SizedBox(height: 32),
            const Divider(),

            // --- METODE PEMBAYARAN ---
            const SizedBox(height: 16),
            const Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _selectedPayment == method['name'] ? Colors.amber : Colors.grey.shade300, width: _selectedPayment == method['name'] ? 2 : 1),
                ),
                child: ListTile(
                  onTap: () => setState(() => _selectedPayment = method['name'] as String),
                  leading: Icon(method['icon'] as IconData, color: method['color'] as Color),
                  title: Text(method['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Radio<String>(
                    value: method['name'] as String,
                    groupValue: _selectedPayment,
                    activeColor: Colors.amber.shade700,
                    onChanged: (value) => setState(() => _selectedPayment = value!),
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // --- TOMBOL BAYAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Rp 5.000', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Bayar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.amber.shade800),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}