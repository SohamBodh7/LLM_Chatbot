// pipeline {
//     agent {
//         kubernetes {
//             yaml '''
// apiVersion: v1
// kind: Pod
// metadata:
//   labels:
//     jenkins: agent
// spec:
//   containers:
//   - name: docker
//     image: docker:latest
//     command:
//     - cat
//     tty: true
//     volumeMounts:
//     - name: docker-sock
//       mountPath: /var/run/docker.sock

//   - name: kubectl
//     image: bitnami/kubectl:latest
//     command:
//     - cat
//     tty: true
//     securityContext:
//       runAsUser: 0

//   volumes:
//   - name: docker-sock
//     hostPath:
//       path: /var/run/docker.sock
// '''
//         }
//     }

//     environment {
//         APP_NAME = "2401023-chatbot"
//         NEXUS_URL = "nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085" 
//         SONAR_HOST_URL = "http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000"
//         IMAGE_TAG = "${BUILD_NUMBER}"
//         K8S_NAMESPACE = "chatbot-prod"
        
//         // Credentials
//         NEXUS_CREDS_ID = "nexus-docker-login" 
//         SONAR_TOKEN_ID = "sonar-token-2401023" 
//     }

//     stages {
//         stage('1. Checkout Code') {
//             steps {
//                 checkout scm
//             }
//         }

//         stage('2. Prepare Configs') {
//             steps {
//                 container('docker') {
//                     sh 'mkdir -p .streamlit'
//                     sh 'echo "[general]\\nmock = true" > .streamlit/secrets.toml'
//                 }
//             }
//         }

//         stage('3. SonarQube Analysis') {
//             steps {
//                 script {
//                     try {
//                         def scannerHome = tool 'SonarScanner' 
//                         withCredentials([string(credentialsId: SONAR_TOKEN_ID, variable: 'SONAR_TOKEN')]) {
//                             echo "Running SonarQube Code Analysis..."
//                             sh """
//                             export SONAR_SCANNER_OPTS="-Xmx512m"
//                             ${scannerHome}/bin/sonar-scanner \
//                             -Dsonar.projectKey=${APP_NAME} \
//                             -Dsonar.sources=. \
//                             -Dsonar.python.version=3.10 \
//                             -Dsonar.host.url=${SONAR_HOST_URL} \
//                             -Dsonar.login=${SONAR_TOKEN}
//                             """
//                             echo "SonarQube scan completed successfully"
//                         }
//                     } catch (Exception e) {
//                         echo "SonarQube scan failed: ${e.message}"
//                         echo "Continuing pipeline despite SonarQube failure..."
//                         currentBuild.result = 'UNSTABLE'
//                     }
//                 }
//             }
//         }

//         stage('4. Build Docker Image') {
//             steps {
//                 container('docker') {
//                     script {
//                         echo "Building Docker Image..."
//                         sh 'sleep 5'
//                         sh "docker build -t ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ."
//                         sh "docker tag ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} ${NEXUS_URL}/${APP_NAME}:latest"
//                         echo "Docker image built successfully"
//                     }
//                 }
//             }
//         }

//         stage('5. Push to Nexus Repository') {
//             steps {
//                 container('docker') {
//                     script {
//                         echo "Pushing Docker image to Nexus Repository..."
//                         withCredentials([usernamePassword(credentialsId: NEXUS_CREDS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
//                             sh "echo \$PASS | docker login ${NEXUS_URL} -u \$USER --password-stdin"
//                             sh "docker push ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
//                             sh "docker push ${NEXUS_URL}/${APP_NAME}:latest"
//                             echo "Docker images pushed successfully to Nexus"
//                         }
//                     }
//                 }
//             }
//         }

//         stage('6. Deploy to Kubernetes') {
//             steps {
//                 container('kubectl') {
//                     script {
//                         echo "Deploying application to Kubernetes..."
//                         dir('k8s-deployment') {
//                             sh """
//                                 # Create namespace if it doesn't exist
//                                 kubectl apply -f namespace.yaml
                                
