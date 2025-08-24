pipeline {
  agent any

  environment {
    REPO  = 'https://github.com/SaniyaParasara/productivity-app.git'  // your repo
    BRANCH= 'main'
    IMAGE = 'saniyaparasara/productivity-app'                         // your Docker Hub image
    TAG   = "build-${env.BUILD_NUMBER}"
    // Pin a Kaniko version to avoid 404s on "latest"
    KANIKO_VER = 'v1.23.2'
    KANIKO_URL = "https://github.com/GoogleContainerTools/kaniko/releases/download/${KANIKO_VER}/executor-linux-amd64"
  }

  options { timestamps(); timeout(time: 20, unit: 'MINUTES') }

  stages {
    stage('Checkout') {
      steps {
        git branch: env.BRANCH, url: env.REPO
      }
    }

    stage('Download Kaniko') {
      steps {
        script {
          httpRequest httpMode: 'GET', url: env.KANIKO_URL, outputFile: 'kaniko'
          sh 'chmod +x ./kaniko'
        }
      }
    }

    stage('Build & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          sh '''
            set -e
            mkdir -p /tmp/.docker
            AUTH="$(printf '%s:%s' "$DU" "$DP" | base64 | tr -d '\\n')"
            cat > /tmp/.docker/config.json <<EOF
{ "auths": { "https://index.docker.io/v1/": { "auth": "${AUTH}" } } }
EOF
            ./kaniko --dockerfile Dockerfile --context "$WORKSPACE" \
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
            ./kaniko --dockerfile Dockerfile --context "$WORKSPACE" \
                     --destination "${IMAGE}:latest" \
                     --docker-config /tmp/.docker
          '''
        }
      }
    }
  }

  post {
    always { echo "Build result: ${currentBuild.currentResult}" }
  }
}
