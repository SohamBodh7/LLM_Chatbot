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
                sh 'echo "[general]\nmock = true" > .streamlit/secrets.toml'
            }
        }

        // 🚀 PRIORITY 1: BUILD IMAGE
        stage('3. Build Image') {
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

        // 🚀 PRIORITY 2: PUSH TO NEXUS
        stage('4. Push to Nexus') {
            steps {
                container('dind') {
                    script {
                        echo "🚀 Uploading to Nexus..."
                        withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            try {
                                sh "echo $PASS | docker login ${NEXUS_URL} -u $USER --password-stdin"
                                sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                                sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
                            } catch (Exception e) {
                                error("Nexus Push Failed")
                            }
                        }
                    }
                }
            }
        }

        // ⚠️ OPTIONAL: SONARQUBE (RUNS LAST)
        stage('5. SonarQube (Optional)') {
            steps {
                script {
                    try {
                        def scannerHome = tool 'SonarScanner' 
                        withCredentials([string(credentialsId: SONAR_TOKEN_ID, variable: 'SONAR_TOKEN')]) {
                            echo "🔍 Attempting SonarQube Scan..."
                            // Attempt scan with limited memory to prevent crash
                            sh """
                            export SONAR_SCANNER_OPTS="-Xmx512m"
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=${APP_NAME} \
                            -Dsonar.sources=. \
                            -Dsonar.python.version=3.10 \
                            -Dsonar.host.url=http://sonarqube:9000 \
                            -Dsonar.login=${SONAR_TOKEN}
                            """
                        }
                    } catch (Exception e) {
                        echo "⚠️ Scan failed or crashed agent. (But Docker image is safe!)"
                        currentBuild.result = 'UNSTABLE'
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