//                                 # Update image tag to current build
//                                 sed -i 's|:latest|:${IMAGE_TAG}|g' deployment.yaml
                                
//                                 # Apply Kubernetes resources
//                                 kubectl apply -f pvc.yaml
//                                 kubectl apply -f deployment.yaml
//                                 kubectl apply -f service.yaml
//                                 kubectl apply -f ingress.yaml
                                
//                                 # Wait for deployment to complete
//                                 kubectl rollout status deployment/${APP_NAME}-deployment -n ${K8S_NAMESPACE} --timeout=5m
                                
//                                 # Show deployment info
//                                 echo "Deployment completed successfully!"
//                                 kubectl get pods -n ${K8S_NAMESPACE} -l app=${APP_NAME}
//                                 kubectl get svc -n ${K8S_NAMESPACE} -l app=${APP_NAME}
//                             """
//                         }
//                     }
//                 }
//             }
//         }
//     }

//     post {
//         always {
//             container('docker') {
//                 script {
//                     try {
//                         echo "Cleaning up local Docker images..."
//                         sh "docker rmi ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG} || true"
//                         sh "docker rmi ${NEXUS_URL}/${APP_NAME}:latest || true"
//                     } catch (Exception e) {
//                         echo "Cleanup skipped or failed (non-critical)"
//                     }
//                 }
//             }
//         }
//         success {
//             echo "Pipeline completed successfully!"
//             echo "Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
//             echo "Image pushed to Nexus Repository"
//         }
//         failure {
//             echo "Pipeline failed. Check the logs above for details."
//         }
//         unstable {
//             echo "Pipeline completed with warnings (likely SonarQube connectivity issue)."
//             echo "Docker image built: ${NEXUS_URL}/${APP_NAME}:${IMAGE_TAG}"
//             echo "Image pushed to Nexus Repository"
//         }
//     }
// }

pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: sonar-scanner
    image: sonarsource/sonar-scanner-cli
    command: ["cat"]
    tty: true

  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["cat"]
    tty: true
    securityContext:
      runAsUser: 0
      readOnlyRootFilesystem: false
    env:
    - name: KUBECONFIG
      value: /kube/config
    volumeMounts:
    - name: kubeconfig-secret
      mountPath: /kube/config
      subPath: kubeconfig

  - name: dind
    image: docker:dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    volumeMounts:
    - name: docker-config
      mountPath: /etc/docker/daemon.json
      subPath: daemon.json

  volumes:
  - name: docker-config
    configMap:
      name: docker-daemon-config
  - name: kubeconfig-secret
    secret:
      secretName: kubeconfig-secret
