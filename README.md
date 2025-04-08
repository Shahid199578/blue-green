# 🚀 EKS CI/CD Blue-Green Deployment Project

This project demonstrates a complete **CI/CD pipeline** using **Jenkins**, **Terraform**, **Docker**, **SonarQube**, **Trivy**, and **Amazon EKS**. It features a **Spring Boot** application and implements a **Blue-Green deployment** strategy to minimize downtime during releases.

---

## 📦 Features

- ☕ Spring Boot microservice
- 🐳 Dockerized build
- 🧹 Static code analysis with SonarQube
- 🔐 Vulnerability scanning with Trivy
- 🔁 CI/CD pipeline using Jenkins
- ☁️ Infrastructure as Code with Terraform
- ♻️ Zero-downtime Blue-Green Deployment on EKS

---

## 🛠️ Tech Stack

- Java 17 / Spring Boot 3.x
- Docker
- Terraform
- Jenkins
- SonarQube
- Trivy
- Amazon EKS
- Kubernetes

---

## 📁 Project Structure

```
.
├── Dockerfile
├── Jenkinsfile
├── pom.xml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── k8s/
│   ├── blue-deployment.yaml
│   ├── green-deployment.yaml
│   └── service.yaml
└── src/
    └── main/
        └── java/
            └── com/example/demoapp/
                ├── DemoApplication.java
                └── controller/
                    └── HelloController.java
```

---

## ☸️ Infrastructure Setup with Terraform

### 1. 🔧 Provision AWS Resources

```bash
cd terraform
terraform init
terraform apply
```

### 2. 📡 Connect to EKS Cluster

```bash
aws eks --region <your-region> update-kubeconfig --name demoapp-cluster
```

> Replace `<your-region>` with your actual AWS region (e.g., `ap-south-1`)

---

## 🚦 Initial Kubernetes Deployment (Blue Version)

Before running Jenkins pipeline for the first time, deploy the blue version and service:

```bash
kubectl apply -f k8s/blue-deployment.yaml
kubectl apply -f k8s/service.yaml
```

---

## 🔁 Jenkins CI/CD Pipeline

The Jenkins pipeline will:

1. Checkout the source code
2. Compile and test the application
3. Scan the code using SonarQube
4. Run file and image vulnerability scans using Trivy
5. Build and push Docker image to DockerHub
6. Deploy the green version to EKS
7. Switch production traffic from blue to green
8. (Optional) Remove the blue deployment

> ⚙️ Ensure **Jenkins**, **Trivy**, and **SonarQube** are _installed and running_ on their respective EC2 instances.  
> 👉 [Install Jenkins](https://mantratech.hashnode.dev/jenkins-installation-on-ubuntu)  
> 👉 [Install SonarQube](https://mantratech.hashnode.dev/how-to-install-sonarqube-on-ubuntu)

### Jenkins Requirements

- ✅ Docker installed on Jenkins agent
- ✅ AWS CLI and `kubectl` configured on Jenkins agent
- ✅ Trivy installed
- ✅ Credentials:
  - DockerHub (`dockerhub-creds`)
  - SonarQube (`MySonarQube`)


---

## ✅ Accessing the Application

Once deployed, access the app using your Load Balancer DNS:

```bash
curl http://<LOAD_BALANCER_DNS>/health
```

To test both versions (blue & green), you can also port-forward or set up additional services per deployment for side-by-side inspection.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!  
Feel free to fork the repo and submit pull requests.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙋‍♂️ Questions?

Open an issue or reach out to [yourname@yourdomain.com](mailto:yourname@yourdomain.com)

