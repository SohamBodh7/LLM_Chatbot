pipeline {
    agent any

    environment {
        APP_NAME = "sohamrepo-chatbot"
        NEXUS_URL = "nexus:8085" 
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // Credentials
        NEXUS_CREDS_ID = "nexus-docker-login" 
        SONAR_TOKEN_ID = "2401023-chatbot" 
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('2. Prepare Configs') {
            steps {
                sh 'mkdir -p .streamlit'
                sh 'echo "[general]\\nmock = true" > .streamlit/secrets.toml'
            }
        }

        stage('3. SonarQube Analysis') {
            steps {
                script {
                    try {
                        def scannerHome = tool 'SonarScanner' 
                        withCredentials([string(credentialsId: SONAR_TOKEN_ID, variable: 'SONAR_TOKEN')]) {
                            echo "Running SonarQube Code Analysis..."
                            sh """
                            export SONAR_SCANNER_OPTS="-Xmx512m"
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=${APP_NAME} \
                            -Dsonar.sources=. \
                            -Dsonar.python.version=3.10 \
                            -Dsonar.host.url=http://sonarqube:9000 \
                            -Dsonar.login=${SONAR_TOKEN}
                            """
                            echo "SonarQube scan completed successfully"
                        }
                    } catch (Exception e) {
                        echo "SonarQube scan failed: ${e.message}"
                        echo "Continuing pipeline despite SonarQube failure..."
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        stage('4. Build Docker Image') {
            steps {
                script {
                    echo "Checking Docker availability..."
                    sh 'which docker || echo "Docker CLI not in PATH"'
                    sh 'ls -la /var/run/docker.sock || echo "Docker socket not found"'
                    sh 'echo "PATH is: $PATH"'
                    
                    echo "DOCKER IS NOT AVAILABLE ON THIS JENKINS SERVER"
                    echo "Please contact your administrator to:"
                    echo "1. Install Docker CLI in Jenkins container, OR"
                    echo "2. Mount Docker socket: -v /var/run/docker.sock:/var/run/docker.sock"
                    echo "Skipping Docker build..."
                    error("Docker not available - cannot build image")
                }
            }
        }

        stage('5. Push to Nexus Repository') {
            steps {
                script {
                    echo "Pushing Docker image to Nexus Repository..."
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo \$PASS | docker login ${NEXUS_URL} -u \$USER --password-stdin"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
                        echo "Docker images pushed successfully to Nexus"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    echo "Cleaning up local Docker images..."
                    sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
                    sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
                } catch (Exception e) {
                    echo "Cleanup skipped or failed (non-critical)"
                }
            }
        }
        success {
            echo "Pipeline completed successfully!"
            echo "Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
            echo "Image pushed to Nexus Repository"
        }
        failure {
            echo "Pipeline failed. Check the logs above for details."
            echo "REASON: Docker is not installed/available on Jenkins server"
            echo "SOLUTION: Contact your college administrator to configure Docker access"
        }
        unstable {
            echo "Pipeline completed with warnings (likely SonarQube connectivity issue)."
            echo "Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
            echo "Image pushed to Nexus Repository"
        }
    }
}