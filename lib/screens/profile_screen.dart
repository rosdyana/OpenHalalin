import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:halalapp/services/auth_service.dart';
import 'package:halalapp/providers/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? l10n.profile,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings List
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(l10n.notifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Handle notifications settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  languageProvider.getCurrentLanguageName(),
                  style: const TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showLanguageDialog(context, languageProvider),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text(l10n.darkMode),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Handle dark mode settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: Text(l10n.helpSupport),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Handle help & support
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Handle privacy policy
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              l10n.logout,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) async {
    final l10n = AppLocalizations.of(context);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: LanguageProvider.supportedLanguages.entries.map((entry) {
                return ListTile(
                  title: Text(LanguageProvider.nativeLanguageNames[entry.key]!),
                  trailing: languageProvider.currentLocale.languageCode == entry.key
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () async {
                    await languageProvider.setLocale(entry.key);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.languageChanged)),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.logout),
          content: Text(l10n.logoutConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(l10n.confirm),
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService().signOut();
              },
            ),
          ],
        );
      },
    );
  }
}
