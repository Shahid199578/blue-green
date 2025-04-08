package com.example.demoapp.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
  @GetMapping("/")
  public String home() {
    return "Welcome to the Blue-Green Deployment App!";
  }

  @GetMapping("/health")
  public String health() {
    return "OK";
  }
}
