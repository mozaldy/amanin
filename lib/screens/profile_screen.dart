// lib/screens/profile_screen.dart

import 'package:amanin/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20.0),
          CircleAvatar(
            radius: 60.0,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              user?.fullName.isNotEmpty == true
                  ? user!.fullName.substring(0, 1).toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            user?.email ?? '',
            style: const TextStyle(fontSize: 16.0, color: Colors.grey),
          ),
          const SizedBox(height: 8.0),
          if (user?.isAdmin == true)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 30.0),
          const Divider(),
          const SizedBox(height: 10.0),
          _buildProfileItem(Icons.email, 'Email', user?.email ?? 'N/A'),
          _buildProfileItem(
            Icons.person,
            'Account Type',
            user?.isAdmin == true ? 'Administrator' : 'Regular User',
          ),
          _buildProfileItem(Icons.security, 'Account Status', 'Active'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: const [
                Text(
                  'App Information',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text('Amanin v1.0.0', style: TextStyle(fontSize: 16.0)),
                SizedBox(height: 4.0),
                Text(
                  'Amanin surabaya kita dengan aplikasi Amanin.',
                  style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14.0, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontSize: 16.0)),
            ],
          ),
        ],
      ),
    );
  }
}
