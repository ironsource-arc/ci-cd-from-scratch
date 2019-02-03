#!groovy?

def call(text, channel) {
    def slackURL = 'https://hooks.slack.com/services/xxxxxxxxx/xxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxx'
    def payload = JsonOutput.toJson([text  : text,
                                    channel   : channel,
                                    username  : "jenkins",
                                    icon_emoji: ":jenkins:"])
    sh "curl -X POST --data-urlencode \'payload=${payload}\' ${slackURL}"
}
