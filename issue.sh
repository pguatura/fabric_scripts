#!/bin/bash -e

dir=$(dirname $0)

while getopts o:u:p:t:i:d:C: option 
do
    case "${option}"
        in
        o) projectId=${OPTARG};;
        t) token=${OPTARG};;
        u) user=${OPTARG};;
        p) pass=${OPTARG};;
        i) issueId=${OPTARG};;
        d) numDays=${OPTARG};;
        C) consolidate=${OPTARG};;
    esac
done

if [[ "$consolidate" == "" ]];then
    consolidate="false"
fi

if [[ "$token" == "" ]];then
    token=$($dir/login.sh $user $pass)
fi

if [ "$token" == "" -o "$token" == "null" ];then
    echo "INVALID TOKEN - check usage"
    exit 1
fi

if [[ "$projectId" == "" ]];then
    projects=$($dir/projects.sh -t $token | jq '.')
    text=$(echo $projects | jq -r '. | sort_by(.name) | to_entries[] | " \(.key)) (\(.value.platform)) \(.value.name) - \(.value.identifier)"')
    text="$text"
    echo -e "Choose project:\n\n$text\n\nProject number, followed by [ENTER]:"
    read projectNumber
    projectId=$(echo $projects | jq --argjson num "$projectNumber" -r '. | sort_by(.name)[$num].externalId')
fi

if [ "$projectId" == "" -o "$projectId" == "null" ];then
    echo "INVALID PROJECT ID - check usage"
    exit 1
fi

if [[ "$issueId" == "" ]];then
    issues=$($dir/issues.sh -t $token -o $projectId -v Z | jq '.')
    text=$(echo $issues | jq -r '. | sort_by(-.createdAt) | to_entries[] | " \(.key)) (\(.value.state)/\(.value.type)) [ \(.value.occurrenceCount) ] \(.value.title) - \(.value.subtitle)"')
    text="$text"
    echo -e "Choose issue:\n\n$text\n\nIssue number, followed by [ENTER]:"
    read issueNumber
    issueId=$(echo $issues | jq --argjson num "$issueNumber" -r '. | sort_by(-.createdAt)[$num].externalId')
fi

versions=$($dir/versions.sh -t $token -o $projectId)
startDate=$(($(date -u -d "00:00:00 $numDays days ago" +%s)*1000))
endDate=$(($(date -u -d "23:59:59" +%s)*1000))


started=false

while [[ $result != ""  || "$started" == "false" ]]; do
    started=true
    if [[ "$result" == "" ]];then
        params="externalId:\\\"latest\\\",issueId:\\\"$issueId\\\""
        variables=" \"externalId_0\":\"$projectId\" "
        methodParams=" \$externalId_0:String! "
    else
        params="issueId:\\\"$issueId\\\",pageTime:\$pageTime_1, pageDirection:\$pageDirection_2"
        variables="\"externalId_0\":\"$projectId\", \"pageTime_1\":$createdAt,\"pageDirection_2\":\"previous\""
        methodParams=" \$externalId_0:String! , \$pageTime_1:UnixMsTimestamp! , \$pageDirection_2:CrashSessionPaginationDirection! "
    fi

    result=$(curl -s 'https://api-dash.fabric.io/graphql?relayDebugName=SingleSession' \
        -H "Authorization: Bearer $token" -H 'Content-Type: application/json' \
        --data-binary "{\"query\":\"query SingleSession($methodParams) \
        {project(externalId:\$externalId_0) {crashlytics \
        {_session1SEzhR:session($params) \
        {externalId,createdAt,buildVersionId, \
        stacktraces \
        {exceptions {caption {title,subtitle}}}}}}}\", \
        \"variables\":{$variables}}" --compressed)
    result=$(echo "$result" | jq '.data.project.crashlytics[]  | select(has("externalId"))')
    createdAt=$(echo "$result" | jq '.createdAt')
    if [[ "$createdAt" == "" ]];then
        break
    fi  
    if [[ $startDate -gt $createdAt ]];then
        break
    fi
    formatteddDate=$(($createdAt/1000))
    formatteddDate=$(date -d @$formatteddDate +"%Y-%m-%d %H:%M:%S")
    buildVersion=$(echo "$result" | jq -r '.buildVersionId')
    versionName=$(echo $versions | jq --arg id $buildVersion -r '.[] | select(.externalId == $id) | .name' )
    echo $result | jq --argjson tForm "{\"createdAtString\":\"$formatteddDate\",\"buildVersionName\":\"$versionName\"""}" '. | .stacktraces = ([.stacktraces.exceptions[] | .caption]) | . += . + $tForm' \
    | jq
    
 done