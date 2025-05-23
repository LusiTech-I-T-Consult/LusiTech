pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'eu-west-1' // or your region
  }

  stages {
    stage('Terraform Init') {
      steps {
        withAWS(credentials: 'awscreds') {
          sh 'terraform init'
        }
      }
      post {
        success { echo 'Terraform Init completed successfully.' }
        failure { echo 'Terraform Init failed.' }
        always { echo 'Terraform Init stage finished.' }
      }
    }

    stage('Terraform Plan') {
      steps {
        withAWS(credentials: 'awscreds') {
          sh 'terraform plan'
        }
      }
      post {
        success { echo 'Terraform Plan completed successfully.' }
        failure { echo 'Terraform Plan failed.' }
        always { echo 'Terraform Plan stage finished.' }
      }
    }

    stage('Terraform Apply') {
      steps {
        withAWS(credentials: 'awscreds') {
          sh 'terraform apply -auto-approve'
        }
      }
      post {
        success { echo 'Terraform Apply completed successfully.' }
        failure { echo 'Terraform Apply failed.' }
        always { echo 'Terraform Apply stage finished.' }
      }
    }
  }
}
