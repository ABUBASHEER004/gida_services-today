import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart';

class ChatInboxScreen extends StatelessWidget {
  final String currentUserId;

  const ChatInboxScreen({
    super.key,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where(
              'participants',
              arrayContains: currentUserId,
            )
            .orderBy(
              'updatedAt',
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          // Empty
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet",
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,

            itemBuilder: (context, index) {
              final chat =
                  chats[index].data()
                      as Map<String, dynamic>;

              final participants =
                  List<String>.from(
                chat['participants'] ?? [],
              );

              final participantNames =
                  Map<String, dynamic>.from(
                chat['participantNames'] ?? {},
              );

              final otherUserId =
                  participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );

              final otherUserName =
                  participantNames[otherUserId]
                          ?.toString() ??
                      "Unknown User";

              final senderName =
                  participantNames[currentUserId]
                          ?.toString() ??
                      "User";

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),

                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Colors.green.shade100,
                    child: const Icon(
                      Icons.person,
                      color: Colors.green,
                    ),
                  ),

                  title: Text(
                    otherUserName,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    chat['lastMessage']
                            ?.toString() ??
                        "No messages yet",
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId:
                              snapshot.data!.docs[index].id,
                          senderId: currentUserId,
                          senderName: senderName,
                          receiverId: otherUserId,
                          chatName: otherUserName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}