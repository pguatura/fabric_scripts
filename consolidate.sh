#!/bin/bash -e

dir=$(dirname $0)

while getopts f: option 
do
    case "${option}"
        in
        f) filePath=${OPTARG};;
    esac
done

if [ "$filePath" == "" ];then
    echo "NO CONTENT OR FILE"
    exit 1
fi

result="{}"

while read -r p; do
    if [[ "$p" == "" ]];then 
        continue 
    fi
    error=$(echo $p | jq -r '.stacktraces[0].subtitle')
    if [[ "$error" == "" ]];then
        error=$(echo $p | jq -r '.stacktraces[0].title')
    fi
    time=$(echo "$p" | jq -r '.createdAt')
    dateStr=$(echo "$p" | jq -r '.createdAtString')
    version=$(echo "$p" | jq -r '.buildVersionName')
    errorId=$(echo "$error" | cksum | cut -f 1 -d ' ')
    registered=$(echo "$result" | jq --arg error $errorId '. | has($error)')
    errorObj="{}"
    if [[ "$registered" == "false" ]];then
        errorObj=$(echo "{}" | jq --arg version "'$version'" --arg error "$error" --arg timeStr "$dateStr" --arg timestamp "$time"\
        '. += {"error":$error,"time":$timestamp,"timeStr":$timeStr,"versionName":$version, "qtd":0}')
        result=$(echo $result | jq --argjson ad "$errorObj" --arg id $errorId '. +=  {} | .[$id]  += $ad')
    else
        errorObj=$(echo "$result" | jq --arg error $errorId '.[$error]')
    fi
    versionName=$(echo $errorObj | jq -r '.versionName') 
    timestamp=$(echo $errorObj | jq -r '.time') 
    timeStr=$(echo $errorObj | jq -r '.timeStr') 
    if [[ $versionName != *"'$version'"* ]]; then
        versionName="$versionName,'$version'"
    fi
    if (( $time <= $timestamp )); then
        timestamp=$time
        timeStr=$dateStr 
    fi
    qtd=$(($(echo $errorObj | jq -r '.qtd')+1))
    result=$(echo $result | jq --arg qtd "$qtd" --arg id $errorId '.[$id].qtd = $qtd')
    result=$(echo $result | jq --arg timestamp "$timestamp" --arg id $errorId '.[$id].time = $timestamp')
    result=$(echo $result | jq --arg timestr "$timeStr" --arg id $errorId '.[$id].timeStr = $timestr')
    result=$(echo $result | jq --arg versionName "$versionName" --arg id $errorId '.[$id].versionName = $versionName')
done < $filePath
echo $result | jq -r '[.[] | select(has("error"))]'
