# Use an official OpenJDK runtime as a parent image
FROM openjdk:25-slim

# Set the working directory
WORKDIR /app

# Copy the application JAR file
COPY target/demoapp-1.0.0.jar app.jar

# Expose the application port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
