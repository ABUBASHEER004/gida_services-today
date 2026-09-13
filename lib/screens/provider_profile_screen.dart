import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'login_screen.dart';
import 'provider_edit_profile.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load profile'));
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final name = (data['name'] ?? 'Service Provider').toString();
          final service = (data['service'] ?? 'Service provider').toString();
          final phone = (data['phone'] ?? 'Not provided').toString();
          final address =
              (data['address'] ?? data['location'] ?? 'Not provided')
                  .toString();
          final imageUrl =
              (data['profileImage'] ?? data['photoUrl'] ?? '').toString();
          final online = data['isOnline'] == true;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    ProfileAvatar(
                      imageUrl: imageUrl,
                      name: name,
                      radius: 46,
                      showOnline: true,
                      isOnline: online,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      service,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        online ? '● Online now' : '● Offline',
                        style: TextStyle(
                          color: online
                              ? const Color(0xFFB8F2D1)
                              : Colors.white70,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _info(Icons.phone_outlined, 'Phone number', phone),
              _info(Icons.design_services_outlined, 'Service', service),
              _info(Icons.location_on_outlined, 'Location', address),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProviderEditProfile(providerId: user.uid),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit profile'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
