pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        APP_NAME = "sohamrepo-chatbot"
        
        // Nexus Connection (Internal Service Name)
        // If this fails, replace 'nexus' with the Server IP (e.g. 192.168.1.50)
        NEXUS_URL = "nexus:8085" 
        
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // --- CREDENTIAL IDs (Must exist in Jenkins) ---
        NEXUS_CREDS_ID = "nexus-docker-login" 
        SONAR_TOKEN_ID = "2401023-chatbot" // <--- ENSURE THIS ID EXISTS IN JENKINS
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
                    // 1. Get the scanner tool
                    def scannerHome = tool 'SonarScanner' 
                    
                    // 2. Manually inject the Token (Bypassing broken Global Config)
                    withCredentials([string(credentialsId: SONAR_TOKEN_ID, variable: 'SONAR_TOKEN')]) {
                        
                        echo "🔍 Scanning with Manual Token..."
                        
                        // 3. Run Scanner with specific URL and Token
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