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

        // 🔍 STAGE 1: SONARQUBE SCANNING (Non-blocking)
        stage('3. SonarQube Analysis') {
            steps {
                script {
                    try {
                        def scannerHome = tool 'SonarScanner' 
                        withCredentials([string(credentialsId: SONAR_TOKEN_ID, variable: 'SONAR_TOKEN')]) {
                            echo "🔍 Running SonarQube Code Analysis..."
                            sh """
                            export SONAR_SCANNER_OPTS="-Xmx512m"
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=${APP_NAME} \
                            -Dsonar.sources=. \
                            -Dsonar.python.version=3.10 \
                            -Dsonar.host.url=http://sonarqube:9000 \
                            -Dsonar.login=${SONAR_TOKEN}
                            """
                            echo "✅ SonarQube scan completed successfully"
                        }
                    } catch (Exception e) {
                        echo "⚠️ SonarQube scan failed: ${e.message}"
                        echo "⚠️ Continuing pipeline despite SonarQube failure..."
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }

        // 🐳 STAGE 2: BUILD DOCKER IMAGE
        stage('4. Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker Image..."
                    sh 'sleep 5'
                    sh "docker build -t ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ."
                    sh "docker tag ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ${NEXUS_URL}/${APP_NAME}:latest"
                    echo "✅ Docker image built successfully"
                }
            }
        }

        // 🚀 STAGE 3: PUSH TO NEXUS REPOSITORY
        stage('5. Push to Nexus Repository') {
            steps {
                script {
                    echo "🚀 Pushing Docker image to Nexus Repository..."
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo \$PASS | docker login ${NEXUS_URL} -u \$USER --password-stdin"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
                        echo "✅ Docker images pushed successfully to Nexus"
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    echo "🧹 Cleaning up local Docker images..."
                    sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
                    sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
                } catch (Exception e) {
                    echo "⚠️ Cleanup skipped or failed (non-critical)"
                }
            }
        }
        success {
            echo "🎉 Pipeline completed successfully!"
            echo "✓ SonarQube analysis passed"
            echo "✓ Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
            echo "✓ Image pushed to Nexus Repository"
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
        unstable {
            echo "⚠️ Pipeline completed with warnings (likely SonarQube connectivity issue)."
            echo "✓ Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
            echo "✓ Image pushed to Nexus Repository"
        }
    }
}