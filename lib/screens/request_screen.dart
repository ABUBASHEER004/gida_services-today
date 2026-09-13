import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class RequestScreen extends StatefulWidget {
  final String providerPhoto;
  final String userId;
  final String providerId;
  final String providerName;
  final String category;

  const RequestScreen({
    super.key,
    required this.providerPhoto,
    required this.userId,
    required this.providerId,
    required this.providerName,
    required this.category,
  });

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen>
    with WidgetsBindingObserver {
  static const int _platformFee = 300;

  final TextEditingController descriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = false;
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserPresence(true);
    _saveFcmToken();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _setUserPresence(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserPresence(false);
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _setUserPresence(bool value) async {
    if (mounted) setState(() => isOnline = value);

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set(
        {
          'isOnline': value,
          'lastSeen': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Presence update failed: $e');
    }
  }

  Future<String> _getCurrentUserName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) return 'Customer';
      final data = doc.data() ?? <String, dynamic>{};
      final name = data['name']?.toString().trim();
      return name == null || name.isEmpty ? 'Customer' : name;
    } catch (_) {
      return 'Customer';
    }
  }

  Future<void> _saveFcmToken() async {
    try {
      final token = await NotificationService.getToken();
      if (token == null || token.isEmpty) return;

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  String _formatLastSeen(Timestamp? timestamp) {
    if (timestamp == null) return 'Offline';

    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inSeconds < 60) return 'Active recently';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours} hr ago';
    return 'Last seen ${diff.inDays} day(s) ago';
  }

  Future<void> _logout() async {
    await _setUserPresence(false);
    NotificationService.dispose();
    await _auth.signOut();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _editProfile() async {
    final currentName = await _getCurrentUserName();
    if (!mounted) return;

    final controller = TextEditingController(text: currentName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit profile'),
              content: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;

                          setDialogState(() => saving = true);
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .set(
                              {'name': name},
                              SetOptions(merge: true),
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Could not update profile: $e')),
                              );
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save changes'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _sendRequest() async {
    final description = descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the service you need.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'userId': widget.userId,
        'providerId': widget.providerId,
        'providerName': widget.providerName,
        'category': widget.category,
        'description': description,
        'status': 'pending',
        'completed': false,
        'amount': 0,
        'serviceFee': _platformFee,
        'serviceFeePaid': false,
        'serviceFeePaidAt': null,
        'userConfirmedPaid': false,
        'providerPaid': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      descriptionController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent — the provider can now respond.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openProviderChat() async {
    try {
      final senderName = await _getCurrentUserName();
      final chatId = widget.userId.compareTo(widget.providerId) < 0
          ? '${widget.userId}_${widget.providerId}'
          : '${widget.providerId}_${widget.userId}';

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set(
        {
          'participants': [widget.userId, widget.providerId],
          'participantNames': {
            widget.userId: senderName,
            widget.providerId: widget.providerName,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            senderId: widget.userId,
            receiverId: widget.providerId,
            chatName: widget.providerName,
            senderName: senderName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: $e')),
        );
      }
    }
  }

  Future<void> _openAdminChat() async {
    const adminId = 'ADMIN_SUPPORT';

    try {
      final senderName = await _getCurrentUserName();
      final chatId = widget.userId.compareTo(adminId) < 0
          ? '${widget.userId}_$adminId'
          : '${adminId}_${widget.userId}';

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set(
        {
          'participants': [widget.userId, adminId],
          'participantNames': {
            widget.userId: senderName,
            adminId: 'GIDA SUPPORT',
          },
          'lastMessage': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            senderId: widget.userId,
            receiverId: adminId,
            chatName: 'GIDA SUPPORT',
            senderName: senderName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open support chat: $e')),
        );
      }
    }
  }

  Future<void> _confirmPaid(String requestId) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm platform fee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your service has been marked as completed. '
                'Make the platform payment, then confirm it below.',
              ),
              const SizedBox(height: 18),
              _paymentDetail('Amount', '₦$_platformFee'),
              _paymentDetail('Bank', 'Kuda Microfinance Bank'),
              _paymentDetail('Account number', '2082918233'),
              const SizedBox(height: 14),
              Text(
                'Only tap “I’ve Paid” after completing the transfer.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.verified_rounded),
              label: const Text("I've Paid"),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('requests')
                      .doc(requestId)
                      .set(
                    {
                      'serviceFee': _platformFee,
                      'serviceFeePaid': true,
                      'serviceFeePaidAt': FieldValue.serverTimestamp(),
                      'userConfirmedPaid': true,
                    },
                    SetOptions(merge: true),
                  );

                  await FirebaseFirestore.instance
                      .collection('requests')
                      .doc(requestId)
                      .collection('history')
                      .add({
                    'action':
                        'User confirmed payment of ₦$_platformFee platform service fee',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Payment confirmation recorded for ₦$_platformFee.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Could not record payment: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _paymentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final Color color;
    final IconData icon;

    switch (normalized) {
      case 'accepted':
        color = Colors.blue;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.task_alt_rounded;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = Colors.orange;
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            normalized[0].toUpperCase() + normalized.substring(1),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _providerHeader(Map<String, dynamic> data) {
    final online = data['isOnline'] == true;
    final image = (data['profileImage'] ?? widget.providerPhoto).toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(.82),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(.18),
            backgroundImage:
                image.isNotEmpty ? NetworkImage(image) : null,
            child: image.isEmpty
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.providerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(.78)),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: online ? Colors.lightGreenAccent : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        online
                            ? 'Online now'
                            : _formatLastSeen(data['lastSeen'] as Timestamp?),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(.16),
              foregroundColor: Colors.white,
            ),
            tooltip: 'Chat with provider',
            onPressed: _openProviderChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] ?? 'pending').toString();
    final description = (data['description'] ?? '').toString();
    final category = (data['category'] ?? widget.category).toString();
    final feePaid = data['serviceFeePaid'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.10),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.home_repair_service_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: _statusBadge(status),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
            ),
            if (status.toLowerCase() == 'completed') ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: feePaid
                      ? Colors.green.withOpacity(.07)
                      : Colors.orange.withOpacity(.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (feePaid ? Colors.green : Colors.orange)
                        .withOpacity(.16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      feePaid
                          ? Icons.verified_rounded
                          : Icons.account_balance_wallet_outlined,
                      color: feePaid ? Colors.green : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feePaid
                            ? 'Platform fee confirmed (₦$_platformFee)'
                            : 'Platform fee: ₦$_platformFee',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: feePaid ? Colors.green.shade800 : Colors.orange.shade900,
                        ),
                      ),
                    ),
                    if (!feePaid)
                      FilledButton(
                        onPressed: () => _confirmPaid(doc.id),
                        child: const Text('Pay fee'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'Service request',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'support') _openAdminChat();
              if (value == 'profile') _editProfile();
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'support',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.support_agent_rounded),
                  title: Text('Gida support'),
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline_rounded),
                  title: Text('Edit profile'),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Sign out'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 800 ? 28.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ${widget.providerName}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.4,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Tell the provider what you need and start a conversation.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('providers')
                            .doc(widget.providerId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final data = snapshot.hasData && snapshot.data!.exists
                              ? (snapshot.data!.data()
                                      as Map<String, dynamic>? ??
                                  <String, dynamic>{})
                              : <String, dynamic>{
                                  'isOnline': false,
                                  'lastSeen': null,
                                };
                          return _providerHeader(data);
                        },
                      ),
                      const SizedBox(height: 26),
                      _sectionHeader(
                        'What do you need?',
                        'Give enough detail for an accurate response.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        minLines: 5,
                        maxLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText:
                              'Example: I need help fixing a leaking kitchen pipe...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 14, right: 8, top: 14),
                            child: Icon(Icons.edit_note_rounded),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 52,
                            minHeight: 52,
                          ),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: loading ? null : _sendRequest,
                          icon: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(loading ? 'Sending request...' : 'Send request'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _sectionHeader(
                        'Your requests',
                        'Track conversations and completed services with this provider.',
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('requests')
                            .where('userId', isEqualTo: widget.userId)
                            .where('providerId', isEqualTo: widget.providerId)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _InfoCard(
                              icon: Icons.cloud_off_rounded,
                              title: 'Could not load requests',
                              message:
                                  'Check your connection or Firestore index configuration.',
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return _InfoCard(
                              icon: Icons.inbox_outlined,
                              title: 'No requests yet',
                              message:
                                  'Describe your service need above and your request will appear here.',
                            );
                          }

                          return Column(
                            children: docs.map(_requestCard).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(.10)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: colors.primary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}
