package com.example.demoapp.service;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class AppInfoService {

    public Map<String, String> getAppInfo() {
        return Map.of(
            "version", "1.0.0",
            "description", "Blue-Green Deployment App",
            "releaseDate", "2025-04-08"
        );
    }
}