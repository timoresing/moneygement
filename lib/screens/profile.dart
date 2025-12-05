import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Ini Profile',
        style: TextStyle(
          color: Colors.black,
          fontSize: 30,
        ),
      ),
    );
  }
}
