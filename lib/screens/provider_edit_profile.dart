import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';

class ProviderEditProfile extends StatefulWidget {
  final String providerId;

  const ProviderEditProfile({
    super.key,
    required this.providerId,
  });

  @override
  State<ProviderEditProfile> createState() => _ProviderEditProfileState();
}

class _ProviderEditProfileState extends State<ProviderEditProfile> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final serviceController = TextEditingController();

  bool loading = false;
  bool initialized = false;
  bool uploadingImage = false;
  String profileImage = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data() ?? <String, dynamic>{};

      setState(() {
        nameController.text = (data['name'] ?? '').toString();
        phoneController.text = (data['phone'] ?? '').toString();
        serviceController.text = (data['service'] ?? '').toString();
        profileImage =
            (data['profileImage'] ?? data['photoUrl'] ?? '').toString();
        initialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load profile: $e')),
      );
    }
  }

  Future<void> changeProfileImage() async {
    final choice = await showModalBottomSheet<ImageSource>(
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
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final image = choice == ImageSource.camera
        ? await ProfileImageService.pickFromCamera()
        : await ProfileImageService.pickFromGallery();

    if (image == null) return;

    setState(() => uploadingImage = true);

    try {
      final url = await ProfileImageService.updateProfileImage(
        uid: widget.providerId,
        image: image,
      );

      if (url == null || url.isEmpty) {
        throw Exception('Image upload failed.');
      }

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .set(
        {
          'profileImage': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .set(
        {
          'profileImage': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => profileImage = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  Future<void> updateProfile() async {
    if (loading) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final service = serviceController.text.trim();

    if (name.isEmpty || phone.isEmpty || service.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all profile fields.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final updates = {
        'name': name,
        'phone': phone,
        'service': service,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .set(updates, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .set(
        {
          'name': name,
          'phone': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    serviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = nameController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Provider Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ProfileAvatar(
                  imageUrl: profileImage,
                  name: name.isEmpty ? 'Provider' : name,
                  radius: 54,
                ),
                Material(
                  color: AppColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: uploadingImage ? null : changeProfileImage,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: uploadingImage
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.navy,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 19,
                              color: AppColors.navy,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Tap the camera to change your public profile photo',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 26),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name / business name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: serviceController,
            decoration: const InputDecoration(
              labelText: 'Service',
              prefixIcon: Icon(Icons.design_services_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: loading ? null : updateProfile,
              icon: loading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(loading ? 'Saving...' : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
