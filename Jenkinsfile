pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        SONAR_SERVER_NAME = "sonarqube" 
        APP_NAME = "sohamrepo-chatbot"
        
        // ⚠️ CRITICAL CHANGE FOR COLLEGE SERVER:
        // 'localhost' won't work inside the cluster. We guess the service name is 'nexus'.
        // If this fails, change 'nexus' to the IP address of the server.
        NEXUS_URL = "nexus:8085" 
        
        IMAGE_TAG = "${BUILD_NUMBER}"
        NEXUS_CREDS_ID = "nexus-docker-login" 
        SONAR_PROJECT_KEY = "${APP_NAME}"
        
        // Memory safety (keep this!)
        SONAR_SCANNER_OPTS = "-Xmx256m"
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
                    withSonarQubeEnv(SONAR_SERVER_NAME) { 
                        // 🛠️ THE FIX IS HERE:
                        // We add -Dsonar.host.url to OVERRIDE the broken admin setting.
                        // We try the internal container name "http://sonarqube:9000"
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.sources=. \
                        -Dsonar.python.version=3.10 \
                        -Dsonar.host.url=http://sonarqube:9000
                        """
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
                        // Note: If 'nexus:8085' fails, you might need to try the Server IP
                        withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            sh "echo $PASS | docker login ${NEXUS_URL} -u $USER --password-stdin"
                            sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                            sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
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