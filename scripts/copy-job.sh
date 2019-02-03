CRUMB=$(curl -s 'http://admin:35d0xxxxxxxxxxxxxxxxxxxxxxxx3375b07c@<%your jenkins url%>:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
echo $CRUMB
curl -s https:///<YOUR_NAME>:35d0xxxxxxxxxxxxxxxxxxxxxxxx3375b07c@jenkins-route.com/job/<%job name%>/config.xml | curl -X POST 'http:///admin:35d0xxxxxxxxxxxxxxxxxxxxxxxx3375b07c@<%your jenkins url%>:8080/createItem?name=<%job name%>' -H "$CRUMB" --header "Content-Type: application/xml" -d @-
