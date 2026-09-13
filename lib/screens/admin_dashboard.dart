import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'admin_chat_viewer_screen.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int currentTab = 0;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    saveAdminToken();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      NotificationService.showNotification(
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? '',
      );
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> saveAdminToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    await _firestore.collection('admins').doc(user.uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> activateUser(String id) async {
    await _firestore.collection('users').doc(id).set({
      'status': 'active',
      'blocked': false,
    }, SetOptions(merge: true));
  }

  Future<void> deactivateUser(String id) async {
    await _firestore.collection('users').doc(id).set(
      {'status': 'inactive'},
      SetOptions(merge: true),
    );
  }

  Future<void> blockUser(String id) async {
    await _firestore.collection('users').doc(id).set({
      'status': 'blocked',
      'blocked': true,
    }, SetOptions(merge: true));
  }

  Future<void> deleteUser(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  Future<void> activateProvider(String id) async {
    await _firestore.collection('providers').doc(id).set({
      'status': 'active',
      'isSuspended': false,
    }, SetOptions(merge: true));
  }

  Future<void> deactivateProvider(String id) async {
    await _firestore.collection('providers').doc(id).set(
      {'status': 'inactive'},
      SetOptions(merge: true),
    );
  }

  Future<void> blockProvider(String id) async {
    await _firestore.collection('providers').doc(id).set({
      'status': 'blocked',
      'isSuspended': true,
    }, SetOptions(merge: true));
  }

  Future<void> deleteProvider(String id) async {
    await _firestore.collection('providers').doc(id).delete();
  }

  double toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> confirmPayment(String id) async {
    await _firestore.collection('requests').doc(id).set({
      'commissionPaid': true,
      'commissionPaidAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('requests').doc(id).collection('history').add({
      'action': 'Admin confirmed payment',
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment confirmed')),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('requests').snapshots(),
      builder: (context, reqSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, userSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('providers').snapshots(),
              builder: (context, providerSnap) {
                if (!reqSnap.hasData ||
                    !userSnap.hasData ||
                    !providerSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = reqSnap.data!.docs;
                final users = userSnap.data!.docs;
                final providers = providerSnap.data!.docs;
                final online = providers
                    .where((d) => d.data()['isOnline'] == true)
                    .length;
                final pending = requests
                    .where((d) => d.data()['status'] == 'pending')
                    .length;
                final completed = requests
                    .where((d) => d.data()['status'] == 'completed')
                    .length;

                double revenue = 0;
                for (final request in requests) {
                  revenue += toDouble(request.data()['commission']);
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1100
                        ? 4
                        : constraints.maxWidth >= 650
                            ? 2
                            : 1;

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      children: [
                        _welcomeHeader(
                          'Admin overview',
                          'Monitor Gida Services from one place.',
                          Icons.admin_panel_settings_rounded,
                        ),
                        const SizedBox(height: 18),
                        GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: columns == 1 ? 3.0 : 1.55,
                          children: [
                            _statCard(
                              title: 'Total users',
                              value: '${users.length}',
                              icon: Icons.people_alt_rounded,
                              color: Colors.blue,
                            ),
                            _statCard(
                              title: 'Providers',
                              value: '${providers.length}',
                              icon: Icons.storefront_rounded,
                              color: AppColors.primary,
                            ),
                            _statCard(
                              title: 'Online now',
                              value: '$online',
                              icon: Icons.circle,
                              color: AppColors.accent,
                            ),
                            _statCard(
                              title: 'Requests',
                              value: '${requests.length}',
                              icon: Icons.assignment_rounded,
                              color: Colors.orange,
                            ),
                            _statCard(
                              title: 'Pending',
                              value: '$pending',
                              icon: Icons.pending_actions_rounded,
                              color: AppColors.warning,
                            ),
                            _statCard(
                              title: 'Completed',
                              value: '$completed',
                              icon: Icons.task_alt_rounded,
                              color: Colors.teal,
                            ),
                            _statCard(
                              title: 'Commission',
                              value: '₦${revenue.toStringAsFixed(0)}',
                              icon: Icons.payments_rounded,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _sectionLabel('Quick management'),
                        const SizedBox(height: 10),
                        _quickActions(),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _welcomeHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ));
  }

  Widget _quickActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _quickAction('Users', Icons.people_alt_rounded, 1),
        _quickAction('Providers', Icons.storefront_rounded, 2),
        _quickAction('Requests', Icons.assignment_rounded, 3),
        _quickAction('Support', Icons.support_agent_rounded, 4),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, int tab) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      onPressed: () => setState(() => currentTab = tab),
    );
  }

  Widget usersTab() {
    return _collectionList(
      collection: 'users',
      emptyIcon: Icons.people_outline_rounded,
      emptyTitle: 'No users yet',
      builder: (doc, data) {
        final name = (data['name'] ?? 'No Name').toString();
        final email = (data['email'] ?? 'No email').toString();
        final status = (data['status'] ?? 'active').toString();
        final blocked = data['blocked'] == true;

        return _managementCard(
          avatarIcon: Icons.person_rounded,
          imageUrl: (data['profileImage'] ?? data['photoUrl'] ?? '').toString(),
          title: name,
          subtitle: email,
          status: status,
          active: !blocked,
          actions: [
            _miniAction(
              'Activate',
              Icons.check_circle_outline,
              () => activateUser(doc.id),
            ),
            _miniAction(
              blocked ? 'Unblock' : 'Block',
              blocked ? Icons.lock_open_rounded : Icons.block_rounded,
              () => blocked
                  ? activateUser(doc.id)
                  : blockUser(doc.id),
            ),
            _miniAction(
              'Delete',
              Icons.delete_outline_rounded,
              () => _confirmDelete(
                'Delete user?',
                'This will permanently remove the user profile.',
                () => deleteUser(doc.id),
              ),
              danger: true,
            ),
          ],
        );
      },
    );
  }

  Widget providersTab() {
    return _collectionList(
      collection: 'providers',
      emptyIcon: Icons.storefront_outlined,
      emptyTitle: 'No providers yet',
      builder: (doc, data) {
        final name = (data['name'] ?? 'No Name').toString();
        final service = (data['service'] ?? 'No service').toString();
        final status = (data['status'] ?? 'active').toString();
        final online = data['isOnline'] == true;
        final suspended = data['isSuspended'] == true;

        return _managementCard(
          avatarIcon: Icons.storefront_rounded,
          imageUrl: (data['profileImage'] ?? data['photoUrl'] ?? '').toString(),
          title: name,
          subtitle: service,
          status: online ? 'Online' : status,
          active: !suspended,
          actions: [
            _miniAction(
              'Activate',
              Icons.check_circle_outline,
              () => activateProvider(doc.id),
            ),
            _miniAction(
              suspended ? 'Unblock' : 'Block',
              suspended
                  ? Icons.lock_open_rounded
                  : Icons.block_rounded,
              () => suspended
                  ? activateProvider(doc.id)
                  : blockProvider(doc.id),
            ),
            _miniAction(
              'Delete',
              Icons.delete_outline_rounded,
              () => _confirmDelete(
                'Delete provider?',
                'This will permanently remove the provider profile.',
                () => deleteProvider(doc.id),
              ),
              danger: true,
            ),
          ],
        );
      },
    );
  }

  Widget _collectionList({
    required String collection,
    required IconData emptyIcon,
    required String emptyTitle,
    required Widget Function(
      QueryDocumentSnapshot<Map<String, dynamic>>,
      Map<String, dynamic>,
    ) builder,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(Icons.cloud_off_rounded, 'Unable to load $collection');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _emptyState(emptyIcon, emptyTitle);

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) => builder(docs[index], docs[index].data()),
        );
      },
    );
  }

  Widget _managementCard({
    required IconData avatarIcon,
    String? imageUrl,
    required String title,
    required String subtitle,
    required String status,
    required bool active,
    required List<Widget> actions,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfileAvatar(
                  imageUrl: imageUrl,
                  name: title,
                  radius: 23,
                  showOnline: status.toLowerCase() == 'online',
                  isOnline: status.toLowerCase() == 'online',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _statusPill(status, active),
              ],
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniAction(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? AppColors.danger : AppColors.primary,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        side: BorderSide(
          color: danger ? AppColors.danger : AppColors.border,
        ),
      ),
    );
  }

  Widget _statusPill(String text, bool active) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? AppColors.primary : AppColors.danger,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget requestsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(
            Icons.cloud_off_rounded,
            'Unable to load requests',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(
            Icons.assignment_outlined,
            'No requests yet',
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final id = doc.id;
            final amount = toDouble(data['amount']);
            final commission = toDouble(data['commission']);
            final earning = toDouble(data['providerEarning']);
            final paid = data['commissionPaid'] == true;
            final status = (data['status'] ?? 'pending').toString();
            final category = (data['category'] ?? 'Service request').toString();
            final description = (data['description'] ?? '').toString();
            final userId = (data['userId'] ?? '').toString();
            final providerId = (data['providerId'] ?? '').toString();

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
                        const SizedBox(width: 10),
                        _statusPill(status.toUpperCase(), status != 'rejected'),
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
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _amountChip('Amount', amount),
                        _amountChip('Commission', commission),
                        _amountChip('Provider earns', earning),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: paid ? null : () => confirmPayment(id),
                          icon: const Icon(Icons.verified_rounded, size: 17),
                          label: Text(paid ? 'Payment confirmed' : 'Confirm payment'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminChatViewerScreen(
                                  requestId: id,
                                  userId: userId,
                                  providerId: providerId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                          label: const Text('View chat'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _history(id),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _amountChip(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        '$label: ₦${amount.toStringAsFixed(0)}',
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _history(String id) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('requests')
          .doc(id)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text(
            'No history yet',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          );
        }
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            'Activity history',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, size: 19),
              title: Text(
                (data['action'] ?? '').toString(),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget supportChatsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('chats').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyState(Icons.cloud_off_rounded, 'Unable to load support chats');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data!.docs.where((doc) {
          final participants = List<String>.from(
            doc.data()['participants'] ?? const [],
          );
          return participants.contains('ADMIN_SUPPORT');
        }).toList();

        if (chats.isEmpty) {
          return _emptyState(
            Icons.support_agent_rounded,
            'No support chats yet',
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = chats[index];
            final data = doc.data();
            final participants = List<String>.from(
              data['participants'] ?? const [],
            );
            final other = participants.firstWhere(
              (id) => id != 'ADMIN_SUPPORT',
              orElse: () => 'Unknown',
            );
            final type = (data['type'] ?? '').toString();

            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 7,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  type == 'provider_admin'
                      ? 'Provider Support'
                      : 'User Support',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  (data['lastMessage'] ?? 'No messages').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminChatViewerScreen(
                        requestId: '',
                        userId: other,
                        providerId: '',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    String title,
    String message,
    Future<void> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await action();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboardTab(),
      usersTab(),
      providersTab(),
      requestsTab(),
      supportChatsTab(),
    ];

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Overview',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline_rounded),
        selectedIcon: Icon(Icons.people_rounded),
        label: 'Users',
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: 'Providers',
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment_rounded),
        label: 'Requests',
      ),
      NavigationDestination(
        icon: Icon(Icons.support_agent_outlined),
        selectedIcon: Icon(Icons.support_agent_rounded),
        label: 'Support',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Admin menu',
            onSelected: (value) {
              if (value == 'logout') logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 10),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentTab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) {
          setState(() => currentTab = index);
        },
        destinations: destinations,
      ),
    );
  }
}
