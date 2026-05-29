package com.atesteme.taskmanager.task;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByProjectIdAndProjectUserIdOrderByCreatedAtDesc(Long projectId, Long userId);

    Optional<Task> findByIdAndProjectIdAndProjectUserId(Long id, Long projectId, Long userId);
}

