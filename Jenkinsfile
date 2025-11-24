pipeline {
    agent any 

    environment {
        // --- 1. CONFIGURATION ---
        // I updated this to match your screenshot exactly (lowercase)
        SONAR_SERVER_NAME = "sonarqube" 

        APP_NAME = "sohamrepo-chatbot"
        // Ensure this port matches your Nexus (e.g., 8085)
        NEXUS_URL = "localhost:8085" 
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        NEXUS_CREDS_ID = "nexus-docker-login" 
        SONAR_PROJECT_KEY = "${APP_NAME}"
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

        stage('3. SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner' 
                    // This now uses "sonarqube" to match your screenshot
                    withSonarQubeEnv(SONAR_SERVER_NAME) { 
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.sources=. \
                        -Dsonar.python.version=3.10
                        """
                    }
                }
            }
        }

        stage('4. Build Image') {
            steps {
                // Run inside 'dind' container to access Docker
                container('dind') {
                    script {
                        echo "🐳 Building Docker Image..."
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
                            sh "echo $PASS | docker login ${NEXUS_URL} -u $USER --password-stdin"
                            sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                            sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
                        }
                    }
                }
            }
        }
        
        post {
            always {
                container('dind') {
                    sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
                    sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
                }
            }
        }
    }
}