'''
        }
    }

    environment {
        APP_NAME        = "2401023-chatbot"
        IMAGE_TAG       = "latest"
        REGISTRY_URL    = "nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085"
        REGISTRY_REPO   = "2401023-chatbot"
        SONAR_PROJECT   = "2401023_chatbot"
        SONAR_HOST_URL = "http://my-sonarqube-sonarqube.sonarqube.svc.cluster.local:9000"
    }

    stages {

        stage('Build Docker Image') {
            steps {
                container('dind') {
                    sh '''
                        sleep 15
                        docker build -t $APP_NAME:$IMAGE_TAG .
                        docker images
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                container('sonar-scanner') {
                    withCredentials([
                        string(credentialsId: 'sonar-token-2401023', variable: 'SONAR_TOKEN')
                    ]) {
                        sh '''
                            sonar-scanner \
                              -Dsonar.projectKey=$SONAR_PROJECT \
                              -Dsonar.host.url=$SONAR_HOST_URL \
                              -Dsonar.login=$SONAR_TOKEN \
                              -Dsonar.python.coverage.reportPaths=coverage.xml
                        '''
                    }
                }
            }
        }

        stage('Login to Docker Registry') {
            steps {
                container('dind') {
                    sh 'docker --version'
                    sh 'sleep 10'
                    sh 'docker login nexus-service-for-docker-hosted-registry.nexus.svc.cluster.local:8085 -u admin -p Changeme@2025'
                }
            }
        }

        stage('Build - Tag - Push Image') {
            steps {
                container('dind') {
                    sh '''
                        docker tag $APP_NAME:$IMAGE_TAG \
                          $REGISTRY_URL/$REGISTRY_REPO/$APP_NAME:$IMAGE_TAG

                        docker push $REGISTRY_URL/$REGISTRY_REPO/$APP_NAME:$IMAGE_TAG
                        docker pull $REGISTRY_URL/$REGISTRY_REPO/$APP_NAME:$IMAGE_TAG
                        docker images
                    '''
                }
            }
        }

        stage('Cleanup Old Resources') {
            steps {
                container('kubectl') {
                    script {
                        echo "Checking for old namespace 'chatbot-prod'..."
                        def namespaceExists = sh(
                            script: 'kubectl get namespace chatbot-prod --ignore-not-found',
                            returnStdout: true
                        ).trim()
                        
                        if (namespaceExists) {
                            echo "Found old namespace 'chatbot-prod'. Deleting..."
                            sh 'kubectl delete namespace chatbot-prod --wait=true --timeout=60s || true'
                            echo "Old namespace deleted successfully"
                        } else {
                            echo "No old namespace found. Proceeding with deployment..."
                        }

                        echo "Removing potential conflicting ingress..."
                        sh 'kubectl delete ingress sohamrepo-chatbot-ingress -n 2401023-chatbot --ignore-not-found=true || true'

                        echo "Removing stale deployment..."
                        sh 'kubectl delete deployment sohamrepo-chatbot-deployment -n 2401023-chatbot --ignore-not-found=true || true'
                    }
                }
            }
        }

        stage('Deploy Application') {
            steps {
                container('kubectl') {
                    dir('k8s-deployment') {
                        sh '''
                            kubectl apply -f deployment.yaml
                            kubectl apply -f service.yaml
                            kubectl apply -f ingress.yaml
                            kubectl apply -f pvc.yaml
                            kubectl apply -f namespace.yaml
                            kubectl rollout status deployment/sohamrepo-chatbot-deployment -n 2401023-chatbot --timeout=5m || echo "⚠️ Rollout timeout - checking pod status..."
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                container('kubectl') {
                    script {
                        echo "🔍 Checking deployment health..."
                        sh '''
                            echo "\n=== Namespace Status ==="
                            kubectl get all -n 2401023-chatbot
                            
                            echo "\n=== Pod Details ==="
                            kubectl get pods -n 2401023-chatbot -o wide
                            
                            echo "\n=== Deployment Status ==="
                            kubectl describe deployment sohamrepo-chatbot-deployment -n 2401023-chatbot | tail -30
                            
                            echo "\n=== Recent Events ==="
                            kubectl get events -n 2401023-chatbot --sort-by='.lastTimestamp' | tail -20
                            
                            # Get pod name and check logs if pod exists
                            POD_NAME=$(kubectl get pods -n 2401023-chatbot -l app=sohamrepo-chatbot -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
                            
                            if [ ! -z "$POD_NAME" ]; then
                                echo "\n=== Pod Description: $POD_NAME ==="
                                kubectl describe pod $POD_NAME -n 2401023-chatbot | tail -50
                                
                                echo "\n=== Pod Logs: $POD_NAME ==="
                                kubectl logs $POD_NAME -n 2401023-chatbot --tail=50 || echo "No logs available yet"
                            else
                                echo "\n⚠️ No pods found matching label app=sohamrepo-chatbot"
                            fi
                            
                            echo "\n=== Ingress Status ==="
                            kubectl get ingress -n 2401023-chatbot
                        '''
                    }
                }
            }
        }
    }
}


