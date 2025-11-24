pipeline {
    agent any

    environment {
        // --- UPDATED CONFIGURATION ---
        // Your specific Repo Name & Project Key
        APP_NAME = "sohamrepo-chatbot" 
        
        // Your specific Nexus Port (Must match the one you created in Nexus UI)
        NEXUS_URL = "localhost:8085" 
        
        // Deployment Port (Streamlit)
        APP_PORT = "8501"
        
        // Credentials IDs (From Manage Jenkins -> Credentials)
        NEXUS_CREDS_ID = "nexus-docker-login" 
        SONAR_PROJECT_KEY = "${APP_NAME}"
        
        // Automatic Versioning
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo "⬇️ Pulling code..."
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
                    echo "🔍 Scanning..."
                    def scannerHome = tool 'SonarScanner' 
                    withSonarQubeEnv('SonarQube-Server') { 
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
                script {
                    echo "🐳 Building Docker Image..."
                    sh "docker build -t ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ."
                    sh "docker tag ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ${NEXUS_URL}/${APP_NAME}:latest"
                }
            }
        }

        stage('5. Push to Nexus') {
            steps {
                script {
                    echo "🚀 Uploading to Port 8085..."
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo $PASS | docker login ${NEXUS_URL} -u $USER --password-stdin"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
                    }
                }
            }
        }
        
        // Deployment stage skipped for local CI testing. 
        // Uncomment if you have K8s ready.
        /* stage('6. Deploy') { ... } 
        */
    }

    post {
        always {
            echo "🧹 Cleaning up..."
            sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
            sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
        }
    }
}