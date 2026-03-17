import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Peringkat Tongkrongan', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil seluruh tagihan yang pernah dibuat oleh akun ini
        stream: FirebaseFirestore.instance
            .collection('bills')
            .where('createdBy', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data pengeluaran.'));
          }

          // 1. Kumpulkan semua pengeluaran per orang
          Map<String, double> spendingPerPerson = {};
          
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            var splitResult = data['splitResult'] as Map<String, dynamic>? ?? {};
            
            splitResult.forEach((name, amount) {
              // Jika namanya "You", ubah jadi nama user biar lebih personal di Leaderboard
              String displayName = name == 'You' ? (user?.displayName ?? 'Kamu') : name;
              spendingPerPerson[displayName] = (spendingPerPerson[displayName] ?? 0) + amount;
            });
          }

          // 2. Urutkan dari yang terbesar (Juara) ke yang terkecil
          List<MapEntry<String, double>> sortedLeaderboard = spendingPerPerson.entries.toList();
          sortedLeaderboard.sort((a, b) => b.value.compareTo(a.value));

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: sortedLeaderboard.length,
            itemBuilder: (context, index) {
              String name = sortedLeaderboard[index].key;
              double totalAmount = sortedLeaderboard[index].value;

              // DESAIN KHUSUS JUARA 1
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Warna Emas
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 64, color: Colors.white),
                      const SizedBox(height: 8),
                      const Text(
                        'SELAMAT KAMU JUARANYA!',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          'Total: Rp ${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      )
                    ],
                  ),
                );
              }

              // DESAIN UNTUK JUARA 2 DAN SETERUSNYA
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  trailing: Text(
                    'Rp ${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}