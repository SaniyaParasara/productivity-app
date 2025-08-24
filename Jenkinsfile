pipeline {
  agent any

  environment {
    IMAGE       = "saniyaparasara/productivity-app"
    TAG         = "build-${env.BUILD_NUMBER}"
    APP_PORT    = "8000"                 // container port
    HOST_PORT   = "8000"                 // change if 8000 is busy (e.g., 8010)
    CONTAINER   = "productivity-app"     // fixed name; replaces previous runs
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
          if (isUnix()) {
            sh   "docker build -t ${IMAGE}:${TAG} ."
          } else {
            bat  "docker build -t ${IMAGE}:${TAG} ."
          }
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
              sh  "docker tag ${IMAGE}:${TAG} ${IMAGE}:latest"
              sh  "docker push ${IMAGE}:${TAG}"
              sh  "docker push ${IMAGE}:latest"
            } else {
              bat "echo ${DP} | docker login -u ${DU} --password-stdin"
              bat "docker tag ${IMAGE}:${TAG} ${IMAGE}:latest"
              bat "docker push ${IMAGE}:${TAG}"
              bat "docker push ${IMAGE}:latest"
            }
          }
        }
      }
    }

    stage('Deploy Local') {
      steps {
        script {
          if (isUnix()) {
            sh  "docker rm -f ${CONTAINER} || true"
            sh  "docker run -d --name ${CONTAINER} -p ${HOST_PORT}:${APP_PORT} ${IMAGE}:${TAG}"
          } else {
            bat "docker rm -f ${CONTAINER} || ver>nul"
            bat "docker run -d --name ${CONTAINER} -p ${HOST_PORT}:${APP_PORT} ${IMAGE}:${TAG}"
          }
        }
      }
    }

    stage('Smoke Test') {
      steps {
        script {
          // Requires "HTTP Request" plugin
          def ok = false
          for (int i = 0; i < 12; i++) {
            try {
              def r = httpRequest url: "http://localhost:${HOST_PORT}/healthz",
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
      script {
        // Print container logs to help debugging
        if (isUnix()) { sh  "docker logs ${CONTAINER} || true" }
        else          { bat "docker logs ${CONTAINER} || ver>nul" }
      }
    }
    always {
      echo "Build result: ${currentBuild.currentResult}"
      script {
        if (isUnix()) {
          sh  "docker ps --format '{{.Names}} -> {{.Ports}}'"
        } else {
          bat "docker ps --format \"{{.Names}} -> {{.Ports}}\""
        }
      }
    }
  }
}
