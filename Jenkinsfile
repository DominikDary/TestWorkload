echo "SNAPSHOT_VERSION: ${BUILD_NUMBER}"
buildNumber = "${BUILD_NUMBER}"

node("mesos-windows") {
    stage('Checkout of git repo (cmd)') {
        bat 'IF not exist TestWorkload (git clone https://sergiimatusEPAM@github.com/alekspv/TestWorkload.git) else (cd TestWorkload && git pull)';
    }
    stage('Clean') {
        bat "cd TestWorkload && dotnet clean"
    }
    stage('Build') {
        bat 'cd TestWorkload && dotnet build'
    }
    stage('Publish, pack into zip') {
        bat 'cd TestWorkload && dotnet publish -o .\\..\\..\\target'
        bat '7z.exe a -mmt2 -tzip package.%BUILD_NUMBER%.zip target'
    }
    stage("Upload Snapshot to Nexus "){
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'Nexus_token', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            bat "curl -v -u %USERNAME%:%PASSWORD% --upload-file package.%BUILD_NUMBER%.zip http://nexus.marathon.mesos:27092/repository/dotnet-sample/0.1-SNAPSHOT/TestWorkload.zip"
        }
    }
    stage("Upload Release to Nexus "){
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'Nexus_token', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            bat "curl -v -u %USERNAME%:%PASSWORD% --upload-file package.%BUILD_NUMBER%.zip http://nexus.marathon.mesos:27092/repository/dotnet-sample/RELEASE/TestWorkload-0.1.%BUILD_NUMBER%.zip"
        }
    }
}
node("build-docker"){
    stage("Build Docker image"){
        bat """
            docker build -t sergiimatusepam/testworkload-app https://raw.githubusercontent.com/alekspv/TestWorkload/master/Dockerfile --no-cache
            docker tag sergiimatusepam/testworkload-app:latest sergiimatusepam/testworkload-app:0.%BUILD_NUMBER%
        """
    }
    stage("Publish to DockerHub"){
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'DockerHub_token', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
            bat """
                echo | set /p="%PASSWORD%" | docker login -u %USERNAME% --password-stdin
                docker push sergiimatusepam/testworkload-app:0.%BUILD_NUMBER%
                docker push sergiimatusepam/testworkload-app:latest
            """
        }
    }
}
node("mesos-windows") {
    stage("Publish service") {
        marathon(
            url: 'http://marathon.mesos:8080',
            forceUpdate: true,
            docker: 'sergiimatusepam/testworkload-app:0.${BUILD_NUMBER}',
            filename: 'TestWorkload/Marathon-templates/testworkload-app.json')
    }
}