pipeline {
    agent any
    tools {
        maven 'MAVEN_HOME'
    }
    
    stages {
        stage('Checkout Git Repository') {
            steps {
                echo 'Checking out the Git repository...'
                git branch: 'master', url: 'https://github.com/niranjan-1001/Medicure-healthcare.git'
            }
        }
        
        stage('Build Package') {
            steps {
                echo 'Building the package using Maven...'
                sh 'mvn clean package'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building the Docker image...'
                sh 'docker build -t niranjan1001/healthcare:1.0 .'
            }
        }

         stage('Publish the HTML Reports') {
      steps {
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: '/var/lib/jenkins/workspace/Healthcare/target/surefire-reports', reportFiles: 'index.html', reportName: 'HTML Report', reportTitles: '', useWrapperFileDirectly: true])
                        }
            } 
        
        stage('Login to Docker Hub') {
            steps {
                echo 'Logging in to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'Dockerlogin-user', passwordVariable: 'dockerhubpass', usernameVariable: 'dockerhublogin')]) {
                    sh "docker login -u ${dockerhublogin} -p ${dockerhubpass}"
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                echo 'Pushing the Docker image to Docker Hub...'
                sh 'docker push niranjan1001/healthcare:1.0'
            }
        }
        
        stage('Create Infrastructure with Terraform') {
            steps {
                echo 'Creating infrastructure using Terraform...'
                dir('scripts') {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'jenkinsIAMuser', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh 'terraform init'
                        sh 'terraform validate'
                        sh 'terraform apply --auto-approve -lock=false'
                    }
                }
            }
        }
    }
}
