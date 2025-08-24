pipeline {
  agent any

  environment {
    IMAGE = "saniyaparasara/productivity-app"
    TAG   = "build-${env.BUILD_NUMBER}"
    // Pin a known-good Kaniko release to avoid 404s on "latest"
    KANIKO_VER = "v1.23.2"
    KANIKO_URL = "https://github.com/GoogleContainerTools/kaniko/releases/download/${KANIKO_VER}/executor-linux-amd64"
  }

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Download Kaniko') {
      steps {
        script {
          // Download the Kaniko executor binary and make it executable
          httpRequest httpMode: 'GET', url: env.KANIKO_URL, outputFile: 'kaniko'
          sh 'chmod +x ./kaniko && ./kaniko --help >/dev/null 2>&1 || true'
        }
      }
    }

    stage('Build & Push Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          sh '''
            set -e
            mkdir -p /tmp/.docker
            AUTH="$(printf '%s:%s' "$DU" "$DP" | base64 | tr -d '\\n')"
            cat > /tmp/.docker/config.json <<EOF
{ "auths": { "https://index.docker.io/v1/": { "auth": "${AUTH}" } } }
EOF

            # Build & push the versioned tag
            ./kaniko --dockerfile Dockerfile \
                     --context "$WORKSPACE" \
                     --destination "${IMAGE}:${TAG}" \
                     --docker-config /tmp/.docker
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
            AUTH="$(printf '%s:%s' "$DU" "$DP" | base64 | tr -d '\\n')"
            cat > /tmp/.docker/config.json <<EOF
{ "auths": { "https://index.docker.io/v1/": { "auth": "${AUTH}" } } }
EOF

            # Push latest tag (reuses same build context)
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
