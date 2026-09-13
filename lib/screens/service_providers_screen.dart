
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'request_screen.dart';

class ServiceProvidersScreen extends StatelessWidget {
  final String category;

  const ServiceProvidersScreen({
    super.key,
    required this.category,
  });

  String normalize(String value) {
    return value.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String selectedCategory = normalize(category);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _state(
              'Unable to load providers',
              Icons.cloud_off_rounded,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return _state(
              'No provider data available',
              Icons.people_outline_rounded,
            );
          }

          final providers = snapshot.data!.docs.where((doc) {
            final Map<String, dynamic> data = doc.data();

            final String service =
                (data['service'] ?? '').toString();

            return normalize(service) == selectedCategory;
          }).toList();

          if (providers.isEmpty) {
            return _empty();
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              32,
            ),
            itemCount: providers.length + 1,
            separatorBuilder: (_, index) {
              return SizedBox(
                height: index == 0 ? 14 : 10,
              );
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return _categoryBanner();
              }

              final doc = providers[index - 1];
              final Map<String, dynamic> data = doc.data();

              final bool online = data['isOnline'] == true;

              final String location =
                  (data['location'] ?? '').toString().trim();

              final String photo =
                  (data['profileImage'] ??
                          data['photoUrl'] ??
                          '')
                      .toString()
                      .trim();

              final String name =
                  (data['name'] ?? 'Service Provider')
                      .toString()
                      .trim();

              final String service =
                  (data['service'] ?? category)
                      .toString()
                      .trim();

              return _providerCard(
                context,
                user: user,
                providerId: doc.id,
                providerName: name,
                providerPhoto: photo,
                service: service,
                location: location,
                online: online,
              );
            },
          );
        },
      ),
    );
  }

  Widget _categoryBanner() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Showing providers offering $category. '
              'Check availability before sending a request.',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerCard(
    BuildContext context, {
    required User? user,
    required String providerId,
    required String providerName,
    required String providerPhoto,
    required String service,
    required String location,
    required bool online,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: AppColors.border.withOpacity(0.9),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please log in to continue.',
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RequestScreen(
                  providerPhoto: providerPhoto,
                  userId: user.uid,
                  providerId: providerId,
                  providerName: providerName,
                  category: service,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // FIX:
                // name is now passed because _providerAvatar()
                // requires photo, name and online.
                _providerAvatar(
                  photo: providerPhoto,
                  name: providerName,
                  online: online,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: online
                                  ? AppColors.accent
                                  : AppColors.muted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              online
                                  ? 'Available now'
                                  : 'Currently offline',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: online
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(width: 9),
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _providerAvatar({
    required String photo,
    required String name,
    required bool online,
  }) {
    return ProfileAvatar(
      imageUrl: photo,
      name: name,
      radius: 31,
      showOnline: true,
      isOnline: online,
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No providers yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no providers listed '
              'for $category.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _state(
    String message,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: AppColors.muted,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

