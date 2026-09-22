pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "tobal1234/jenkins-cicd-project"
    }

    stages {
        stage('Oluwatoba.Lojede - Build Docker Image') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .'
            }
        }

        stage('Oluwatoba.Lojede - Login to Dockerhub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh 'echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USER" --password-stdin'
                }
            }
        }

        stage('Oluwatoba.Lojede - Push image to Dockerhub') {
            steps {
                sh 'docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}'
            }
        }
    }
}