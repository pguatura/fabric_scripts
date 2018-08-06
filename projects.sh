#!/bin/bash -e

dir=$(dirname $0)

while getopts u:p:t: option 
do
    case "${option}"
        in
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

result=$(curl -s 'https://api-dash.fabric.io/graphql?relayDebugName=Sidebar_route' -H "Authorization: Bearer $token" -H 'Content-Type: application/json' --data-binary '{"query":"query Sidebar_route {currentAccount {...F2}} fragment F0 on Project {name,identifier,platform} fragment F1 on Account {_projects4cqQId:projects(first:400) {edges {node {externalId,name,platform,...F0}}}} fragment F2 on Account {...F1}","variables":{}}' --compressed)

echo $result

# echo $result | jq -r '[.data.currentAccount._projects4cqQId.edges[].node]'