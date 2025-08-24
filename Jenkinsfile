pipeline {
  agent any

  environment {
    IMAGE = "saniyaparasara/productivity-app"
    TAG   = "build-${env.BUILD_NUMBER}"
  }

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Download Kaniko') {
      steps {
        // Use HTTP Request plugin to download the Kaniko executor binary (no curl/wget needed)
        script {
          def url = 'https://github.com/GoogleContainerTools/kaniko/releases/latest/download/executor-linux-amd64'
          httpRequest httpMode: 'GET', url: url, outputFile: 'kaniko'
          sh 'chmod +x ./kaniko'
        }
      }
    }

    stage('Build & Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          sh '''
            set -e
            # Create Docker auth config for Kaniko
            mkdir -p /tmp/.docker
            printf '%s:%s' "$DU" "$DP" | base64 | tr -d '\\n' > /tmp/.docker/.auth
            AUTH=$(cat /tmp/.docker/.auth)

            cat > /tmp/.docker/config.json <<EOF
{ "auths": { "https://index.docker.io/v1/": { "auth": "${AUTH}" } } }
EOF

            # Build & push tag
            ./kaniko --dockerfile Dockerfile \
                     --context "$WORKSPACE" \
                     --destination "${IMAGE}:${TAG}" \
                     --docker-config /tmp/.docker

            # Also push :latest on main
          '''
        }
      }
    }

    stage('Tag latest (main only)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          sh '''
            set -e
            mkdir -p /tmp/.docker
            printf '%s:%s' "$DU" "$DP" | base64 | tr -d '\\n' > /tmp/.docker/.auth
            AUTH=$(cat /tmp/.docker/.auth)

            cat > /tmp/.docker/config.json <<EOF
{ "auths": { "https://index.docker.io/v1/": { "auth": "${AUTH}" } } }
EOF

            ./kaniko --dockerfile Dockerfile \
                     --context "$WORKSPACE" \
                     --destination "${IMAGE}:latest" \
                     --docker-config /tmp/.docker
          '''
        }
      }
    }
  }

  post {
    always {
      echo "Build result: ${currentBuild.currentResult}"
    }
  }
}
