pipeline {
    agent any
    environment {
    SVC_ACCOUNT_KEY = credentials('terraform-auth')
  }
  stages {
      stage('Set Terraform path'){
          steps {
              script{
                  def tfHome = tool name: 'Terraform'
                  env.PATH = "${tfHome}:${env.PATH}"
              }
              sh 'terraform --version'
          }
      }
      stage('TF Plan'){
          steps {
            //   container('terraform') {
                  sh 'terraform init'
                  sh 'terraform plan'
            //   }
          }
      }
      stage('Approval'){
          steps {
              script {
                  def userInput = input(id: 'confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ])
              }
          }
      }
      stage('TF Apply'){
          steps {
            //   container('terraform'){
                  sh 'terraform apply -auto-approve'
            //   }
          }
      }
  }
}