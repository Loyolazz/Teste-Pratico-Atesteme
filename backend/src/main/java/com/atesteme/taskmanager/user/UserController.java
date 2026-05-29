package com.atesteme.taskmanager.user;

import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping
    public List<UserResponse> list() {
        return userRepository.findAllByOrderByNameAsc()
                .stream()
                .map(UserResponse::from)
                .toList();
    }
}
