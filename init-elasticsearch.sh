#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                     Show this message
  --elasticsearchServerName  Name of server to use (optional)
  --elasticsearchId          Elasticsearch id, default: elasticsearch
  --elasticsearchVersion     Elasticsearch version
  --elasticsearchHost        Elasticsearch host, default: localhost
  --elasticsearchSsl         Elasticsearch SSL (true/false), default: false
  --elasticsearchPort        Elasticsearch port, default: 9200
  --elasticsearchPrefix      Elasticsearch prefix, default: magento
  --elasticsearchUser        User name if behind basic auth
  --elasticsearchPassword    Password if behind basic auth

Example: ${scriptName} --elasticsearchVersion 7.9 --elasticsearchPort 9200
EOF
}

elasticsearchServerName=
elasticsearchId=
elasticsearchVersion=
elasticsearchHost=
elasticsearchSsl=
elasticsearchPort=
elasticsearchPrefix=
elasticsearchUser=
elasticsearchPassword=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${elasticsearchVersion}" ]]; then
  >&2 echo "No Elasticsearch version specified!"
  exit 1
fi

if [[ -z "${elasticsearchHost}" ]]; then
  elasticsearchHost="localhost"
fi

if [[ -z "${elasticsearchSsl}" ]]; then
  elasticsearchSsl="false"
fi

if [[ -z "${elasticsearchPort}" ]]; then
  elasticsearchPort="9200"
fi

if [[ -z "${elasticsearchPrefix}" ]]; then
  elasticsearchPrefix="magento"
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if [[ -z "${elasticsearchServerName}" ]]; then
  elasticsearchServerName=
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if { [[ "${elasticsearchHost}" == "localhost" ]] || [[ "${elasticsearchHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      elasticsearchServerName="${server}"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${elasticsearchHost}" ]]; then
        elasticsearchServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${elasticsearchServerName}" ]]; then
  echo ""
  echo "No server found for Elasticsearch host!"

  addServer=0
  echo ""
  echo "Do you wish to add a new server with the host name ${elasticsearchHost}?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) addServer=1; break;;
      No ) break;;
    esac
  done

  if [[ "${addServer}" == 1 ]]; then
    echo ""
    echo "Please specify the server name, followed by [ENTER]:"
    read -r -i "elasticsearch_server" -e elasticsearchServerName

    if [[ -z "${elasticsearchServerName}" ]]; then
      echo "No elasticsearch name specified!"
      exit 1
    fi

    sshUser=$(whoami)
    echo ""
    echo "Please specify the SSH user, followed by [ENTER]:"
    read -r -i "${sshUser}" -e sshUser

    if [[ -z "${sshUser}" ]]; then
      echo "No SSH user specified!"
      exit 1
    fi

    "${currentPath}/init-server.sh" \
      --name "${elasticsearchServerName}" \
      --type ssh \
      --host "${elasticsearchHost}" \
      --sshUser "${sshUser}"
  fi
fi

if [[ -z "${elasticsearchServerName}" ]]; then
  echo "No server found for Elasticsearch host!"
  exit 1
fi

if [[ -z "${elasticsearchId}" ]]; then
  elasticsearchId="${elasticsearchServerName}_elasticsearch"
fi

ini-set "${currentPath}/../env.properties" yes "${elasticsearchServerName}" elasticsearch "${elasticsearchId}"
ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" version "${elasticsearchVersion}"
ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" ssl "${elasticsearchSsl}"
ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" port "${elasticsearchPort}"
ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" prefix "${elasticsearchPrefix}"
if [[ -n "${elasticsearchUser}" ]] && [[ -n "${elasticsearchPassword}" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" user "${elasticsearchUser}"
  ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" password "${elasticsearchPassword}"
fi
