#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help              Show this message
  --systemName        System name, default: system
  --installId         Installation id, default: install
  --magentoVersion    Magento version
  --magentoEdition    Magento edition, default: community
  --magentoMode       Magento mode, default: developer
  --cryptKey          Crypt key, default: 59d6bece52542f48fd629b78e7921b39
  --composerUser      Magento composer user, default: d661c529da2e737d5b514bf1ff2a2576
  --composerPassword  Magento composer password, default: b969ec145c55b8a8248ca8541160fe89
  --adminPath         Admin path (optional)
  --mailAddress       Mail address for all system mails

Example: ${scriptName} --magentoVersion 2.3.7 --magentoEdition community --magentoMode production
EOF
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

systemName=
installId=
magentoVersion=
magentoEdition=
magentoMode=
cryptKey=
composerUser=
composerPassword=
adminPath=
mailAddress=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

if [[ -z "${installId}" ]]; then
  installId="install"
fi

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${magentoEdition}" ]]; then
  magentoEdition="community"
fi

if [[ -z "${magentoMode}" ]]; then
  magentoMode="developer"
fi

if [[ "${magentoMode}" != "default" ]] && [[ "${magentoMode}" != "production" ]] && [[ "${magentoMode}" != "developer" ]]; then
  echo "Invalid Magento mode (default, developer or production) specified!"
  exit 1
fi

if [[ -z "${cryptKey}" ]]; then
  cryptKey="59d6bece52542f48fd629b78e7921b39"
fi

if [[ -z "${composerUser}" ]]; then
  if [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 1 ]]; then
    composerUser="397680c997623334a6da103dbfd2d3c3"
  else
    composerUser="d661c529da2e737d5b514bf1ff2a2576"
  fi
fi

if [[ -z "${composerPassword}" ]]; then
  if [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 1 ]]; then
    composerPassword="a9ccf6ec2e552892f8a510b4b0e1edd5"
  else
    composerPassword="b969ec145c55b8a8248ca8541160fe89"
  fi
fi

if [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 1 ]]; then
  composerServer="https://composer.tofex.de"
else
  composerServer="https://repo.magento.com"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" no "${systemName}" install "${installId}"
ini-set "${currentPath}/../env.properties" yes "${installId}" repositories "composer|${composerServer}|${composerUser}|${composerPassword}"
ini-set "${currentPath}/../env.properties" yes "${installId}" magentoVersion "${magentoVersion}"
ini-set "${currentPath}/../env.properties" yes "${installId}" magentoEdition "${magentoEdition}"
ini-set "${currentPath}/../env.properties" yes "${installId}" magentoMode "${magentoMode}"
if [[ -n "${cryptKey}" ]] && [[ "${cryptKey}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${installId}" cryptKey "${cryptKey}"
fi
if [[ -n "${adminPath}" ]] && [[ "${adminPath}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${installId}" adminPath "${adminPath}"
fi
if [[ -n "${mailAddress}" ]] && [[ "${mailAddress}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${installId}" mailAddress "${mailAddress}"
fi
