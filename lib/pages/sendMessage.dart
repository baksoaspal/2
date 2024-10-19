import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SendMessagePage extends StatefulWidget {
  final String nomor;

  SendMessagePage({required this.nomor});

  @override
  _SendMessagePageState createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // API Configuration

  final username = "projecart04@gmail.com";
  final password = "advertisement331@";
  final String baseUrl = 'https://id.nobox.ai';
  final String token =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImN0eSI6IkpXVCJ9.eyJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1lIjoicHJvamVjdGFydDA0QGdtYWlsLmNvbSIsImh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3dzLzIwMDUvMDUvaWRlbnRpdHkvY2xhaW1zL25hbWVpZGVudGlmaWVyIjoiMTI2MyIsImV4cCI6MTcyOTIzODM2NywiaXNzIjoiaHR0cHM6Ly9pZC5ub2JveC5haS8iLCJhdWQiOiJodHRwczovL2lkLm5vYm94LmFpLyJ9.zwL9KLOJyoSY8-d2JhEsCdldR8yDhJ6WbquP1Po7Uc8'; // Ganti dengan token autentikasi API NoBox
  final String accountId = '602045505106693'; // Ganti dengan ID akun NoBox

  @override
  void initState() {
    super.initState();
    _numberController.text = widget.nomor; // Set nomor dari widget
  }

  Future<void> sendMessageToAPI(String nomorTujuan, String pesan) async {
    final url = Uri.parse('$baseUrl/Inbox/Send');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "ExtId": nomorTujuan,
          "ChannelId": "1", // Channel ID untuk WhatsApp
          "AccountIds": accountId, // ID akun NoBox
          "BodyType": "Text",
          "Body": pesan,
          "Attachment": "" // Kosongkan jika tidak ada lampiran
        }),
      );

      if (response.statusCode == 200) {
        print('Pesan berhasil terkirim');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesan berhasil dikirim!')),
        );
      } else {
        print('Gagal mengirim pesan: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: ${response.body}')),
        );
      }
    } catch (e) {
      print('Gagal mengirim pesan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e')),
      );
    }
  }

  void sendMessage() {
    final String number = _numberController.text;
    final String message = _messageController.text;

    // Validasi input
    if (number.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nomor tujuan dan pesan tidak boleh kosong')),
      );
      return;
    }

    // Kirim pesan melalui API
    sendMessageToAPI(number, message);

    // Bersihkan form setelah pengiriman
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kirim Pesan Whatsapp'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor Tujuan',
                hintText: 'Contoh: 6281234567890',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Pesan',
                hintText: 'Masukkan pesan yang akan dikirim',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: sendMessage,
              child: Text('Kirim Pesan'),
            ),
          ],
        ),
      ),
    );
  }
}
