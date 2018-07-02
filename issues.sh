#!/bin/bash -e

dir=$(dirname $0)

while getopts o:u:p:t:s:v:c:d: option 
do
    case "${option}"
        in
        o) projectId=${OPTARG};;
        t) token=${OPTARG};;
        u) user=${OPTARG};;
        p) pass=${OPTARG};;
        s) status=${OPTARG};;
        v) versionId=${OPTARG};;
        c) type=${OPTARG};;
        d) numDays=${OPTARG};;
    esac
done

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

if [ "$status" == "" -o "$status" == "null" ];then
    status="open"
fi

if [ "$type" == "" -o "$type" == "null" ];then
    type="all"
fi

versions=$($dir/versions.sh -t $token -o $projectId | jq '.')

if [ "$versionId" == "" -o "$versionId" == "null" ];then
    text=$(echo $versions | jq -r '. | sort_by(-.sortOrder) | to_entries[] | " \(.key)) \(.value.name)"')
    text=" Z) Last 5\n$text"
    echo -e "Choose version:\n\n$text\n\nProject number, followed by [ENTER]:"
    read versionNumber
    if [[ "$versionNumber" == "Z" ]];then
        versionId=$(echo $versions | jq '[. | sort_by(-.sortOrder)[0:4][] | .externalId] ')
    else
        versionId=$(echo $versions | jq --argjson num "$versionNumber" '[. | sort_by(-.sortOrder)[$num].externalId]')
    fi
fi

if [ "$versionId" == "Z" ];then
    versionId=$(echo $versions | jq '[. | sort_by(-.sortOrder)[0:4][] | .externalId] ')
fi
versionName=$(echo $versions | jq --arg id "[\"$versionId\"]" '[.[] | select(.externalId | inside($id) ) | .name]')
versionName=$(echo $versionName | sed 's/"/\\\\\"/g')

startDate=$(date -u -d "00:00:00 $numDays days ago" +%s)
endDate=$(date -u -d "23:59:59" +%s)
externalId=$projectId

query=$(echo '{"query":"query TopIssues($externalId_0:String!,$type_1:IssueType!,$start_2:UnixTimestamp!,$end_3:UnixTimestamp!,$filters_4:IssueFiltersType!,$state_5:IssueState!) {project(externalId:$externalId_0) {crashlytics {_issues1ctixL:issues(synthesizedBuildVersions:{versions},eventType:$type_1,start:$start_2,end:$end_3,state:$state_5,first:15,filters:$filters_4) {edges {node {externalId,createdAt,resolvedAt,title,subtitle,state,type,occurrenceCount,earliestBuildVersion {buildVersion {name}},latestBuildVersion {buildVersion {name}}}}}}}}","variables":{"externalId_0":"{externalId}","type_1":"{type}","start_2":{start},"end_3":{end},"filters_4":{},"state_5":"{status}"}}' | sed "s/{status}/$status/g" | sed "s/{end}/$endDate/g" | sed "s/{start}/$startDate/g" | sed "s/{versions}/$versionName/g" | sed "s/{externalId}/$externalId/g" | sed "s/{type}/$type/g")


data=$(curl -s 'https://api-dash.fabric.io/graphql?relayDebugName=TopIssues' \
-H "Authorization: Bearer $token" \
-H 'Content-Type: application/json' \
--data-binary "$query" --compressed)
 echo $data | jq '[.data.project.crashlytics._issues1ctixL.edges[].node | .earliestBuildVersion = .earliestBuildVersion.buildVersion.name | .latestBuildVersion = .latestBuildVersion.buildVersion.name]'