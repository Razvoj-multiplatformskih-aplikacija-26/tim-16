
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/app_bottom_navigation.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,

      appBar: AppBar(
        title: const Text(
          'Moj profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        centerTitle: false,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartica korisnika
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: primaryColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.person_outline,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Marko Petrović',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Kupac na Svežku',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 17,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Član Svežko zajednice',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Osnovni podaci
            Text(
              'Osnovni podaci',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _ProfileInfoTile(
                    icon: Icons.person_outline,
                    title: 'Ime i prezime',
                    value: 'Marko Petrović',
                  ),
                  const Divider(height: 1, indent: 48),
                  _ProfileInfoTile(
                    icon: Icons.email_outlined,
                    title: 'Email adresa',
                    value: 'marko@email.com',
                  ),
                  const Divider(height: 1, indent: 48),
                  _ProfileInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Broj telefona',
                    value: '+381 60 123 4567',
                  ),
                  const Divider(height: 1, indent: 48),
                  _ProfileInfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Adresa',
                    value: 'Novi Sad, Srbija',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Podešavanja
            Text(
              'Podešavanja naloga',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _ProfileActionTile(
                    icon: Icons.edit_outlined,
                    title: 'Izmeni profil',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Izmena profila biće dostupna uskoro.',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _ProfileActionTile(
                    icon: Icons.location_on_outlined,
                    title: 'Adrese za dostavu',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Adrese za dostavu biće dostupne uskoro.',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _ProfileActionTile(
                    icon: Icons.lock_outline,
                    title: 'Promena lozinke',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Promena lozinke biće dostupna uskoro.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Odjava
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funkcionalnost odjave biće dodata kasnije.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Odjavi se'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),

      bottomNavigationBar: AppBottomNavigation(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
          // Ostale ekrane povezujemo kada budu napravljeni.
        },
      ),
    );
  }
}

// Widget za prikaz jednog podatka
class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(
            icon,
            size: 23,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget za stavke podešavanja
class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
