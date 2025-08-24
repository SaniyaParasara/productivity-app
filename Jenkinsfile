pipeline {
  agent any
  environment {
    IMAGE = "saniyaparasara/productivity-app" 
    TAG   = "build-${env.BUILD_NUMBER}"
    APP_PORT = "8000"
    CONTAINER = "productivity_app_${env.BUILD_NUMBER}"
    DOCKER_HOST = "tcp://host.docker.internal:2375"
  }
  options { timestamps(); ansiColor('xterm') }

  stages {
    stage('Checkout'){ steps { checkout scm } }

    stage('Docker Build (tests run in build)'){
      steps {
        script {
          if (isUnix()) sh "docker build -t ${IMAGE}:${TAG} ."
          else          bat "docker build -t ${IMAGE}:${TAG} ."
        }
      }
    }

    stage('Push to Docker Hub (main only)'){
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          script {
            if (isUnix()) {
              sh "echo ${DP} | docker login -u ${DU} --password-stdin"
              sh "docker tag ${IMAGE}:${TAG} ${IMAGE}:latest"
              sh "docker push ${IMAGE}:${TAG}"
              sh "docker push ${IMAGE}:latest"
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

    stage('Deploy Local'){
      steps {
        script {
          if (isUnix()) {
            sh "docker rm -f ${CONTAINER} || true"
            sh "docker run -d --name ${CONTAINER} -p 8000:${APP_PORT} ${IMAGE}:${TAG}"
          } else {
            bat "docker rm -f ${CONTAINER} || ver>nul"
            bat "docker run -d --name ${CONTAINER} -p 8000:${APP_PORT} ${IMAGE}:${TAG}"
          }
        }
      }
    }

    stage('Smoke Test'){
      steps {
        script {
          def ok=false
          for (int i=0;i<10;i++){
            try {
              def r = httpRequest url: "http://localhost:8000/healthz", validResponseCodes: '200', timeout: 10
              if (r?.content?.contains('ok')) { ok=true; break }
            } catch(e) { sleep 3 }
          }
          if (!ok) error "Smoke test failed"
        }
      }
    }
  }

  post {
    always {
      echo "Build: ${currentBuild.currentResult}"
      script {
        if (isUnix()) sh "docker ps --format '{{.Names}} -> {{.Ports}}'"
        else          bat "docker ps --format \"{{.Names}} -> {{.Ports}}\""
      }
    }
  }
}  