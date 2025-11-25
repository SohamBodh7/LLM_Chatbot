pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  containers:
  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }

    environment {
        APP_NAME = "sohamrepo-chatbot"
        NEXUS_URL = "192.168.20.250:8085" 
        SONAR_HOST_URL = "http://192.168.20.250:9000"
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
                container('docker') {
                    sh 'mkdir -p .streamlit'
                    sh 'echo "[general]\\nmock = true" > .streamlit/secrets.toml'
                }
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
                            -Dsonar.host.url=${SONAR_HOST_URL} \
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
                container('docker') {
                    script {
                        echo "Building Docker Image..."
                        sh 'sleep 5'
                        sh "docker build -t ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ."
                        sh "docker tag ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ${NEXUS_URL}/${APP_NAME}:latest"
                        echo "Docker image built successfully"
                    }
                }
            }
        }

        stage('5. Push to Nexus Repository') {
            steps {
                container('docker') {
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
    }

    post {
        always {
            container('docker') {
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
        }
        success {
            echo "Pipeline completed successfully!"
            echo "Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
            echo "Image pushed to Nexus Repository"
        }
        failure {
            echo "Pipeline failed. Check the logs above for details."
        }
        unstable {
            echo "Pipeline completed with warnings (likely SonarQube connectivity issue)."
            echo "Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
            echo "Image pushed to Nexus Repository"
        }
    }
}