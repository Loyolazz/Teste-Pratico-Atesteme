import 'package:atesteme_taskmanager_mobile/app/modules/tasks/task_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte valores da API para enums de tarefa', () {
    expect(TaskStatus.fromValue('PENDENTE'), TaskStatus.pendente);
    expect(TaskStatus.fromValue('EM_ANDAMENTO'), TaskStatus.emAndamento);
    expect(TaskStatus.fromValue('CONCLUIDA'), TaskStatus.concluida);

    expect(TaskPriority.fromValue('BAIXA'), TaskPriority.baixa);
    expect(TaskPriority.fromValue('MEDIA'), TaskPriority.media);
    expect(TaskPriority.fromValue('ALTA'), TaskPriority.alta);
  });
}
