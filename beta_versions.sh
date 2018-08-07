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
    data=$($dir/login.sh $user $pass true)
    echo "TOKEN: " $(echo $data | awk '{ print $3 }') 
else
    data=$($dir/login.sh -t $token -c true)
fi
developer=$(echo $data | awk '{ print $1 }')
session=$(echo $data | awk '{ print $2 }')
token=$(echo $data | awk '{ print $3 }')

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
    echo "PROJECT: $projectId" 
fi

if [ "$projectId" == "" -o "$projectId" == "null" ];then
    echo "INVALID PROJECT ID - check usage"
    exit 1
fi

project=$($dir/project_info.sh -t $token -o $projectId | jq '.')

org=$(echo $project | jq -r '.orgId')

releases=$(curl -s "https://fabric.io/api/v2/organizations/$org/apps/$projectId/beta_distribution/releases?do_not_create=true" \
-H "Cookie: _fabric_session=$session;" \
 -H "X-CRASHLYTICS-DEVELOPER-TOKEN: $developer" \
 --compressed)
 echo $releases | jq -r '[.instances[] | select(.build_version.display_version | contains("-RELEASE")) | .build_version = .build_version.display_version][0:30] | to_entries[] | "\(.value.build_version)\n\n\(.value.release_notes_summary)\n\n============================================\n"'