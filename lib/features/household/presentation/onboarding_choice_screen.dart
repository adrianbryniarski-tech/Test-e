import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nasz_budzet_domowy/features/auth/application/auth_providers.dart';

/// Pierwszy ekran po logowaniu (gdy user nie należy do żadnego gospodarstwa).
///
/// Daje wybór: utwórz nowe gospodarstwo (jest pierwszą osobą w rodzinie)
/// lub dołącz do istniejącego (partner/ka już ma kod).
class OnboardingChoiceScreen extends ConsumerWidget {
  const OnboardingChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Wyloguj',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user?.email != null)
                Text(
                  'Zalogowany jako ${user!.email}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Skonfigurujmy Twój budżet',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Budżet jest wspólny dla dwóch osób. '
                'Wybierz jak chcesz zacząć:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              _ChoiceCard(
                icon: Icons.add_home_outlined,
                title: 'Stwórz nowe gospodarstwo',
                subtitle:
                    'Jesteś pierwszą osobą. Dostaniesz kod do podzielenia '
                    'się z partnerem/ką.',
                onTap: () => context.push('/onboarding/create'),
              ),
              const SizedBox(height: 16),
              _ChoiceCard(
                icon: Icons.key_outlined,
                title: 'Mam kod zaproszenia',
                subtitle: 'Partner/ka wysłał Ci kod (np. ABC-XYZ) — wpisz go, '
                    'żeby się dołączyć.',
                onTap: () => context.push('/onboarding/join'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
