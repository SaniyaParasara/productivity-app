pipeline {
  agent {
    docker {
      image 'docker:24-cli'                // has the docker CLI
      args '-e DOCKER_HOST=tcp://host.docker.internal:2375'
    }
  }

  environment {
    IMAGE       = "saniyaparasara/productivity-app"
    TAG         = "build-${env.BUILD_NUMBER}"
    APP_PORT    = "8000"
    HOST_PORT   = "8000"                   // change if busy, e.g., 8010
    CONTAINER   = "productivity-app"       // fixed name for easy replace
  }

  options { timestamps(); timeout(time: 25, unit: 'MINUTES') }

  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Docker Build (tests in Dockerfile)') {
      steps {
        sh "docker version"               // sanity check
        sh "docker build -t ${IMAGE}:${TAG} ."
      }
    }

    stage('Push to Docker Hub (main only)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          sh  "echo ${DP} | docker login -u ${DU} --password-stdin"
          sh  "docker tag ${IMAGE}:${TAG} ${IMAGE}:latest"
          sh  "docker push ${IMAGE}:${TAG}"
          sh  "docker push ${IMAGE}:latest"
        }
      }
    }

    stage('Deploy Local') {
      steps {
        sh "docker rm -f ${CONTAINER} || true"
        sh "docker run -d --name ${CONTAINER} -p ${HOST_PORT}:${APP_PORT} ${IMAGE}:${TAG}"
      }
    }

    stage('Smoke Test') {
      steps {
        script {
          // Requires HTTP Request plugin
          def ok = false
          for (int i = 0; i < 12; i++) {
            try {
              def r = httpRequest url: "http://host.docker.internal:${HOST_PORT}/healthz",
                                  validResponseCodes: '200', timeout: 10
              if (r?.content?.toLowerCase()?.contains('ok')) { ok = true; break }
            } catch (e) { sleep 3 }
          }
          if (!ok) error "Smoke test failed"
        }
      }
    }
  }

  post {
    failure {
      sh "docker logs ${CONTAINER} || true"
    }
    always {
      echo "Build result: ${currentBuild.currentResult}"
      sh "docker ps --format '{{.Names}} -> {{.Ports}}' || true"
    }
  }
}
