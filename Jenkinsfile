pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        APP_NAME = "sohamrepo-chatbot"
        
        // ⚠️ CRITICAL: If 'nexus:8085' fails with "Name not known" in the next run,
        // you MUST replace 'nexus' with the actual IP Address of the college server.
        // Example: "192.168.1.50:8085"
        NEXUS_URL = "nexus:8085" 
        
        IMAGE_TAG = "${BUILD_NUMBER}"
        NEXUS_CREDS_ID = "nexus-docker-login" 
        
        // Variables for the disabled SonarQube stage (kept for reference)
        SONAR_SERVER_NAME = "sonarqube"
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
                // Create dummy secret file so Streamlit doesn't crash during build
                sh 'mkdir -p .streamlit'
                sh 'echo "[general]\nmock = true" > .streamlit/secrets.toml'
            }
        }

        // ============================================================
        // 🛑 SONARQUBE STAGE (DISABLED)
        // Code preserved below for future reference.
        // To enable, remove the "/*" and "*/" symbols.
        // ============================================================
        /*
        stage('3. SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner' 
                    withSonarQubeEnv(SONAR_SERVER_NAME) { 
                        // Try to connect to internal container using -Dsonar.host.url
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.sources=. \
                        -Dsonar.python.version=3.10 \
                        -Dsonar.host.url=http://sonarqube:9000 \
                        -X
                        """
                    }
                }
            }
        }
        */
        // ============================================================

        stage('4. Build Image') {
            steps {
                // Run inside 'dind' container to find the 'docker' command
                container('dind') {
                    script {
                        echo "🐳 Building Docker Image..."
                        // Wait a few seconds to ensure Docker Daemon is ready
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
                // Use '|| true' so the pipeline stays Green even if cleanup errors occur
                sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
                sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
            }
        }
    }
}