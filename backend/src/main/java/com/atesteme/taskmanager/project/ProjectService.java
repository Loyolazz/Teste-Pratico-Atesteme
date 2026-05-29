package com.atesteme.taskmanager.project;

import com.atesteme.taskmanager.exception.ResourceNotFoundException;
import com.atesteme.taskmanager.security.AuthenticatedUserProvider;
import com.atesteme.taskmanager.user.User;
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
        Project project = new Project(request.name().trim(), normalizeDescription(request.description()), user);
        return toResponse(projectRepository.save(project));
    }

    @Transactional
    public ProjectResponse update(Long projectId, ProjectRequest request) {
        User user = authenticatedUserProvider.getCurrentUser();
        Project project = findOwnedProject(projectId, user.getId());
        project.update(request.name().trim(), normalizeDescription(request.description()));
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
                project.getCreatedAt(),
                project.getTasks().size()
        );
    }

    private String normalizeDescription(String description) {
        return description == null || description.isBlank() ? null : description.trim();
    }
}

