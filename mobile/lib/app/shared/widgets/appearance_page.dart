import 'package:flutter/material.dart';

import '../branding/branding_config.dart';
import '../branding/branding_scope.dart';
import '../services/app_logger.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  var _isReloading = false;

  Future<void> _reloadBranding() async {
    AppLogger.info('screen.appearance.reload_branding_tapped');
    setState(() => _isReloading = true);
    try {
      await BrandingScope.controlsOf(context).reloadBranding();
    } finally {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = BrandingScope.controlsOf(context);
    final branding = scope.config;

    return Scaffold(
      appBar: AppBar(title: const Text('Aparência')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.settings_suggest_outlined),
                label: Text('Sistema'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Escuro'),
              ),
            ],
            selected: {scope.themeMode},
            onSelectionChanged: (selection) {
              final themeMode = selection.first;
              AppLogger.info('screen.appearance.theme_mode_selected',
                  context: {'themeMode': themeMode.name});
              scope.onThemeModeChanged(themeMode);
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cores do backend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _isReloading ? null : _reloadBranding,
                icon: _isReloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Atualizar cores',
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PalettePanel(title: 'Claro', palette: branding.light),
          const SizedBox(height: 12),
          _PalettePanel(title: 'Escuro', palette: branding.dark),
        ],
      ),
    );
  }
}

class _PalettePanel extends StatelessWidget {
  const _PalettePanel({
    required this.title,
    required this.palette,
  });

  final String title;
  final BrandingPalette palette;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ColorChip(label: 'Principal', color: palette.primary),
                _ColorChip(label: 'Secundária', color: palette.secondary),
                _ColorChip(label: 'Destaque', color: palette.accent),
                _ColorChip(label: 'Fundo', color: palette.background),
                _ColorChip(label: 'Superfície', color: palette.surface),
                _ColorChip(label: 'Borda', color: palette.border),
                _ColorChip(label: 'Texto', color: palette.text),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
