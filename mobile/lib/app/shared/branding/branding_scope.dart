import 'package:flutter/widgets.dart';

import 'branding_config.dart';

class BrandingScope extends InheritedWidget {
  const BrandingScope({
    required this.config,
    required super.child,
    super.key,
  });

  final BrandingConfig config;

  static BrandingConfig of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<BrandingScope>()
            ?.config ??
        BrandingConfig.fallback;
  }

  @override
  bool updateShouldNotify(BrandingScope oldWidget) {
    return config != oldWidget.config;
  }
}
