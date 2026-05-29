import 'package:flutter_modular/flutter_modular.dart';

import 'projects_page.dart';

class ProjectModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const ProjectsPage());
  }
}

