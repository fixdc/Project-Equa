import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Inisialisasi halaman sementara
    _pages = [
   _buildHomePage(), // Kita ganti Beranda menjadi fungsi khusus ini
   _buildDummyPage('Scan Struk', Icons.receipt_outlined, 'Kamera untuk scan struk otomatis'),
   _buildProfilePage(),
 ];
  }

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

  Widget _buildHomePage() {
final user = FirebaseAuth.instance.currentUser;

  // StreamBuilder agar status dan nama otomatis berubah secara realtime kalau di-update
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
    builder: (context, snapshot) {
      // Nilai bawaan sebelum data selesai di-load
      String username = user?.displayName ?? 'User';
      String status = 'Basic';

      // Jika data dari database sudah terbaca
      if (snapshot.hasData && snapshot.data!.exists) {
        var data = snapshot.data!.data() as Map<String, dynamic>;
        username = data['username'] ?? username;
        status = data['status'] ?? 'Basic';
      }

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0, // Menghilangkan bayangan garis bawah
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bagian Kiri: Sapaan Username
              Text(
                'Hi, $username 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              
              // Bagian Kanan: Badge Status (Basic / Premium)
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
        body: const Center(
          child: Text('Daftar Split Bill akan muncul di sini', style: TextStyle(color: Colors.grey)),
        ),
      );
    },
  );
  }

  // Widget sementara untuk halaman Profil (Ada tombol logout-nya)
  // Halaman Profil (Dilengkapi fitur Edit Username & Reset Password)
  Widget _buildProfilePage() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text('Tidak ada user aktif'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        // Tampilkan loading saat mengambil data
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
              // Foto Profil Default
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, size: 50, color: Colors.blueAccent),
              ),
              const SizedBox(height: 16),
              
              // Nama dan Badge Status
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

              // Menu 1: Ganti Username
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text('Ganti Username'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Munculkan Pop-up untuk ketik nama baru
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
                              // Update di Firebase Auth
                              await user.updateDisplayName(nameController.text.trim());
                              // Update di Firestore Database
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                'username': nameController.text.trim(),
                              });
                              if (context.mounted) Navigator.pop(context); // Tutup dialog
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
                    // Munculkan Pop-up Simulasi Pembayaran
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
                              // Simulasi proses bayar sukses, lalu update status di database
                              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                                'status': 'Premium',
                              });
                              
                              if (context.mounted) {
                                Navigator.pop(context); // Tutup pop-up
                                // Tampilkan notifikasi sukses
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

              // Menu 2: Ganti Password (Kirim Email Reset)
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

              // Menu 3: Logout
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
      // Tampilkan halaman sesuai index yang dipilih
      body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kartu Ringkasan Tagihan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
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
                        'Total Tagihan Aktif',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Nanti angka ini akan kita ambil dari database perhitungannya
                      const Text(
                        'Rp 0',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
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
                
                // 2. Judul Riwayat
                const Text(
                  'Riwayat Split Bill',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                
                // 3. Area Daftar Riwayat (Sementara kita buat kosong/empty state)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada tagihan nih.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const Text(
                          'Yuk buat split bill pertamamu!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      
      // Bottom Navigation bergaya Material 3
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100, // Warna kotak highlight
        
        // 1. KODE INI UNTUK MENGHAPUS SEMUA TULISAN
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, 
        
        // 2. MENGATUR TINGGI BAR AGAR PAS DENGAN ICON BESAR
        height: 65, 
        
        destinations: const [
          // Tab 1: Beranda
          NavigationDestination(
            // 3. ICON DIPERBESAR MENJADI SIZE 32 & DIPILIH YANG LEBIH SIMPEL
            icon: Icon(Icons.home_outlined, size: 32, color: Colors.black87),
            selectedIcon: Icon(Icons.home, size: 32, color: Colors.blueAccent),
            label: 'Home', // Label tetap wajib ditulis di kode, tapi tidak akan muncul di layar
          ),
          
          // Tab 2: Scan Struk (Icon diganti yang lebih simpel)
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined, size: 32, color: Colors.black87),
            selectedIcon: Icon(Icons.receipt, size: 32, color: Colors.blueAccent),
            label: 'Scan',
          ),
          
          // Tab 3: Profil
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