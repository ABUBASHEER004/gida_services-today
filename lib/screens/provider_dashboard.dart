import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

import 'chat_screen.dart';
import 'login_screen.dart';
import 'provider_edit_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'dart:async';

class ProviderDashboard extends StatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderDashboard({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard>
    with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isOnline = false;
  String address = "Loading location...";
  String profileImage = '';

  Future<void> saveFcmToken() async {
    try {
      final token = await NotificationService.getToken();
      debugPrint("FCM TOKEN: $token");

      if (token != null) {
        await _firestore.collection('providers').doc(widget.providerId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));

        debugPrint("Token saved successfully");
      }
    } catch (e) {
      debugPrint("FCM Token Error: $e");
    }
  }

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final serviceController = TextEditingController();
  Future<void> addHistory(String requestId, String action) async {
    await _firestore
        .collection('requests')
        .doc(requestId)
        .collection('history')
        .add({
      'action': action,
      'providerId': widget.providerId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    toggleStatus(true);

    loadProviderData();
    saveFcmToken();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    toggleStatus(
      state == AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _firestore.collection('providers').doc(widget.providerId).set({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    NotificationService.dispose();

    nameController.dispose();
    phoneController.dispose();
    serviceController.dispose();

    super.dispose();
  }

  Future<void> openChat(String userId) async {
    if (userId.isEmpty || widget.providerId.isEmpty) return;

    String customerName = "Customer";

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      customerName = userDoc.data()?['name'] ?? "Customer";
    }

    final chatId = userId.compareTo(widget.providerId) < 0
        ? "${userId}_${widget.providerId}"
        : "${widget.providerId}_$userId";

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [
        userId,
        widget.providerId,
      ],
      'participantNames': {
        userId: customerName,
        widget.providerId: widget.providerName,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          senderId: widget.providerId,
          receiverId: userId,
          chatName: customerName,
          senderName: widget.providerName,
        ),
      ),
    );
  }

  Widget earningsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('providerId', isEqualTo: widget.providerId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        double totalEarned = 0;
        double pendingCommission = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          totalEarned += (data['providerEarning'] ?? 0).toDouble();

          if (data['providerMarkedPaid'] != true) {
            pendingCommission += (data['commission'] ?? 0).toDouble();
          }
        }

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  "Earnings Summary",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text("Total Earned: ₦${totalEarned.toStringAsFixed(0)}"),
                Text(
                    "Pending Commission: ₦${pendingCommission.toStringAsFixed(0)}"),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // LOAD PROFILE
  // =========================
  Future<void> loadProviderData() async {
    final doc =
        await _firestore.collection('providers').doc(widget.providerId).get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    if (!mounted) return;

    setState(() {
      isOnline = data['isOnline'] == true;

      nameController.text = data['name'] ?? '';
      phoneController.text = data['phone'] ?? '';
      serviceController.text = data['service'] ?? '';
      profileImage = (data['profileImage'] ?? data['photoUrl'] ?? '').toString();

      address = data['address'] ??
          data['location']?['address'] ??
          "Location not available";
    });
  }

  // =========================
  // EDIT PROFILE
  // =========================
  Future<void> openEditProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderEditProfile(providerId: widget.providerId)));

    // Reload provider data
    await loadProviderData();

    // Save latest FCM token
    final token = await NotificationService.getToken();

    await _firestore.collection('providers').doc(widget.providerId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  // =========================
  // ONLINE/OFFLINE
  // =========================
  Future<void> toggleStatus(bool value) async {
    if (mounted) {
      setState(() => isOnline = value);
    }

    await _firestore.collection('providers').doc(widget.providerId).set({
      'isOnline': value,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =========================
// ADMIN CHAT (FULL HISTORY FIXED)
// =========================
  void openAdminChat() async {
    final providerId = widget.providerId;

    if (providerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid provider ID")),
      );
      return;
    }

    final chatId = "ADMIN_SUPPORT_$providerId";

    await _firestore.collection('chats').doc(chatId).set({
      'participants': [
        "ADMIN_SUPPORT",
        widget.providerId,
      ],
      'participantNames': {
        "ADMIN_SUPPORT": "ADMIN SUPPORT",
        widget.providerId: widget.providerName,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          senderId: providerId,
          receiverId: "ADMIN_SUPPORT",
          chatName: "ADMIN SUPPORT",
          senderName: widget.providerName,
        ),
      ),
    );
  }

  // =========================
  // CHAT WITH USER
  // ======================
  Future<void> acceptRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).set({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addHistory(requestId, "Request accepted");
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).set({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addHistory(requestId, "Request rejected");
  }

  // =========================
  // COMPLETE JOB
  // =========================
  Future<void> markAsDone(String id, double amount) async {
    const commissionRate = 0.05;

    final commission = amount * commissionRate;
    final providerEarning = amount - commission;

    await _firestore.collection('requests').doc(id).set({
      'status': 'completed',
      'completed': true,
      'amount': amount,
      'commission': commission,
      'providerEarning': providerEarning,
      'commissionPaid': false,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await addHistory(
      id,
      "Job completed. Earned ₦${providerEarning.toStringAsFixed(0)}, Commission ₦${commission.toStringAsFixed(0)}",
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Earned ₦${providerEarning.toStringAsFixed(0)}"),
      ),
    );
  }

  void showCompleteJobDialog(String requestId) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete Job"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              Navigator.pop(context);
              await markAsDone(requestId, amount);
            },
            child: const Text("Complete"),
          ),
        ],
      ),
    );
  }

  // =========================
  // MARK COMMISSION PAID
  // =========================
  Future<void> markCommissionPaid(String requestId) async {
    final ref = _firestore.collection('requests').doc(requestId);

    await ref.set({
      'providerMarkedPaid': true,
      'providerPaidAt': FieldValue.serverTimestamp(),
      'providerPaymentStatus': 'paid_pending_admin_review',
    }, SetOptions(merge: true));

    await addHistory(requestId, "Commission marked as PAID by provider");

    final chatId = "ADMIN_SUPPORT_${widget.providerId}";
    await _firestore.collection("chats").doc(chatId).set({
      "participants": [
        "ADMIN_SUPPORT",
        widget.providerId,
      ],
      "participantNames": {
        "ADMIN_SUPPORT": "ADMIN SUPPORT",
        widget.providerId: widget.providerName,
      },
      "lastMessage": "Commission marked as paid",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "senderId": widget.providerId,
      "message": "I have paid commission for request $requestId",
      "timestamp": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment sent to admin")),
    );
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _firestore.collection('providers').doc(widget.providerId).set({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }


  Widget _earningsPanel() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('requests')
          .where('providerId', isEqualTo: widget.providerId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        double earned = 0;
        double pending = 0;

        for (final doc in snapshot.data?.docs ?? const []) {
          final data = doc.data();
          earned += _money(data['providerEarning']);
          if (data['providerMarkedPaid'] != true) {
            pending += _money(data['commission']);
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Earnings overview',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₦${earned.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _earningChip(
                    'Completed earnings',
                    '₦${earned.toStringAsFixed(0)}',
                  ),
                  _earningChip(
                    'Pending commission',
                    '₦${pending.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _earningChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              )),
        ],
      ),
    );
  }

  double _money(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _providerHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: profileImage,
            name: widget.providerName,
            radius: 28,
            showOnline: true,
            isOnline: isOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${widget.providerName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage your requests and grow your service business.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isOnline,
            onChanged: toggleStatus,
          ),
        ],
      ),
    );
  }

  Widget _commissionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commission payment',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Kuda Microfinance Bank',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 3),
                SelectableText(
                  '2082918233',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Pay commission after completing a job, then mark it as paid.",
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final id = doc.id;
    final userId = (data['userId'] ?? '').toString();
    final status = (data['status'] ?? 'pending').toString();
    final category = (data['category'] ?? 'Service request').toString();
    final description = (data['description'] ?? '').toString();
    final amount = _money(data['amount']);
    final paid = data['providerMarkedPaid'] == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    category,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusPill(status),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₦${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: userId.isEmpty ? null : () => openChat(userId),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                  label: const Text('Chat'),
                ),
                if (status == 'pending')
                  ElevatedButton.icon(
                    onPressed: () => acceptRequest(id),
                    icon: const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Accept'),
                  ),
                if (status == 'pending')
                  OutlinedButton.icon(
                    onPressed: () => rejectRequest(id),
                    icon: const Icon(Icons.close_rounded, size: 17),
                    label: const Text('Reject'),
                  ),
                if (status == 'accepted')
                  ElevatedButton.icon(
                    onPressed: () => showCompleteJobDialog(id),
                    icon: const Icon(Icons.task_alt_rounded, size: 17),
                    label: const Text('Mark done'),
                  ),
                if (status == 'completed' && !paid)
                  ElevatedButton.icon(
                    onPressed: () => markCommissionPaid(id),
                    icon: const Icon(Icons.verified_rounded, size: 17),
                    label: const Text('I have paid'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = statusColor(status);
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyRequests() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No requests yet',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'New customer requests will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'chat':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Open a customer chat from a request below.',
                      ),
                    ),
                  );
                  break;
                case 'support':
                  openAdminChat();
                  break;
                case 'edit':
                  openEditProfile();
                  break;
                case 'logout':
                  logout();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'chat',
                child: Text('Customer chats'),
              ),
              PopupMenuItem(
                value: 'support',
                child: Text('Admin support'),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit profile'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Sign out'),
              ),
            ],
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _providerHeader(),
          const SizedBox(height: 14),
          _earningsPanel(),
          const SizedBox(height: 14),
          _commissionCard(),
          const SizedBox(height: 22),
          const Text(
            'Customer requests',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('requests')
                .where('providerId', isEqualTo: widget.providerId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Unable to load requests. Check your connection or Firestore index.',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return _emptyRequests();

              return Column(
                children: docs
                    .map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _requestCard(context, doc),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
