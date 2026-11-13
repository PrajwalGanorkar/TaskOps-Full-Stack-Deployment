// TaskOps CI/CD: test -> build -> push to Docker Hub -> deploy (on every push to main)
//
// Jenkins prerequisites (details in DEVOPS.md, section 7):
//   * Credentials: 'dockerhub-creds' (Username + Password/Access Token)
//   * Optional cloud deploy: credential 'ec2-ssh-key' (SSH key) + env var DEPLOY_HOST=<EC2 public IP>
//     If DEPLOY_HOST is empty, the stack is deployed on the Jenkins host itself (local/self-hosted).
//   * Agent needs Docker Engine + Compose plugin.
pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
  }

  // Fires on a GitHub webhook push; pollSCM is the fallback when Jenkins is not reachable from GitHub.
  triggers {
    githubPush()
    pollSCM('H/2 * * * *')
  }

  environment {
    DOCKERHUB  = credentials('dockerhub-creds')   // exposes DOCKERHUB_USR / DOCKERHUB_PSW (masked in logs)
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    COMPOSE_ENV = '--env-file .env.example'       // build/validate without needing a real secret
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Compose validation') {
      steps {
        sh '''
          export DOCKERHUB_USER="$DOCKERHUB_USR"
          docker compose $COMPOSE_ENV config --quiet
        '''
      }
    }

    stage('Build images') {
      steps {
        sh '''
          export DOCKERHUB_USER="$DOCKERHUB_USR"
          docker compose $COMPOSE_ENV build
          docker tag "$DOCKERHUB_USR/taskops-backend:$IMAGE_TAG"  "$DOCKERHUB_USR/taskops-backend:latest"
          docker tag "$DOCKERHUB_USR/taskops-frontend:$IMAGE_TAG" "$DOCKERHUB_USR/taskops-frontend:latest"
        '''
      }
    }

    stage('Backend tests') {
      steps {
        sh 'docker run --rm -e DEBUG=True "$DOCKERHUB_USR/taskops-backend:$IMAGE_TAG" python manage.py test'
      }
    }

    stage('Push to Docker Hub') {
      when { expression { (env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'main') ==~ /(origin\/)?main/ } }
      steps {
        sh '''
          echo "$DOCKERHUB_PSW" | docker login -u "$DOCKERHUB_USR" --password-stdin
          for svc in backend frontend; do
            docker push "$DOCKERHUB_USR/taskops-$svc:$IMAGE_TAG"
            docker push "$DOCKERHUB_USR/taskops-$svc:latest"
          done
        '''
      }
    }

    stage('Deploy') {
      when { expression { (env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'main') ==~ /(origin\/)?main/ } }
      steps {
        script {
          if (env.DEPLOY_HOST?.trim()) {
            // Cloud (AWS EC2 provisioned by Terraform)
            sshagent(credentials: ['ec2-ssh-key']) {
              sh '''
                SSH="ssh -o StrictHostKeyChecking=accept-new ubuntu@$DEPLOY_HOST"
                $SSH "mkdir -p ~/taskops"
                scp -o StrictHostKeyChecking=accept-new docker-compose.yml scripts/deploy.sh ubuntu@$DEPLOY_HOST:~/taskops/
                $SSH "cd ~/taskops && DOCKERHUB_USER=$DOCKERHUB_USR IMAGE_TAG=$IMAGE_TAG sh deploy.sh"
              '''
            }
          } else {
            // Local / self-hosted: deploy on the Docker host that runs this agent
            withEnv(["DOCKERHUB_USER=${env.DOCKERHUB_USR}"]) {
              sh 'sh scripts/deploy.sh'
            }
          }
        }
      }
    }
  }

  post {
    always  { sh 'docker logout || true' }
    success { echo "TaskOps pipeline OK - images pushed and deployed (tag ${env.BUILD_NUMBER})." }
    failure { echo 'Pipeline failed. Review the stage logs above.' }
  }
}
