pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        APP_NAME = "sohamrepo-chatbot"
        NEXUS_URL = "nexus:8085" 
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // Credentials
        NEXUS_CREDS_ID = "nexus-docker-login" 
        SONAR_TOKEN_ID = "2401023-chatbot" // Your created ID
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
                sh 'echo "[general]\nmock = true" > .streamlit/secrets.toml'
            }
        }

        stage('3. SonarQube (Allow Failure)') {
            steps {
                script {
                    // We wrap this in a TRY block so errors don't kill the build
                    try {
                        def scannerHome = tool 'SonarScanner' 
                        withCredentials([string(credentialsId: SONAR_TOKEN_ID, variable: 'SONAR_TOKEN')]) {
                            echo "🔍 Attempting SonarQube Scan..."
                            sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=${APP_NAME} \
                            -Dsonar.sources=. \
                            -Dsonar.python.version=3.10 \
                            -Dsonar.host.url=http://sonarqube:9000 \
                            -Dsonar.login=${SONAR_TOKEN} \
                            -X
                            """
                        }
                    } catch (Exception e) {
                        // If it fails, we catch the error and print a warning instead of stopping
                        echo "⚠️ SonarQube Connection Failed. Skipping scan to proceed with Docker Build."
                        echo "Error details: ${e.getMessage()}"
                        // We set the stage result to UNSTABLE (Yellow) instead of FAILURE (Red)
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        stage('4. Build Image') {
            steps {
                container('dind') {
                    script {
                        echo "🐳 Building Docker Image..."
                        sh 'sleep 5'
                        sh "docker build -t ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ."
                        sh "docker tag ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ${NEXUS_URL}/${APP_NAME}:latest"
                    }
                }
            }
        }

        stage('5. Push to Nexus') {
            steps {
                container('dind') {
                    script {
                        echo "🚀 Uploading to Nexus..."
                        withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            // We allow failure here too, just in case 'nexus' hostname is also wrong
                            try {
                                sh "echo $PASS | docker login ${NEXUS_URL} -u $USER --password-stdin"
                                sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                                sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
                            } catch (Exception e) {
                                echo "⚠️ Nexus Push Failed (Hostname issue?)."
                                error("Nexus Push Failed") // We DO fail the build if Nexus fails
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            container('dind') {
                echo "🧹 Cleaning up..."
                sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
                sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
            }
        }
    }
}