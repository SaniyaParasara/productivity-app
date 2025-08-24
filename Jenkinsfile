pipeline {
  agent any

  environment {
    IMAGE       = "saniyaparasara/productivity-app"
    TAG         = "build-${env.BUILD_NUMBER}"
    APP_PORT    = "8000"                 // container port
    HOST_PORT   = "8000"                 // change if busy (e.g., 8010)
    CONTAINER   = "productivity-app"     // fixed name
    DOCKER_HOST = "tcp://host.docker.internal:2375"  // Docker Desktop TCP
  }

  options {
    timestamps()
    timeout(time: 25, unit: 'MINUTES')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Docker Build (runs tests in Dockerfile)') {
      steps {
        script {
          if (isUnix()) { sh "docker build -t ${env.IMAGE}:${env.TAG} ." }
          else          { bat "docker build -t ${env.IMAGE}:${env.TAG} ." }
        }
      }
    }

    stage('Push to Docker Hub (main only)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          script {
            if (isUnix()) {
              sh  "echo ${DP} | docker login -u ${DU} --password-stdin"
              sh  "docker tag ${env.IMAGE}:${env.TAG} ${env.IMAGE}:latest"
              sh  "docker push ${env.IMAGE}:${env.TAG}"
              sh  "docker push ${env.IMAGE}:latest"
            } else {
              bat "echo ${DP} | docker login -u ${DU} --password-stdin"
              bat "docker tag ${env.IMAGE}:${env.TAG} ${env.IMAGE}:latest"
              bat "docker push ${env.IMAGE}:${env.TAG}"
              bat "docker push ${env.IMAGE}:latest"
            }
          }
        }
      }
    }

    stage('Deploy Local') {
      steps {
        script {
          if (isUnix()) {
            sh  "docker rm -f ${env.CONTAINER} || true"
            sh  "docker run -d --name ${env.CONTAINER} -p ${env.HOST_PORT}:${env.APP_PORT} ${env.IMAGE}:${env.TAG}"
          } else {
            bat "docker rm -f ${env.CONTAINER} || ver>nul"
            bat "docker run -d --name ${env.CONTAINER} -p ${env.HOST_PORT}:${env.APP_PORT} ${env.IMAGE}:${env.TAG}"
          }
        }
      }
    }

    stage('Smoke Test') {
      steps {
        script {
          // Requires "HTTP Request" plugin
          def ok = false
          for (int i=0; i<12; i++) {
            try {
              def r = httpRequest url: "http://localhost:${env.HOST_PORT}/healthz",
                                  validResponseCodes: '200',
                                  timeout: 10
              if (r?.content?.toLowerCase()?.contains('ok')) { ok = true; break }
            } catch (e) {
              sleep 3
            }
          }
          if (!ok) { error "Smoke test failed: /healthz did not return ok" }
        }
      }
    }
  }

  post {
    failure {
      // Wrap in node to ensure workspace/FilePath is available even on early failures
      node {
        script {
          try {
            if (isUnix()) { sh  "docker logs ${env.CONTAINER} || true" }
            else          { bat "docker logs ${env.CONTAINER} || ver>nul" }
          } catch (e) {
            echo "Could not fetch container logs: ${e}"
          }
        }
      }
    }
    always {
      node {
        script {
          echo "Build result: ${currentBuild.currentResult}"
          try {
            if (isUnix()) { sh  "docker ps --format '{{.Names}} -> {{.Ports}}'" }
            else          { bat "docker ps --format \"{{.Names}} -> {{.Ports}}\"" }
          } catch (e) {
            echo "Could not run docker ps: ${e}"
          }
        }
      }
    }
  }
}
