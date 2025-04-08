FROM openjdk:17
COPY target/demoapp-1.0.0.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
