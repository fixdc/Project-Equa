const express = require('express');
const cors = require('cors');
const midtransClient = require('midtrans-client');
const admin = require('firebase-admin');

const app = express();
app.use(cors());
app.use(express.json());

// 1. Inisialisasi Firebase Admin (Akses langsung ke database kamu)
// Nanti kita amankan kuncinya di Environment Variable Vercel
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT))
  });
}
const db = admin.firestore();

// 2. Inisialisasi Midtrans
const snap = new midtransClient.Snap({
  isProduction: false, // Kita pakai mode Sandbox (Testing) dulu ya
  serverKey: process.env.MIDTRANS_SERVER_KEY,
  clientKey: process.env.MIDTRANS_CLIENT_KEY
});

// --- ENDPOINT 1: MINTA LINK PEMBAYARAN (Dipanggil oleh Flutter) ---
app.post('/api/create-transaction', async (req, res) => {
  try {
    const { uid, username, amount } = req.body;
    const orderId = `PREMIUM-${uid}-${Date.now()}`; // Bikin ID Unik

    const parameters = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount
      },
      customer_details: {
        first_name: username,
      },
      // Titip UID Fikri di sini biar gampang dicari pas lunas
      custom_field1: uid 
    };

    const transaction = await snap.createTransaction(parameters);
    // Kirim balik link halaman pembayaran Midtrans ke HP Fikri
    res.json({
      token: transaction.token,
      redirect_url: transaction.redirect_url 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// --- ENDPOINT 2: WEBHOOK MIDTRANS (Sistem Lapor Otomatis) ---
// Midtrans akan diam-diam menembak URL ini kalau user sudah sukses transfer
app.post('/api/webhook', async (req, res) => {
  try {
    const notificationJson = req.body;
    console.log("Notifikasi masuk:", notificationJson);
    const statusResponse = await snap.transaction.notification(notificationJson);

    const transactionStatus = statusResponse.transaction_status;
    const fraudStatus = statusResponse.fraud_status;
    const uid = statusResponse.custom_field1; // Ambil UID yang dititip tadi
    
    // Kalau statusnya settlement (Lunas) atau capture (Kartu Kredit sukses)
    if (transactionStatus == 'capture' || transactionStatus == 'settlement') {
      if (fraudStatus == 'accept') {
        // SIHIR TERJADI DI SINI: Update status Firebase user jadi Premium!
        await db.collection('users').doc(uid).update({ status: 'Premium' });
        console.log(`Hore! Akun ${uid} berhasil jadi Premium.`);
      }
    }
    res.status(200).send('OK'); // Wajib balas OK ke Midtrans
  } catch (error) {
    console.error(error);
    res.status(500).send('Error');
  }
});

module.exports = app;