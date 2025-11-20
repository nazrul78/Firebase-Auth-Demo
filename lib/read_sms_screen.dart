import 'dart:developer';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';

class ReadSmsScreen extends StatefulWidget {
  const ReadSmsScreen({super.key});

  @override
  State<ReadSmsScreen> createState() => _ReadSmsScreenState();
}

class _ReadSmsScreenState extends State<ReadSmsScreen> {
  final Telephony telephony = Telephony.instance;
  String textReceived = '';
  String serverOTP = '2025';

  void startListening() {
    log('Listening started=======>');

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        // Handle message

        setState(() {
          textReceived = message.body!;
        });

        if (serverOTP == textReceived) {
          log('Welcome! You are authorised.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text('Welcome! You are authorised.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text('OTP does not match. You are not authorised.'),
            ),
          );
        }
      },
      listenInBackground: false,
    );
  }

  @override
  void initState() {
    startListening();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥Read incoming SMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(child: Text('Message Received : $textReceived')),
      ),
    );
  }
}
