import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'add_bill_screen.dart';

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
      _buildDummyPage('Scan Struk', Icons.receipt_outlined, 'Kamera untuk scan struk otomatis'),
      _buildProfilePage(),
    ];
  }

  // 1. WIDGET HALAMAN SCAN (SEMENTARA)
  Widget _buildDummyPage(String title, IconData icon, String desc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // 2. WIDGET HALAMAN BERANDA (SUDAH TERKONEKSI DATABASE)
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

        // KODE DIPERBAIKI: Tarik SEMUA tagihan yang dibuat oleh akun ini (mengabaikan nama partisipan)
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bills')
              .where('createdBy', isEqualTo: user?.uid) 
              .snapshots(),
          builder: (context, billSnapshot) {
            
            double totalPengeluaran = 0; // Variabel Spotify Wrapped
            List<QueryDocumentSnapshot> bills = [];

            if (billSnapshot.hasData) {
              bills = billSnapshot.data!.docs;
              
              // Urutkan tagihan dari yang paling baru
              bills.sort((a, b) {
                Timestamp tA = (a.data() as Map<String, dynamic>)['createdAt'] ?? Timestamp.now();
                Timestamp tB = (b.data() as Map<String, dynamic>)['createdAt'] ?? Timestamp.now();
                return tB.compareTo(tA);
              });

              // Hitung total sirkulasi uang dari SEMUA tagihan
              for (var doc in bills) {
                var data = doc.data() as Map<String, dynamic>;
                totalPengeluaran += (data['totalAmount'] ?? 0).toDouble();
              }
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hi, $username 👋',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'Premium' ? Colors.amber.shade100 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: status == 'Premium' ? Colors.amber.shade800 : Colors.grey.shade700,
                        ),
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
                    // Kartu Ringkasan Tagihan (Vibe Spotify Wrapped)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pengeluaran Tongkronganmu',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          // Menampilkan angka fantastis
                          Text(
                            'Rp ${totalPengeluaran.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blueAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Bayar Utang'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Tagih Teman'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Riwayat Split Bill',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    
                    // Area Daftar Riwayat
                    Expanded(
                      child: bills.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text('Belum ada tagihan nih.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                  const Text('Yuk buat split bill pertamamu!', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: bills.length,
                              itemBuilder: (context, index) {
                                var data = bills[index].data() as Map<String, dynamic>;
                                String title = data['title'] ?? 'Acara';
                                double grandTotal = (data['totalAmount'] ?? 0).toDouble();
                                String billStatus = data['status'] ?? 'Aktif';
                                
                                // Cek patungan spesifik untuk akun ini jika namanya ada di partisipan
                                var splitResult = data['splitResult'] as Map<String, dynamic>? ?? {};
                                double myShare = (splitResult['Kamu'] ?? splitResult[username] ?? 0.0).toDouble();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  color: Colors.grey.shade50,
                                  elevation: 0,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: billStatus == 'Aktif' ? Colors.blue.shade100 : Colors.green.shade100,
                                      child: Icon(
                                        billStatus == 'Aktif' ? Icons.receipt_long : Icons.check_circle,
                                        color: billStatus == 'Aktif' ? Colors.blueAccent : Colors.green,
                                      ),
                                    ),
                                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Grand Total: Rp ${grandTotal.toStringAsFixed(0)}'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Bagianmu', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(
                                          'Rp ${myShare.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBillScreen()));
                },
                backgroundColor: Colors.blueAccent,
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            );
          },
        );
      },
    );
  }

  // 3. WIDGET HALAMAN PROFIL
  Widget _buildProfilePage() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text('Tidak ada user aktif'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String username = user.displayName ?? 'User';
        String status = 'Basic';

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          username = data['username'] ?? username;
          status = data['status'] ?? 'Basic';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, size: 50, color: Colors.blueAccent),
              ),
              const SizedBox(height: 16),
              Text(
                username,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Premium' ? Colors.amber.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status == 'Premium' ? Colors.amber.shade800 : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text('Ganti Username'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  TextEditingController nameController = TextEditingController(text: username);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Ganti Username'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(hintText: "Masukkan username baru"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isNotEmpty) {
                              await user.updateDisplayName(nameController.text.trim());
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                'username': nameController.text.trim(),
                              });
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
              const Divider(),

              if (status == 'Basic') ...[
                ListTile(
                  leading: const Icon(Icons.star, color: Colors.amber),
                  title: const Text('Upgrade Premium', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Sekali bayar seumur hidup (Rp 5.000)'),
                  trailing: const Icon(Icons.payment, color: Colors.green),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Beli Premium'),
                        content: const Text(
                          'Dapatkan akses fitur tak terbatas hanya dengan Rp 5.000. Lanjutkan pembayaran?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                'status': 'Premium',
                              });
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Selamat! Akun kamu sekarang Premium! 🌟'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade400),
                            child: const Text('Bayar Rp 5.000', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),
              ],

              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.blueAccent),
                title: const Text('Ganti Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link ganti password telah dikirim ke email kamu!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengirim email reset')),
                      );
                    }
                  }
                },
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 65,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, size: 32, color: Colors.black87),
            selectedIcon: Icon(Icons.home, size: 32, color: Colors.blueAccent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined, size: 32, color: Colors.black87),
            selectedIcon: Icon(Icons.receipt, size: 32, color: Colors.blueAccent),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 32, color: Colors.black87),
            selectedIcon: Icon(Icons.person, size: 32, color: Colors.blueAccent),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}