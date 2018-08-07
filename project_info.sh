#!/bin/bash -e

dir=$(dirname $0)

while getopts u:p:t:o: option 
do
    case "${option}"
        in
        t) token=${OPTARG};;
        u) user=${OPTARG};;
        p) pass=${OPTARG};;
        o) projectId=${OPTARG};;
    esac
done

if [[ "$token" == "" ]];then
    token=$($dir/login.sh $user $pass)
    echo "TOKEN: $token"
fi

if [ "$token" == "" -o "$token" == "null" ];then
    echo "INVALID TOKEN - check usage"
    exit 1
fi

if [[ "$projectId" == "" ]];then
    echo "INVALID PROJECT - check usage"
    exit 1
fi


result=$(curl -s 'https://api-dash.fabric.io/graphql?relayDebugName=Sidebar_route' \
-H "Authorization: Bearer $token" \
-H 'Content-Type: application/json' \
--data-binary '{"query":"query Sidebar_route {currentAccount {...F2}} fragment F0 on Project {name,identifier,platform,organization {alias,name,id}} fragment F1 on Account {_projects4cqQId:projects(first:400) {edges {node {externalId,name,platform,...F0}}}} fragment F2 on Account {...F1}","variables":{}}' --compressed)

project=$(echo $result | jq -r ".data.currentAccount._projects4cqQId.edges[].node | select(.externalId | contains(\"$projectId\"))")

organizationId=$(echo $project | jq -r '.organization.id' | base64 -d | cut -d ":" -f 2)

echo $project | jq --arg org $organizationId -r '. + {orgId: ($org)}'