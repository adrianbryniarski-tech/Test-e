import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nasz_budzet_domowy/app/theme.dart';
import 'package:nasz_budzet_domowy/features/animations/application/animation_settings.dart';
import 'package:nasz_budzet_domowy/features/auth/application/auth_providers.dart';
import 'package:nasz_budzet_domowy/features/household/application/household_providers.dart';
import 'package:nasz_budzet_domowy/features/settings/application/theme_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeVariantProvider);
    final mode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Text(
            'Motyw',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wybierz styl który najbardziej Wam pasuje.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemCount: AppThemeVariant.values.length,
            itemBuilder: (context, index) {
              final v = AppThemeVariant.values[index];
              return _ThemePreviewCard(
                variant: v,
                isSelected: v == variant,
                onTap: () => ref.read(themeVariantProvider.notifier).set(v),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Tryb jasny / ciemny',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Jasny'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Ciemny'),
                icon: Icon(Icons.dark_mode),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: 32),
          Text(
            'Gospodarstwo',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Wszyscy członkowie tego gospodarstwa widzą te same transakcje. '
            'Jeśli Twojej żony/męża nie ma na liście — to znaczy że nie '
            'dołączyła/dołączył do tego samego gospodarstwa.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          const _HouseholdInfoCard(),
          const SizedBox(height: 32),
          Text(
            'Animacje',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Każdą można wyłączyć osobno gdy ktoś woli czysty interfejs.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...AppAnimation.values.map(
            (a) => _AnimationTile(animation: a),
          ),
          const SizedBox(height: 32),
          Text(
            'Info',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aplikacja: Nasz budżet domowy\n'
                'Dla rodziny Bryniarskich (Adrian + Andzia + córeczka)\n'
                'Wszystko AB.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kafelek z miniaturką motywu — pokazuje paletę kolorów + nazwę.
/// Stuknięcie ustawia ten motyw.
class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeVariant variant;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Budujemy "miniaturkę" używając tego samego buildera co prawdziwy
    // motyw — dla light brightness (preview ma być czytelny niezależnie
    // od aktualnego trybu apki).
    final preview = AppTheme.light(variant);
    final scheme = preview.colorScheme;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: preview.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3 kolorowe kółka pokazujące paletę
            Row(
              children: [
                _Dot(color: scheme.primary),
                const SizedBox(width: 6),
                _Dot(color: scheme.secondary),
                const SizedBox(width: 6),
                _Dot(color: scheme.tertiary),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // "Mini surface" — pokazuje jak wygląda Card
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              variant.label,
              style: preview.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              variant.description,
              style: preview.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HouseholdInfoCard extends ConsumerWidget {
  const _HouseholdInfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final householdAsync = ref.watch(currentHouseholdIdProvider);
    final currentUser = ref.watch(currentUserProvider);

    return householdAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Błąd: $e',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
      data: (householdId) {
        if (householdId == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nie należysz do żadnego gospodarstwa.'),
            ),
          );
        }
        final infoAsync = ref.watch(householdInfoProvider(householdId));
        final membersAsync = ref.watch(householdMembersProvider(householdId));
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kvRow(
                  context,
                  label: 'Nazwa',
                  value: infoAsync.value?.name ?? '—',
                ),
                const SizedBox(height: 8),
                _kvRow(
                  context,
                  label: 'ID gospodarstwa',
                  value: householdId,
                  copyable: true,
                ),
                const SizedBox(height: 8),
                _kvRow(
                  context,
                  label: 'Twój user ID',
                  value: currentUser?.id ?? '—',
                  copyable: true,
                ),
                const SizedBox(height: 8),
                _kvRow(
                  context,
                  label: 'Twój email',
                  value: currentUser?.email ?? '—',
                ),
                const Divider(height: 32),
                Text(
                  'Członkowie',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                membersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => Text(
                    'Nie udało się pobrać listy: $e',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  data: (members) {
                    if (members.isEmpty) {
                      return const Text('Brak członków (?)');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in members)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  m.isOwner
                                      ? Icons.star
                                      : Icons.person_outline,
                                  size: 18,
                                  color: m.isOwner
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    m.userId,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                Text(
                                  m.isOwner ? 'owner' : 'member',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            members.length == 1
                                ? 'Tylko Ty jesteś w tym gospodarstwie. '
                                    'Żona musi się dołączyć przez kod '
                                    'zaproszenia (zakładka Transakcje → 👤+).'
                                : 'W gospodarstwie ${members.length} '
                                    'członków — transakcje są wspólne.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kvRow(
    BuildContext context, {
    required String label,
    required String value,
    bool copyable = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: copyable ? 'monospace' : null,
            ),
          ),
        ),
        if (copyable)
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            padding: EdgeInsets.zero,
            tooltip: 'Kopiuj',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
            },
          ),
      ],
    );
  }
}

class _AnimationTile extends ConsumerWidget {
  const _AnimationTile({required this.animation});
  final AppAnimation animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(animationSettingsProvider);
    final enabled = settings.isOn(animation);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        value: enabled,
        onChanged: (v) => ref
            .read(animationSettingsProvider.notifier)
            .set(animation, enabled: v),
        title: Text(animation.label),
        subtitle: Text(animation.description),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
