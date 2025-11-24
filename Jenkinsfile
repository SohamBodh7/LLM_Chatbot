pipeline {
    agent any

    environment {
        // ========================================================================
        // 🛠️ PROJECT SETTINGS (CHANGE THESE FOR NEW PROJECTS)
        // ========================================================================
        
        // 1. Project Name: Matches your SonarQube Project Key & Docker Image Name
        APP_NAME = "imcc-chatbot" 
        
        // 2. Deployment Port: The port your Python/Streamlit app runs on internally
        APP_PORT = "8501"

        // ========================================================================
        // ⚙️ INFRASTRUCTURE SETTINGS (SET ONCE FOR YOUR COLLEGE LAB)
        // ========================================================================
        
        // Nexus URL: Where Jenkins pushes the final Docker image
        // If Nexus is on the same server, use the host's IP or 'localhost'
        NEXUS_URL = "localhost:8083" 
        
        // SonarQube Project Key: Must match the key you created in SonarQube UI
        SONAR_PROJECT_KEY = "${APP_NAME}"
        
        // Credentials IDs: These must match what you created in "Manage Jenkins -> Credentials"
        NEXUS_CREDS_ID = "nexus-docker-login" 
        K8S_CREDS_ID   = "k8s-kubeconfig"     // Only needed for Kubernetes deployment
        SSH_CREDS_ID   = "college-server-ssh" // Only needed for Simple SSH deployment
        
        // Automatic Versioning: Uses the Jenkins Build Number (e.g., v1, v2, v3)
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        // ------------------------------------------------------------------------
        // STAGE 1: CHECKOUT CODE
        // ------------------------------------------------------------------------
        stage('1. Checkout Code') {
            steps {
                echo "⬇️ Pulling code from GitHub..."
                checkout scm
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 2: PREPARE ENVIRONMENT
        // ------------------------------------------------------------------------
        stage('2. Prepare Configs') {
            steps {
                echo "⚙️ Creating dummy secrets for build process..."
                // Streamlit needs this file to exist or it crashes during import
                sh 'mkdir -p .streamlit'
                sh 'echo "[general]\nmock = true" > .streamlit/secrets.toml'
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 3: CODE QUALITY CHECK (SONARQUBE)
        // ------------------------------------------------------------------------
        stage('3. SonarQube Analysis') {
            steps {
                script {
                    echo "🔍 Scanning code quality..."
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

        // ------------------------------------------------------------------------
        // STAGE 4: BUILD DOCKER IMAGE
        // ------------------------------------------------------------------------
        stage('4. Build Image') {
            steps {
                script {
                    echo "🐳 Building Docker Image for ${APP_NAME}..."
                    // Builds the image and tags it with specific version AND 'latest'
                    sh "docker build -t ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ."
                    sh "docker tag ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ${NEXUS_URL}/${APP_NAME}:latest"
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 5: PUSH TO NEXUS (ARTIFACT STORE)
        // ------------------------------------------------------------------------
        stage('5. Push to Nexus') {
            steps {
                script {
                    echo "🚀 Uploading image to Nexus..."
                    // Logs in to Nexus using the hidden credentials from Jenkins
                    withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo $PASS | docker login ${NEXUS_URL} -u $USER --password-stdin"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                        sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
                    }
                }
            }
        }

        // ========================================================================
        // 🚀 DEPLOYMENT STAGE (CHOOSE OPTION A OR B)
        // ========================================================================
        
        // OPTION A: DEPLOY TO KUBERNETES (DEFAULT)
        stage('6. Deploy to Kubernetes') {
            steps {
                script {
                    echo "☸️ Deploying to Kubernetes Cluster..."
                    // Wraps commands with the Kube Config file to access the cluster
                    withKubeConfig([credentialsId: K8S_CREDS_ID]) {
                        // Updates the image in the existing deployment
                        sh "kubectl set image deployment/${APP_NAME} chatbot-container=${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
                        sh "kubectl rollout status deployment/${APP_NAME}"
                    }
                }
            }
        }

        /* // OPTION B: DEPLOY TO SIMPLE SERVER (SSH & DOCKER RUN)
        // Enable this if your college server is just a VM, not Kubernetes.
        // You need 'SSH Pipeline Steps' plugin and an 'SSH Username with private key' credential.
        
        stage('6. Deploy via SSH') {
            steps {
                sshagent(credentials: [SSH_CREDS_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no user@college-server-ip '
                            echo "🛑 Stopping old container..."
                            docker stop ${APP_NAME} || true
                            docker rm ${APP_NAME} || true
                            
                            echo "⬇️ Pulling new image..."
                            docker pull ${NEXUS_URL}/${APP_NAME}:latest
                            
                            echo "▶️ Starting new container..."
                            docker run -d \
                            --name ${APP_NAME} \
                            -p ${APP_PORT}:${APP_PORT} \
                            --restart unless-stopped \
                            ${NEXUS_URL}/${APP_NAME}:latest
                        '
                    """
                }
            }
        } 
        */
    }

    // ------------------------------------------------------------------------
    // POST-BUILD CLEANUP
    // ------------------------------------------------------------------------
    post {
        always {
            echo "🧹 Cleaning up workspace..."
            // Removes the heavy images from Jenkins to save disk space
            sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
            sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
        }
        success {
            echo "✅ Deployment Successful! App is live."
        }
        failure {
            echo "❌ Build Failed. Check logs for details."
        }
    }
}