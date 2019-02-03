#!groovy?

def call(credentialsId, gitUsername, gitPassword, gitCommit, gitBranch, jobEnvVariables) {
    def credentialsId =  'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: credentialsId, usernameVariable: gitUsername, passwordVariable: gitPassword]]) {
        sh '''
            set +e
            set +x
            echo env.GIT_USERNAME=gitUsername > env.properties
            echo env.GIT_PASSWORD=gitPassword >> env.properties
            echo env.GIT_BRANCH=gitBranch >> env.properties
            echo env.ORIGINAL_BRANCH=gitBranch >> env.properties
            echo env.GIT_COMMIT=gitCommit >> env.properties
            cat env.properties
        '''
    }

    sh '''
        sed 's/$/"/g' -i env.properties
        sed 's/=/="/g' -i env.properties
    '''

    sh 'cat infra/jenkins-env-variables.groovy >> env.properties'

    return env.properties
    load ('env.properties')
    env.timestamp=(new Date()).toTimestamp().getTime()
    readEnvText()
}
