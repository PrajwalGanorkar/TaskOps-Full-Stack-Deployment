pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Backend tests') {
      steps { sh 'docker build -t taskops-backend:${BUILD_NUMBER} ./backend' }
    }
    stage('Frontend build') {
      steps { sh 'docker build -t taskops-frontend:${BUILD_NUMBER} ./frontend' }
    }
    stage('Compose validation') {
      steps { sh 'docker compose config --quiet' }
    }
  }
  post { success { echo 'TaskOps CI checks completed.' } failure { echo 'Build failed. Review stage logs.' } }
}
