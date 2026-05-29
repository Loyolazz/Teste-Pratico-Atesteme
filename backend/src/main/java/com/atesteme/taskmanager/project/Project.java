package com.atesteme.taskmanager.project;

import com.atesteme.taskmanager.task.Task;
import com.atesteme.taskmanager.user.User;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "projects")
public class Project {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(length = 500)
    private String description;

    @Column(length = 1600)
    private String workers;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @OneToMany(mappedBy = "project", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Task> tasks = new ArrayList<>();

    protected Project() {
    }

    public Project(String name, String description, String workers, User user) {
        this.name = name;
        this.description = description;
        this.workers = workers;
        this.user = user;
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
    }

    public void update(String name, String description, String workers) {
        this.name = name;
        this.description = description;
        this.workers = workers;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public String getWorkers() {
        return workers;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public User getUser() {
        return user;
    }

    public List<Task> getTasks() {
        return tasks;
    }
}
