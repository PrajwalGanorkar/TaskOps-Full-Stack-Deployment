
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    triggers {
        githubPush()
        pollSCM('H/2 * * * *')
    }

    environment {
    DOCKERHUB = credentials('dockerhub-creds')
    DJANGO_SECRET_KEY = credentials('django-secret-key')
    IMAGE_TAG = "${BUILD_NUMBER}"
    COMPOSE_ENV = '--env-file .env.example'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Compose validation') {
            steps {
                withEnv(["DOCKERHUB_USER=${env.DOCKERHUB_USR}"]) {
                    bat '''
                        @echo off
                        docker compose %COMPOSE_ENV% config --quiet
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Build images') {
            steps {
                withEnv(["DOCKERHUB_USER=${env.DOCKERHUB_USR}"]) {
                    bat '''
                        @echo off

                        docker compose %COMPOSE_ENV% build
                        if errorlevel 1 exit /b 1

                        docker tag "%DOCKERHUB_USR%/taskops-backend:%IMAGE_TAG%" "%DOCKERHUB_USR%/taskops-backend:latest"
                        if errorlevel 1 exit /b 1

                        docker tag "%DOCKERHUB_USR%/taskops-frontend:%IMAGE_TAG%" "%DOCKERHUB_USR%/taskops-frontend:latest"
                        if errorlevel 1 exit /b 1
                    '''
                }
            }
        }

        stage('Backend tests') {
            steps {
                bat '''
                    @echo off
                    docker run --rm -e DEBUG=True "%DOCKERHUB_USR%/taskops-backend:%IMAGE_TAG%" python manage.py test
                    if errorlevel 1 exit /b 1
                '''
            }
        }

        stage('Push to Docker Hub') {
            when {
                expression {
                    def branch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'main'
                    branch == 'main' || branch == 'origin/main'
                }
            }

            steps {
                bat '''
                    @echo off

                    powershell -NoProfile -NonInteractive -Command "$env:DOCKERHUB_PSW | docker login -u $env:DOCKERHUB_USR --password-stdin; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }"

                    if errorlevel 1 exit /b 1

                    for %%S in (backend frontend) do (
                        docker push "%DOCKERHUB_USR%/taskops-%%S:%IMAGE_TAG%"
                        if errorlevel 1 exit /b 1

                        docker push "%DOCKERHUB_USR%/taskops-%%S:latest"
                        if errorlevel 1 exit /b 1
                    )
                '''
            }
        }

        stage('Deploy') {
            when {
                expression {
                    def branch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'main'
                    branch == 'main' || branch == 'origin/main'
                }
            }

            steps {
                script {
                    if (env.DEPLOY_HOST?.trim()) {

                        // AWS EC2 deployment
                        sshagent(credentials: ['ec2-ssh-key']) {
                            bat '''
                                @echo off

                                ssh -o StrictHostKeyChecking=accept-new ubuntu@%DEPLOY_HOST% "mkdir -p ~/taskops"
                                if errorlevel 1 exit /b 1

                                scp -o StrictHostKeyChecking=accept-new docker-compose.yml scripts/deploy.sh ubuntu@%DEPLOY_HOST%:~/taskops/
                                if errorlevel 1 exit /b 1

                                ssh -o StrictHostKeyChecking=accept-new ubuntu@%DEPLOY_HOST% "cd ~/taskops && DOCKERHUB_USER=%DOCKERHUB_USR% IMAGE_TAG=%IMAGE_TAG% sh deploy.sh"
                                if errorlevel 1 exit /b 1
                            '''
                        }

                    } else {

                        // Local Windows Docker deployment
                        withEnv(["DOCKERHUB_USER=${env.DOCKERHUB_USR}"]) {
                            bat '''
                                @echo off
                                docker compose %COMPOSE_ENV% pull
                                if errorlevel 1 exit /b 1

                                docker compose %COMPOSE_ENV% up -d
                                if errorlevel 1 exit /b 1
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            bat 'docker logout || exit /b 0'
        }

        success {
            echo "TaskOps pipeline OK - images pushed and deployed (tag ${env.BUILD_NUMBER})."
        }

        failure {
            echo 'Pipeline failed. Review the stage logs above.'
        }
    }
}
