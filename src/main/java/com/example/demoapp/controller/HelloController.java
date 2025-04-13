package com.example.demoapp.controller;

import com.example.demoapp.service.AppInfoService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    private final AppInfoService appInfoService;

    public HelloController(AppInfoService appInfoService) {
        this.appInfoService = appInfoService;
    }

    @GetMapping("/")
    public String home() {
        return "<h1>Welcome to the Blue Deployment App!</h1>";
    }

    @GetMapping("/health")
    public String health() {
        return "Application is healthy and running.";
    }

    @GetMapping("/version")
    public String version() {
        return "Version: " + appInfoService.getAppInfo().get("version");
    }
}