pipeline {
  agent any

  environment {
    IMAGE       = "saniyaparasara/productivity-app"
    TAG         = "build-${env.BUILD_NUMBER}"
    APP_PORT    = "8000"
    HOST_PORT   = "8000"
    CONTAINER   = "productivity-app"
  }

  options { timestamps(); timeout(time: 25, unit: 'MINUTES') }

  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Install Python deps for smoke test') {
      steps {
        sh '''
          python3 -V || true
          apt-get update && apt-get install -y python3 python3-pip curl ca-certificates
          pip3 install --no-cache-dir -r requirements.txt
        '''
      }
    }

    stage('Build image with Kaniko') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DU', passwordVariable: 'DP')]) {
          sh '''
            set -e
            mkdir -p /kaniko/.docker
            AUTH=$(printf '%s:%s' "$DU" "$DP" | base64 -w0)
cat >/kaniko/.docker/config.json <<EOF
{ "auths": { "https://index.docker.io/v1/": { "auth": "${AUTH}" } } }
EOF
            curl -sSL -o /tmp/kaniko \
              https://github.com/GoogleContainerTools/kaniko/releases/latest/download/executor-linux-amd64
            chmod +x /tmp/kaniko

            # Build & push :TAG (always) and :latest on main
            /tmp/kaniko --dockerfile Dockerfile --context "$WORKSPACE" --destination "${IMAGE}:${TAG}"
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
            mkdir -p /kaniko/.docker
            AUTH=$(printf '%s:%s' "$DU" "$DP" | base64 -w0)
cat >/kaniko/.docker/config.json <<EOF
{ "auths": { "https://index.docker.io/v1/": { "auth": "${AUTH}" } } }
EOF
            curl -sSL -o /tmp/kaniko \
              https://github.com/GoogleContainerTools/kaniko/releases/latest/download/executor-linux-amd64
            chmod +x /tmp/kaniko

            /tmp/kaniko --dockerfile Dockerfile --context "$WORKSPACE" --destination "${IMAGE}:latest"
          '''
        }
      }
    }

    stage('Smoke Test (run app directly)') {
      steps {
        sh '''
          set -e
          # run flask app in background
          python3 app.py & echo $! > app.pid
          # wait a moment for startup
          for i in $(seq 1 20); do
            if curl -fsS http://localhost:${HOST_PORT}/healthz >/dev/null 2>&1; then
              OK=1; break
            fi
            sleep 1
          done
          if [ -z "$OK" ]; then
            echo "Smoke failed"; kill $(cat app.pid) || true; exit 1
          fi
          # stop the app
          kill $(cat app.pid) || true
        '''
      }
    }
  }

  post {
    failure {
      echo "Build failed."
    }
    always {
      echo "Build result: ${currentBuild.currentResult}"
    }
  }
}
