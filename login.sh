#!/bin/bash -e

user=$1
pass=$2
complete=$3
while getopts t:c: option 
do  
    case "${option}"
        in
        t) token=${OPTARG};;
        c) complete=${OPTARG};;
    esac
done


if [[ "$complete" == "" ]];then
    complete=false
fi

get_fabric_session (){
    response=$1
    count=0
    session=""
    while read -r line; do
        if [[ $line == *"_fabric_session"*  ]] ; then
            cookies=$( echo $line  | sed "s/Set-Cookie://g" | tr ";" "\n" | sed "s/^\s//g")
            while read -r line; do
                if [[ $line == "_fabric_session"*  ]] ; then
                    session=$( echo $line  | sed "s/_fabric_session=//g")
                    break
                fi
            done <<< "$cookies"
            break
        fi
    done <<< "$response"
    echo $session
}
get_body (){
    response=$1
    body=""
    while read -r line; do
        if [[ $line == "{"*  ]] ; then
            body=$line
            break;
        fi
    done <<< "$response"
    echo $body
}

urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

test=$(curl -sD - "https://fabric.io/login?utm_campaign=fabric-marketing&utm_medium=natural")
session=$(get_fabric_session "$test")
csrf=""
while read -r line; do
  if [[ $line == *"csrf-token"*  ]] ; then
    csrf=$(echo $line | grep -o 'content="[A-Za-z0-9\/=\+-]*"' | sed 's/content="\(.*\)"/\1/g')
    break
  fi
done <<< $test

result=$(curl -sD - 'https://fabric.io/api/v2/session' -H "Cookie: _ga=GA1.2.772191058.1530530554; _gid=GA1.2.358657458.1530530554; _fabric_session=$session; G_ENABLED_IDPS=google" -H 'Origin: https://fabric.io' -H 'Accept-Encoding: gzip, deflate, br' -H "X-CSRF-Token: $csrf" -H 'Accept-Language: en-US,en;q=0.9' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://fabric.io/login?utm_campaign=fabric-marketing&utm_medium=natural' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'X-CRASHLYTICS-DEVELOPER-TOKEN: 0bb5ea45eb53fa71fa5758290be5a7d5bb867e77' --data "email=$(urlencode $user)&password=$(urlencode $pass)" --compressed)
session2=$(get_fabric_session "$result")
if [[ "$token" == "" ]]; then
    config=$(curl -sD - 'https://fabric.io/api/v2/client_boot/config_data' -H "Cookie: _ga=GA1.2.772191058.1530530554; _gid=GA1.2.358657458.1530530554; G_ENABLED_IDPS=google; notification_key=3KtaL4i2TKhIyJibQHhy4O1dmrdEOiZ88DmC1hxjI%3D; _gat=1; _fabric_session=$session2" -H 'Accept-Encoding: gzip, deflate, br' -H "X-CSRF-Token: $csrf" -H 'Accept-Language: en-US,en;q=0.9' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.139 Safari/537.36' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: https://fabric.io/login' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'X-CRASHLYTICS-DEVELOPER-TOKEN: 0bb5ea45eb53fa71fa5758290be5a7d5bb867e77' --compressed )
    f_session=$(get_fabric_session "$config")
    data=$(get_body "$config")
    token=$(echo $data | jq -r '.current_account.frontend_access_token')
fi
developer="0bb5ea45eb53fa71fa5758290be5a7d5bb867e77"
if [[ $complete == "true"  ]] ; then
    echo "$developer $f_session $token"
else
    echo $token
fi
