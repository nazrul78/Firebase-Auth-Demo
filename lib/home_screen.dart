// import 'package:auth_demo/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  final User currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          // 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            print("Firestore error: ${snapshot.error}");
            return const Center(child: Text("Something went wrong"));
          }

          // ⚠️ No users at all
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          // Filter out current user and map only valid documents
          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('uid') &&
                data.containsKey('name') &&
                data.containsKey('email') &&
                data['uid'] != currentUser.uid;
          }).toList();

          // ⚠️ No other users
          if (users.isEmpty) {
            return const Center(
              child: Text("No other users available to chat."),
            );
          }

          // ✅ Show list
          return ListView(
            children: users.map((userDoc) {
              final user = userDoc.data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user['name'][0].toUpperCase()),
                ),
                title: Text(user['name']),
                subtitle: Text(user['email']),
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => ChatScreen(
                  //       currentUserId: currentUser.uid,
                  //       otherUserId: user['uid'],
                  //       otherUserName: user['name'],
                  //     ),
                  //   ),
                  // );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
