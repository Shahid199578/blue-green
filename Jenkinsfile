pipeline {
  agent any
  tools {
        maven 'Maven-Tool'
    }


  environment {
    IMAGE = "shahid199578/demoapp"
    VERSION = "v1"
    AWS_REGION = "ap-south-1"
    CLUSTER_NAME = "demoapp-cluster"
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/Shahid199578/blue-green.git'
      }
    }

    stage('Compile') {
      steps {
        sh 'mvn clean package'
      }
    }

    stage('Run Tests') {
      steps {
        sh 'mvn test'
      }
    }

    stage('Code Scan (SonarQube)') {
      steps {
        withSonarQubeEnv('MySonarQube') {
          sh "mvn sonar:sonar -Dsonar.projectKey=blue-green"
        }
      }
    }

    stage('Trivy File Scan') {
      steps {
        sh 'trivy fs . > trivy_file_report || true'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t $IMAGE:$VERSION ."
      }
    }

    stage('Trivy Image Scan') {
      steps {
        sh "trivy image $IMAGE:$VERSION > trivy_image_report || true"
      }
    }

    stage('Push to DockerHub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
          sh """
            echo $PASS | docker login -u $USER --password-stdin
            docker push $IMAGE:$VERSION
          """
        }
      }
    }

    stage('Deploy to EKS (Green)') {
      steps {
        sh """
          aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
          sed 's|dockerimage|${IMAGE}:${VERSION}|' k8s/green-deployment.yaml | kubectl apply -f -
        """
      }
    }
    stage('Switch Traffic to Green') {
      steps {
        sh "kubectl patch svc demoapp-service -p '{\"spec\":{\"selector\":{\"app\":\"demoapp\",\"version\":\"green\"}}}'"
      }
    }
  }
}