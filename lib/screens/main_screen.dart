import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'login_screen.dart';
import 'add_bill_screen.dart';
import 'bill_detail_screen.dart';
import 'leaderboard_screen.dart';
import 'premium_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildHomePage(),
      _buildScanPage(),
      _buildProfilePage(),
    ];
  }

  // --- HALAMAN BERANDA ---
  Widget _buildHomePage() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, userSnapshot) {
        String username = user?.displayName ?? 'User';
        String status = 'Basic';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var data = userSnapshot.data!.data() as Map<String, dynamic>;
          username = data['username'] ?? username;
          status = data['status'] ?? 'Basic';
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bills')
              .where('createdBy', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, billSnapshot) {
            double totalPengeluaran = 0;
            List<QueryDocumentSnapshot> bills = [];
            int billsThisWeek = 0;

            if (billSnapshot.hasData) {
              bills = billSnapshot.data!.docs;
              DateTime now = DateTime.now();
              DateTime oneWeekAgo = now.subtract(const Duration(days: 7));

              for (var doc in bills) {
                var data = doc.data() as Map<String, dynamic>;
                totalPengeluaran += (data['totalAmount'] ?? 0).toDouble();

                Timestamp? createdAt = data['createdAt'] as Timestamp?;
                if (createdAt != null && createdAt.toDate().isAfter(oneWeekAgo)) {
                  billsThisWeek++;
                }
              }
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                titleSpacing: 24.0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hi, $username 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: status == 'Premium' ? Colors.amber.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        status == 'Premium' ? 'Premium' : '$billsThisWeek/3 Minggu ini',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status == 'Premium' ? Colors.amber.shade800 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pengeluaran Tongkronganmu', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('Rp ${totalPengeluaran.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen())),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Lihat pengeluaran teman temanmu', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text('Riwayat Split Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: bills.isEmpty
                          ? const Center(child: Text('Belum ada tagihan nih.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: bills.length,
                              itemBuilder: (context, index) {
                                var data = bills[index].data() as Map<String, dynamic>;
                                Timestamp? t = data['createdAt'] as Timestamp?;
                                String dateStr = t != null ? '${t.toDate().day}/${t.toDate().month}/${t.toDate().year}' : '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                                  elevation: 0,
                                  child: ListTile(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BillDetailScreen(billData: data, billId: bills[index].id))),
                                    leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                                    title: Text(data['title'] ?? 'Acara', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(dateStr, style: const TextStyle(fontSize: 11)),
                                    trailing: Text('Rp ${(data['totalAmount'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                child: FloatingActionButton(
                  onPressed: () {
                    if (status == 'Basic' && billsThisWeek >= 3) {
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup popup
                          // Pindah ke layar premium
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
                        }, 
                        child: const Text('Upgrade Sekarang')
                      );
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBillScreen()));
                    }
                  },
                  backgroundColor: (status == 'Basic' && billsThisWeek >= 3) ? Colors.grey : Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HALAMAN SCAN ---
  Widget _buildScanPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text('Scan Struk Otomatis', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Foto struk kamu, biar AI yang hitung harganya & pajaknya!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _pickAndScanImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Buka Kamera', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _pickAndScanImage(ImageSource.gallery),
              icon: const Icon(Icons.image),
              label: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
    );

    try {
      // JANGAN LUPA MASUKKAN API KEY BARUMU DI SINI UNTUK SEMENTARA
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; 
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final imageBytes = await image.readAsBytes();

      // KODE DIPERBAIKI: Prompt AI sekarang meminta Pajak (Tax) juga
      final prompt = TextPart('''
        Anda adalah asisten pembaca struk kasir yang sangat akurat.
        Tugas Anda adalah mengekstrak daftar barang belanjaan dan total pajak dari struk ini.
        Abaikan teks lain seperti nama toko, alamat, diskon, kembalian, atau ucapan terima kasih.
        
        KEMBALIKAN HANYA JSON VALID TANPA MARKDOWN. Format yang diwajibkan:
        {
          "items": [
            {"name": "Kopi Susu", "price": 15000, "qty": 1},
            {"name": "Roti", "price": 5000, "qty": 2}
          ],
          "tax": 2000
        }
        Jika tidak ada pajak (Tax/PB1/Service), isi "tax" dengan 0. Harga harus angka bulat.
      ''');

      final response = await model.generateContent([
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)])
      ]);

      String responseText = response.text ?? '{}';
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      // Parsing format JSON yang baru (sekarang berupa Map, bukan sekadar List)
      Map<String, dynamic> jsonResult = jsonDecode(responseText);
      List<dynamic> jsonList = jsonResult['items'] ?? [];
      
      // Mengambil nilai pajak (kalau AI berhasil menemukannya)
      double parsedTax = double.tryParse(jsonResult['tax']?.toString() ?? '0') ?? 0;

      List<Map<String, dynamic>> parsedItems = [];
      for (var item in jsonList) {
        parsedItems.add({
          'name': item['name'].toString(),
          'price': int.tryParse(item['price'].toString()) ?? 0,
          'qty': int.tryParse(item['qty'].toString()) ?? 1,
          'assignedTo': [], 
        });
      }

      if (mounted) Navigator.pop(context); // Tutup loading

      if (parsedItems.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI tidak menemukan daftar barang.')));
        return;
      }

      // LEMPAR DATA BARANG & PAJAK KE HALAMAN TAGIHAN
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddBillScreen(scannedItems: parsedItems, scannedTax: parsedTax),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses struk: $e')));
    }
  }

  // --- HALAMAN PROFIL ---
  // --- HALAMAN PROFIL (VERSI FULL PREMIUM) ---
  Widget _buildProfilePage() {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String username = data['username'] ?? 'User';
        String status = data['status'] ?? 'Basic';
        bool isPremium = status == 'Premium';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Foto Profil Default
              const CircleAvatar(
                radius: 50, 
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 50, color: Colors.white)
              ),
              const SizedBox(height: 16),
              Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // --- CHIP STATUS (HIJAU JIKA PREMIUM) ---
              Chip(
                label: Text(
                  status.toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)
                ),
                backgroundColor: isPremium ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              const SizedBox(height: 24),

              // --- BOX TERIMA KASIH KHUSUS PREMIUM ---
              if (isPremium)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volunteer_activism, color: Colors.green, size: 30),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Terima Kasih ❤️', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text(
                              'Dukunganmu sangat berarti bagi pengembangan Equa. Nikmati akses tanpa batas! 🔥',
                              style: TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(),

              // --- MENU: GANTI USERNAME ---
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text('Ganti Username', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  TextEditingController nameController = TextEditingController(text: username);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Ganti Username'),
                      content: TextField(
                        controller: nameController, 
                        decoration: const InputDecoration(hintText: "Masukkan username baru"),
                        textCapitalization: TextCapitalization.words,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isNotEmpty) {
                              await user!.updateDisplayName(nameController.text.trim());
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'username': nameController.text.trim()});
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // --- MENU: GANTI PASSWORD ---
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.blueAccent),
                title: const Text('Ganti Password', style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () async {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link reset password sudah dikirim ke email kamu!'), backgroundColor: Colors.green)
                      );
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim email reset.')));
                  }
                },
              ),

              // --- MENU: UPGRADE PREMIUM (HANYA MUNCUL JIKA BASIC) ---
              if (!isPremium) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Upgrade ke Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  subtitle: const Text('Buka semua fitur tanpa batas'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.amber),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen())),
                ),
              ],

              const Divider(),
              
              // --- MENU: LOGOUT ---
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Keluar Akun', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
              ),
              
              const SizedBox(height: 40),
              const Text('Equa App v2.0 - Made with ❤️', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  // --- DIALOGS ---
  void _showLimitReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Tercapai! 🛑'),
        content: const Text('Upgrade ke Premium untuk buat tagihan tanpa batas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nanti')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 2);
            }, 
            child: const Text('Upgrade Sekarang')
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beli Premium'),
        content: const Text('Hanya Rp 5.000 seumur hidup!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).update({'status': 'Premium'});
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text('Bayar Rp 5.000')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 65,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined, size: 32), selectedIcon: Icon(Icons.home, size: 32, color: Colors.blueAccent), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.document_scanner_outlined, size: 32), selectedIcon: Icon(Icons.document_scanner, size: 32, color: Colors.blueAccent), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.person_outline, size: 32), selectedIcon: Icon(Icons.person, size: 32, color: Colors.blueAccent), label: 'Profile'),
        ],
      ),
    );
  }
}