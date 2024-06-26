#!/bin/bash
# // Copyright (c) 2024 - Tony Davis and Evan Rogers

#process to pull performance metrics from Appneta API continuously

if [ -n "$appT" ]; then
    read -a appneta_token <<< "$appT"
else
    appneta_token=()
fi

# Read appneta_root_url array if appURL has a value
if [ -n "$appURL" ]; then
    read -a appneta_root_url <<< "$appURL"
else
    appneta_root_url=()
fi

instance_count="${#appneta_token[@]}"

if [ "$appneta_token" != "none" ]; then
  while true
  do
      for ((l=0; l<$instance_count; l++))
      do
          pathSummary=$(curl -s -X GET -H "Authorization: Token ${appneta_token["$l"]}" -H "Accept: application/json" 'https://'${appneta_root_url["$l"]}'/api/v3/path')
          pathStatus=$(curl -s -X GET -H "Authorization: Token ${appneta_token["$l"]}" -H "Accept: application/json" 'https://'${appneta_root_url["$l"]}'/api/v3/path/status')
          webAppSummary=$(curl -s -X GET -H "Authorization: Token ${appneta_token["$l"]}" -H "Accept: application/json" 'https://'${appneta_root_url["$l"]}'/api/v3/webApplication')
          webAppAll=$(curl -s -X GET -H "Authorization: Token ${appneta_token["$l"]}" -H "Accept: application/json" 'https://'${appneta_root_url["$l"]}'/api/v3/webPath/data')
          path_all=$(curl -s -X GET -H "Authorization: Token ${appneta_token["$l"]}" -H "Accept: application/json" 'https://'${appneta_root_url["$l"]}'/api/v3/path/data')

          #path summary variable creation
          pathOrgId=($(echo "$pathSummary" | jq -r '.[].orgId'))
          pathName=($(echo "$pathSummary" | jq -r '.[].target'))
          pathID=($(echo "$pathSummary" | jq -r '.[].id'))
          path_applianceName=($(echo "$pathSummary" | jq -r '.[].sourceAppliance | gsub(" "; "_")'))
          appliance_networkType=($(echo "$pathSummary" | jq -r '.[].networkType'))
          appliance_ispName=($(echo "$pathSummary" | jq -r '.[].ispName | @sh | sub(" "; "_";"g")')) && appliance_ispName=(${appliance_ispName[@]//\'/})
          appliance_connectionType=($(echo "$pathSummary" | jq -r '.[].connectionType'))
          appliance_vpn=($(echo "$pathSummary" | jq -r '.[].vpn'))
          pathName_count="${#pathName[@]}"
          pathTagCategory=($(echo "$pathSummary" | jq '.[].tags[0].category')) && pathTagCategory=("${pathTagCategory[@]//\"/}")
          pathTagValue=($(echo "$pathSummary" | jq '.[].tags[0].value')) && pathTagValue=("${pathTagValue[@]//\"/}")
          pathStatus=($(echo "$pathStatus" | jq -r '.[].status'))

          webAppId=($(echo "$webAppSummary" | jq -r '.[].id'))
          webAppId_count="${#webAppId[@]}"

          webAppAll=$(cat <<< "$(echo "$webAppAll" | jq 'sort_by(.webPathId)')")
          webAppAll=$(cat <<< "$(echo "$webAppAll" | jq '.[].milestones[] |= {networkTiming: [.["networkTiming"][-1]], serverTiming: [.["serverTiming"][-1]], browserTiming: [.["browserTiming"][-1]], apdexScore: [.["apdexScore"][-1]], totalTime: [.["totalTime"][-1]], basePageSize: [.["basePageSize"][-1]], statusCode: [.["statusCode"][-1]]} | .[].milestones |= map(select(any(.[])))')")

          for ((w=0; w<$webAppId_count; w++))
          do
              webPathData=$(curl -s -X GET -H "Authorization: Token ${appneta_token[$l]}" -H "Accept: application/json" "https://${appneta_root_url[$l]}/api/v3/webApplication/${webAppId[$w]}/monitor")
              webPathCount=$(echo "$webPathData" | jq 'map(select(.id)) | length')
              for ((k=0; k<$webPathCount; k++))
              do
                webPathOrgId=($(echo "$webPathData" | jq -r '.['$k'].orgId'))
                webPathId=($(echo "$webPathData" | jq -r '.['$k'].id'))
                applianceName=($(echo "$webPathData" | jq -r '.['$k'].location.applianceName | gsub(" "; "_")'))
                applianceId=($(echo "$webPathData" | jq -r '.['$k'].location.applianceId'))
                locationLocality=($(echo "$webPathData" | jq -r '.['$k'].location.location.locality | @sh | sub(" "; "_";"g")' | sed "s/'//g"))
                locationAdminAreaLevelOne=($(echo "$webPathData" | jq -r '.['$k'].location.location.adminAreaLevelOne | @sh | sub(" "; "_";"g")' | sed "s/'//g"))
                locationAdminAreaLevelTwo=($(echo "$webPathData" | jq -r '.['$k'].location.location.adminAreaLevelTwo | @sh | sub(" "; "_";"g")' | sed "s/'//g"))
                locationCountry=($(echo "$webPathData" | jq -r '.['$k'].location.location.country | @sh | sub(" "; "_";"g")' | sed "s/'//g"))
                userFlowName=($(echo "$webPathData" | jq -r '.['$k'].userFlow.name' |  sed 's/[^a-zA-Z0-9]//g'))
                webAppName=($(echo "$webPathData" | jq -r '.['$k'].webPathConfig.webAppName | @sh | sub(" "; "_";"g")'))
                webPathWebAppId=($(echo "$webPathData" | jq -r '.['$k'].webPathConfig.webAppId | @sh | sub(" "; "_";"g")'))
                webAppName=(${webAppName[@]//\'/})
                webPathId_status=($(echo "$webPathData" | jq -r '.['$k'].statusWithMuted | @sh | sub(" "; "_";"g")')) && webPathId_status=(${webPathId_status[@]//\"/}) && webPathId_status=(${webPathId_status[@]//\'/})
                webAppTarget=($(echo "$webPathData" | jq -r '.['$k'].target.url | @sh | sub("https://"; "";"g") | sub("http://"; "";"g")')) && webAppTarget=(${webAppTarget[@]//\:*/}) && webAppTarget=(${webAppTarget[@]//\'/}) && webAppTarget=(${webAppTarget[@]//\//})

              webAppAll=$(jq --arg webPathId "$webPathId" \
                     --arg webPathOrgId "$webPathOrgId" \
                     --arg applianceName "$applianceName" \
                     --arg applianceId "$applianceId" \
                     --arg webAppName "$webAppName" \
                     --arg userFlowName "$userFlowName" \
                     --arg webAppTarget "$webAppTarget" \
                     --arg webPathId_status "$webPathId_status" \
                     --arg locality "$locationLocality" \
                     --arg adminAreaLevelOne "$locationAdminAreaLevelOne" \
                     --arg adminAreaLevelTwo "$locationAdminAreaLevelTwo" \
                     '
                map(if .webPathId == ($webPathId | tonumber) then . + {"webPathOrgId": $webPathOrgId, "applianceName": $applianceName, "applianceId": $applianceId,  "appName": $webAppName, "userFlowName": $userFlowName, "webUrlTarget": $webAppTarget , "webPathStatus": $webPathId_status, "locality": $locality, "locationAdminAreaLevelOne": $adminAreaLevelOne, "locationAdminAreaLevelTwo": $adminAreaLevelTwo} else . end)
                ' <<< "$webAppAll")
            done
          done
          echo "$webAppAll" > /data/webApp_all_"$l".json
          path_all=$(cat <<< "$(echo "$path_all" | jq 'sort_by(.pathId)')")
          path_all=$(cat <<< "$(echo "$path_all" | jq '.[].data.totalCapacity |= [.[-1]] | .[].data.utilizedCapacity |= [.[-1]] | .[].data.availableCapacity |= [.[-1]] | .[].data.latency |= [.[-1]] | .[].data.dataJitter |= [.[-1]] | .[].data.dataLoss |= [.[-1]] | .[].data.voiceJitter |= [.[-1]] | .[].data.voiceLoss |= [.[-1]] | .[].data.mos |= [.[-1]] | .[].data.rtt |= [.[-1]] | .[].dataInbound.totalCapacity |= [.[-1]] | .[].dataInbound.utilizedCapacity |= [.[-1]] | .[].dataInbound.availableCapacity |= [.[-1]] | .[].dataInbound.dataJitter |= [.[-1]] | .[].dataInbound.dataLoss |= [.[-1]] | .[].dataInbound.voiceJitter |= [.[-1]] | .[].dataInbound.voiceLoss |= [.[-1]] | .[].dataInbound.mos |= [.[-1]] | .[].dataInbound.rtt |= [.[-1]] | .[].dataInbound.latency |= [.[-1]] | .[].dataOutbound.totalCapacity |= [.[-1]] | .[].dataOutbound.utilizedCapacity |= [.[-1]] | .[].dataOutbound.availableCapacity |= [.[-1]] | .[].dataOutbound.dataJitter |= [.[-1]] | .[].dataOutbound.dataLoss |= [.[-1]] | .[].dataOutbound.voiceJitter |= [.[-1]] | .[].dataOutbound.voiceLoss |= [.[-1]] | .[].dataOutbound.mos |= [.[-1]] | .[].dataOutbound.rtt |= [.[-1]] | .[].dataOutbound.latency |= [.[-1]]')")

          for ((p=0; p<$pathName_count; p++))
          do
              pathOrgId_temp=${pathOrgId[$p]}
              pathName_temp=${pathName[$p]}
              pathStatus_temp=${pathStatus[$p]}
              pathTagCategory_temp=${pathTagCategory[$p]}
              pathTagValue_temp=${pathTagValue[$p]}
              path_applianceName_temp=${path_applianceName[$p]}
              appliance_connectionType_temp=${appliance_connectionType[$p]}
              appliance_ispName_temp=${appliance_ispName[$p]}
              appliance_networkType_temp=${appliance_networkType[$p]}
              appliance_vpn_temp=${appliance_vpn[$p]}
              path_all="$(jq '.['$p'] += {"pathOrgId": "'"$pathOrgId_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"applianceName": "'"$path_applianceName_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"connectionType": "'"$appliance_connectionType_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"ispName": "'"$appliance_ispName_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"networkType": "'"$appliance_networkType_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"vpn": "'"$appliance_vpn_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"pathUrlTarget": "'"$pathName_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"pathStatus": "'"$pathStatus_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"path_tag_category": "'"$pathTagCategory_temp"'"}' <<< "$path_all")"
              path_all="$(jq '.['$p'] += {"path_tag_value": "'"$pathTagValue_temp"'"}' <<< "$path_all")"
          done
          echo "$path_all" > /data/path_all_"$l".json
      done
      bash /initial/influx_bucket_creation.sh
      sleep 120
  done
fi