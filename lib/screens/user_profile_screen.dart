import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/profile_image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _uploadingImage = false;

  Future<void> _changeProfileImage(String uid) async {
    final source = await showModalBottomSheet<ImageSourceChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Change profile photo',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(
                context,
                ImageSourceChoice.gallery,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(
                context,
                ImageSourceChoice.camera,
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = source == ImageSourceChoice.camera
        ? await ProfileImageService.pickFromCamera()
        : await ProfileImageService.pickFromGallery();

    if (image == null) return;

    setState(() => _uploadingImage = true);

    try {
      final url = await ProfileImageService.updateProfileImage(
        uid: uid,
        image: image,
      );

      if (url == null || url.isEmpty) {
        throw Exception('The image could not be uploaded.');
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'profileImage': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Providers are also represented in users, so this keeps the
      // same profile image available everywhere the account is displayed.
      final provider = await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .get();

      if (provider.exists) {
        await provider.reference.set(
          {
            'profileImage': url,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final name = (data['name'] ?? 'Gida User').toString();
          final email = (data['email'] ?? user.email ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          final location = (data['location'] ?? '').toString();
          final imageUrl = (data['profileImage'] ?? data['photoUrl'] ?? '')
              .toString();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ProfileAvatar(
                          imageUrl: imageUrl,
                          name: name,
                          radius: 43,
                        ),
                        Material(
                          color: AppColors.accent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _uploadingImage
                                ? null
                                : () => _changeProfileImage(user.uid),
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: _uploadingImage
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.navy,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: AppColors.navy,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _uploadingImage
                          ? null
                          : () => _changeProfileImage(user.uid),
                      icon: const Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Change profile photo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Account',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 11),
              if (phone.isNotEmpty)
                _tile(Icons.phone_outlined, 'Phone', phone),
              if (location.isNotEmpty)
                _tile(Icons.location_on_outlined, 'Location', location),
              _tile(
                Icons.verified_user_outlined,
                'Account & security',
                'Manage your signed-in account',
              ),
              _tile(
                Icons.help_outline_rounded,
                'Help & support',
                'Get assistance with Gida Services',
              ),
              _tile(
                Icons.description_outlined,
                'Terms & policies',
                'Review platform terms and policies',
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

enum ImageSourceChoice { gallery, camera }
