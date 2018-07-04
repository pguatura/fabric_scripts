#!/bin/bash -e

dir=$(dirname $0)

while getopts o:u:p:t: option 
do
    case "${option}"
        in
        o) projectId=${OPTARG};;
        t) token=${OPTARG};;
        u) user=${OPTARG};;
        p) pass=${OPTARG};;
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

    echo -e "Choose project:\n\n$text\n\nProject number, followed by [ENTER]:"
    read projectNumber
    projectId=$(echo $projects | jq --argjson num "$projectNumber" -r '. | sort_by(.name)[$num].externalId')
fi

if [ "$projectId" == "" -o "$projectId" == "null" ];then
    echo "INVALID PROJECT ID - check usage"
    exit 1
fi

versions=$(curl -s 'https://api-dash.fabric.io/graphql?relayDebugName=Project_route' -H "Authorization: Bearer $token" -H 'Content-Type: application/json' --data-binary "{\"query\":\"query Project_route(\$externalId_0:String!) {project(externalId:\$externalId_0) {id,...F2}} fragment F0 on ProjectVersion {externalId} fragment F1 on Project {externalId} fragment F2 on Project {_versions4zJYbv:versions(first:100,omitVersionsWithNoEvents:true,days:120) {edges {node {externalId,sortOrder,name,...F0}}},...F1}\",\"variables\":{\"externalId_0\":\"$projectId\"}}" --compressed)


if [[ "$versions" == "" ]];then
    echo "ERROR RETRIEVING VERSIONS"
    exit 1
fi

echo $versions  | jq '[.data.project._versions4zJYbv.edges[].node]'