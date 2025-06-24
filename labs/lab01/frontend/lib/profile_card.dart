import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final int age;
  final String? avatarUrl;

  const ProfileCard({
    Key? key,
    required this.name,
    required this.email,
    required this.age,
    this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final avatar = avatarUrl != null
        ? CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(avatarUrl!),
          )
        : CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              name.isNotEmpty ? name[0] : '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 400;

              return isWide
                  ? Row(
                      children: _buildProfileContent(isWide, avatar),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _buildProfileContent(isWide, avatar),
                    );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProfileContent(bool isWide, Widget avatar) {
    return [
      avatar,
      SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 16),
      Expanded(
        child: Column(
          crossAxisAlignment:
              isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Age: $age',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    ];
  }
}
