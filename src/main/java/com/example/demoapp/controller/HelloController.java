package com.example.demoapp.controller;

import com.example.demoapp.service.AppInfoService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HelloController {

    private final AppInfoService appInfoService;

    public HelloController(AppInfoService appInfoService) {
        this.appInfoService = appInfoService;
    }

    @GetMapping("/")
    public Map<String, String> home() {
        return Map.of(
            "message", "Welcome to the Blue-Green Deployment App!",
            "status", "success"
        );
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of(
            "status", "UP",
            "message", "Application is healthy and running."
        );
    }

    @GetMapping("/version")
    public Map<String, String> version() {
        return appInfoService.getAppInfo();
    }
}