package com.atesteme.taskmanager.task;

import com.atesteme.taskmanager.exception.ResourceNotFoundException;
import com.atesteme.taskmanager.project.Project;
import com.atesteme.taskmanager.project.ProjectRepository;
import com.atesteme.taskmanager.security.AuthenticatedUserProvider;
import com.atesteme.taskmanager.user.User;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final ProjectRepository projectRepository;
    private final AuthenticatedUserProvider authenticatedUserProvider;

    public TaskService(
            TaskRepository taskRepository,
            ProjectRepository projectRepository,
            AuthenticatedUserProvider authenticatedUserProvider
    ) {
        this.taskRepository = taskRepository;
        this.projectRepository = projectRepository;
        this.authenticatedUserProvider = authenticatedUserProvider;
    }

    @Transactional(readOnly = true)
    public List<TaskResponse> list(Long projectId) {
        User user = authenticatedUserProvider.getCurrentUser();
        ensureProjectOwnership(projectId, user.getId());
        return taskRepository.findByProjectIdAndProjectUserIdOrderByCreatedAtDesc(projectId, user.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public TaskResponse create(Long projectId, TaskRequest request) {
        User user = authenticatedUserProvider.getCurrentUser();
        Project project = ensureProjectOwnership(projectId, user.getId());
        Task task = new Task(
                request.title().trim(),
                normalizeDescription(request.description()),
                request.priority(),
                request.status(),
                project
        );
        return toResponse(taskRepository.save(task));
    }

    @Transactional
    public TaskResponse update(Long projectId, Long taskId, TaskRequest request) {
        User user = authenticatedUserProvider.getCurrentUser();
        Task task = findOwnedTask(projectId, taskId, user.getId());
        task.update(
                request.title().trim(),
                normalizeDescription(request.description()),
                request.priority(),
                request.status()
        );
        return toResponse(task);
    }

    @Transactional
    public TaskResponse updateStatus(Long projectId, Long taskId, TaskStatusUpdateRequest request) {
        User user = authenticatedUserProvider.getCurrentUser();
        Task task = findOwnedTask(projectId, taskId, user.getId());
        task.updateStatus(request.status());
        return toResponse(task);
    }

    @Transactional
    public void delete(Long projectId, Long taskId) {
        User user = authenticatedUserProvider.getCurrentUser();
        Task task = findOwnedTask(projectId, taskId, user.getId());
        taskRepository.delete(task);
    }

    private Project ensureProjectOwnership(Long projectId, Long userId) {
        // Valida ownership antes de lidar com tarefas, garantindo isolamento entre usuários.
        return projectRepository.findByIdAndUserId(projectId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Projeto não encontrado."));
    }

    private Task findOwnedTask(Long projectId, Long taskId, Long userId) {
        return taskRepository.findByIdAndProjectIdAndProjectUserId(taskId, projectId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Tarefa não encontrada."));
    }

    private TaskResponse toResponse(Task task) {
        return new TaskResponse(
                task.getId(),
                task.getTitle(),
                task.getDescription(),
                task.getPriority(),
                task.getStatus(),
                task.getCreatedAt(),
                task.getProject().getId()
        );
    }

    private String normalizeDescription(String description) {
        return description == null || description.isBlank() ? null : description.trim();
    }
}

