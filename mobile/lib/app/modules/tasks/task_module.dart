import 'package:flutter_modular/flutter_modular.dart';

import 'tasks_page.dart';

class TaskModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(
      '/:projectId',
      child: (_) => TasksPage(
        projectId: int.parse(r.args.params['projectId']!),
        projectName: r.args.data as String?,
      ),
    );
  }
}

