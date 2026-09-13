import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showOnline;
  final bool isOnline;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 28,
    this.showOnline = false,
    this.isOnline = false,
  });

  String get _initial {
    final value = name.trim();
    return value.isEmpty ? 'G' : value[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8F7EF),
      backgroundImage:
          url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
      child: url.isEmpty
          ? Text(
              _initial,
              style: TextStyle(
                color: const Color(0xFF087A45),
                fontSize: radius * .72,
                fontWeight: FontWeight.w900,
              ),
            )
          : null,
    );

    if (!showOnline) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          bottom: 1,
          child: Container(
            width: radius * .48,
            height: radius * .48,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
            ),
          ),
        ),
      ],
    );
  }
}
