package com.atesteme.taskmanager.project;

import com.atesteme.taskmanager.exception.ResourceNotFoundException;
import com.atesteme.taskmanager.security.AuthenticatedUserProvider;
import com.atesteme.taskmanager.user.User;
import java.util.LinkedHashSet;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final AuthenticatedUserProvider authenticatedUserProvider;

    public ProjectService(ProjectRepository projectRepository, AuthenticatedUserProvider authenticatedUserProvider) {
        this.projectRepository = projectRepository;
        this.authenticatedUserProvider = authenticatedUserProvider;
    }

    @Transactional(readOnly = true)
    public List<ProjectResponse> list() {
        User user = authenticatedUserProvider.getCurrentUser();
        return projectRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public ProjectResponse create(ProjectRequest request) {
        // O usuário autenticado vem do JWT para impedir manipulação de ownership pelo client.
        User user = authenticatedUserProvider.getCurrentUser();
        Project project = new Project(
                request.name().trim(),
                normalizeDescription(request.description()),
                serializeWorkers(request.workers()),
                user
        );
        return toResponse(projectRepository.save(project));
    }

    @Transactional
    public ProjectResponse update(Long projectId, ProjectRequest request) {
        User user = authenticatedUserProvider.getCurrentUser();
        Project project = findOwnedProject(projectId, user.getId());
        project.update(
                request.name().trim(),
                normalizeDescription(request.description()),
                serializeWorkers(request.workers())
        );
        return toResponse(project);
    }

    @Transactional
    public void delete(Long projectId) {
        User user = authenticatedUserProvider.getCurrentUser();
        Project project = findOwnedProject(projectId, user.getId());
        projectRepository.delete(project);
    }

    @Transactional(readOnly = true)
    public Project findOwnedProject(Long projectId, Long userId) {
        return projectRepository.findByIdAndUserId(projectId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Projeto não encontrado."));
    }

    private ProjectResponse toResponse(Project project) {
        return new ProjectResponse(
                project.getId(),
                project.getName(),
                project.getDescription(),
                parseWorkers(project.getWorkers()),
                project.getCreatedAt(),
                project.getTasks().size()
        );
    }

    private String normalizeDescription(String description) {
        return description == null || description.isBlank() ? null : description.trim();
    }

    private String serializeWorkers(List<String> workers) {
        if (workers == null || workers.isEmpty()) {
            return null;
        }

        LinkedHashSet<String> normalizedWorkers = new LinkedHashSet<>();
        for (String worker : workers) {
            if (worker != null && !worker.isBlank()) {
                normalizedWorkers.add(worker.trim());
            }
        }

        return normalizedWorkers.isEmpty() ? null : String.join("\n", normalizedWorkers);
    }

    private List<String> parseWorkers(String workers) {
        if (workers == null || workers.isBlank()) {
            return List.of();
        }

        return workers.lines()
                .map(String::trim)
                .filter(worker -> !worker.isBlank())
                .toList();
    }
}
