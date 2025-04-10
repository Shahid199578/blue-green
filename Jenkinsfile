pipeline {
  agent any

  environment {
    IMAGE = "shahid199578/demoapp"
    VERSION = "v1"
    AWS_REGION = "us-east-1"
    CLUSTER_NAME = "demoapp-cluster"
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/your-repo/demoapp.git'
      }
    }

    stage('Compile') {
      steps {
        sh 'mvn clean compile'
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
          sh 'mvn sonar:sonar'
        }
      }
    }

    stage('Trivy File Scan') {
      steps {
        sh 'trivy fs .'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh "docker build -t $IMAGE:$VERSION ."
      }
    }

    stage('Trivy Image Scan') {
      steps {
        sh "trivy image $IMAGE:$VERSION"
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
        sh '''
          aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
          sed "s|dockerimage|$$IMAGE:$VERSION|" k8s/green-deployment.yaml | kubectl apply -f -
        '''
      }
    }

    stage('Switch Traffic to Green') {
      steps {
        sh "kubectl patch svc demoapp-service -p '{\"spec\":{\"selector\":{\"app\":\"demoapp\",\"version\":\"green\"}}}'"
      }
    }

    stage('Cleanup Blue (Optional)') {
      steps {
        input "Do you want to delete Blue deployment?"
        sh "kubectl delete deployment app-blue || true"
      }
    }
  }
}
