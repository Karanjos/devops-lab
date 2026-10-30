pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 45, unit: 'MINUTES')
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    parameters {
        string(name: 'ACR_NAME', defaultValue: '', description: 'ACR resource name only, not the login server. Required for publishing.')
        string(name: 'AZURE_SUBSCRIPTION_ID', defaultValue: '', description: 'Optional subscription ID for az account set.')
        string(name: 'TRIVY_IMAGE', defaultValue: 'aquasec/trivy:latest', description: 'Trivy image. Pin a version/digest for reproducible builds.')
    }

    environment {
        BACKEND_IMAGE = 'devops-lab/backend'
        FRONTEND_IMAGE = 'devops-lab/frontend'
        CONNECT_IMAGE = 'devops-lab/kafka-connect'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHA = sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()
                    if (!env.GIT_SHA) {
                        error('Could not determine the Git commit SHA.')
                    }
                    echo "Building commit ${env.GIT_SHA}"
                }
            }
        }
        
        
        stage('Backend: verify and test') {
            steps {
                sh '''
                    set -eu
                    mkdir -p .m2

                    docker run --rm \
                      --user "$(id -u):$(id -g)" \
                      -e HOME=/tmp \
                      -v "$WORKSPACE/backend:/workspace" \
                      -v "$WORKSPACE/.m2:/maven-cache" \
                      -w /workspace \
                      maven:3.9-eclipse-temurin-21 \
                      mvn -B -Dmaven.repo.local=/maven-cache/repository verify
                '''
            }
            post {
                always {
                    junit(
                        testResults: 'backend/target/surefire-reports/TEST-*.xml',
                        allowEmptyResults: true
                    )
                }
            }
        }


        stage('Frontend: install and build') {
            steps {
                sh '''
                    set -eu
                    docker run --rm \
                      --user "$(id -u):$(id -g)" \
                      -e npm_config_cache=/tmp/npm-cache \
                      -v "$WORKSPACE/frontend:/app" \
                      -w /app \
                      node:22-alpine \
                      sh -lc 'npm ci && npm run build'
                '''
            }
        }

        stage('Build Docker images') {
            steps {
                sh '''
                    set -eu
                    docker build --label "org.opencontainers.image.revision=$GIT_SHA" \
                      -t "$BACKEND_IMAGE:$GIT_SHA" -f backend/Dockerfile backend
                    docker build --label "org.opencontainers.image.revision=$GIT_SHA" \
                      -t "$FRONTEND_IMAGE:$GIT_SHA" -f frontend/Dockerfile frontend
                    docker build --label "org.opencontainers.image.revision=$GIT_SHA" \
                      -t "$CONNECT_IMAGE:$GIT_SHA" -f kafka/connect/Dockerfile kafka/connect
                '''
            }
        }

        stage('Trivy: scan images') {
            steps {
                sh '''
                    set -eu
                    for image in "$BACKEND_IMAGE:$GIT_SHA" "$FRONTEND_IMAGE:$GIT_SHA" "$CONNECT_IMAGE:$GIT_SHA"; do
                      echo "Scanning $image"
                      docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/ \
                        "$TRIVY_IMAGE" \
                        image --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed "$image"
                    done
                '''
            }
        }

        stage('Push images to Azure Container Registry') {
            when {
                not {
                    changeRequest()
                }
            }
            steps {
                script {
                    if (!params.ACR_NAME?.trim()) {
                        error('Set the ACR_NAME build parameter before publishing images.')
                    }
                }
                sh '''
                    set -eu

                    # Uses the managed identity assigned to the Jenkins VM.
                    az login --identity --output none

                    if [ -n "$AZURE_SUBSCRIPTION_ID" ]; then
                      az account set --subscription "$AZURE_SUBSCRIPTION_ID"
                    fi

                    ACR_LOGIN_SERVER="$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)"
                    if [ -z "$ACR_LOGIN_SERVER" ] || [ "$ACR_LOGIN_SERVER" = "None" ]; then
                      echo "Could not resolve the ACR login server for '$ACR_NAME'." >&2
                      exit 1
                    fi

                    echo "Publishing images to $ACR_LOGIN_SERVER"
                    az acr login --name "$ACR_NAME"

                    for image in "$BACKEND_IMAGE" "$FRONTEND_IMAGE" "$CONNECT_IMAGE"; do
                      source_image="$image:$GIT_SHA"
                      target_image="$ACR_LOGIN_SERVER/$image:$GIT_SHA"
                      docker tag "$source_image" "$target_image"
                      docker push "$target_image"
                    done
                '''
            }
        }
    }

    post {
        always {
            echo "CI pipeline finished for commit ${env.GIT_SHA ?: 'unknown'}"
        }
        success {
            echo 'Build, tests, image scan, and applicable publishing stages completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Review the stage logs and test reports above.'
        }
        cleanup {
            sh '''
                set +e
                if [ -n "${GIT_SHA:-}" ]; then
                  docker image rm "$BACKEND_IMAGE:$GIT_SHA" "$FRONTEND_IMAGE:$GIT_SHA" "$CONNECT_IMAGE:$GIT_SHA" >/dev/null 2>&1
                fi
            '''
        }
    }
}
