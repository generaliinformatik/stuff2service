#!/usr/bin/env bash
#
# SPDX-License-Identifier: MIT
# (c) 2019 Generali Informatik
#

function to_service
{
  local source=$1
  
  local target=$(dirname $(readlink -f $source))/$(basename $1)
  target=${target%.*}.service   # remove any suffix and add '.service'

cat << EOF >$target
#
# systemd service created by script2service.sh
# https://github.com/generaliinformatik/stuff2service
#

[Unit]
Description=Run script PLACEHOLDER_SCRIPT

[Service]
Type=oneshot
# extract payload
ExecStartPre=/bin/bash -c "sed -n '/^###PAYLOAD_BEGIN###$/,/^###PAYLOAD_END###$/{//!p}' /etc/systemd/system/%n | cut -c 2- > /tmp/PLACEHOLDER_SCRIPT"
ExecStartPre=/usr/bin/chmod 755 /tmp/PLACEHOLDER_SCRIPT
ExecStart=/tmp/PLACEHOLDER_SCRIPT
ExecStartPost=/usr/bin/rm /tmp/PLACEHOLDER_SCRIPT

###PAYLOAD_BEGIN###
###PAYLOAD_END###
EOF

  # prefix lines with hash | insert lines into target file
  sed -e 's/^/#/' $source  | sed -i '/^###PAYLOAD_BEGIN/r /dev/stdin' $target

  # add newline if source did not end with one
  if [ $(tail -c 1 $source | wc -l) -eq 0 ]; then
    sed -i 's/###PAYLOAD_END###$/\n###PAYLOAD_END###/' $target
  fi
  
  # replace placeholders with script name
  local source_filename=$(basename $source)
  sed -i "s/PLACEHOLDER_SCRIPT/${source_filename//\//\\/}/" $target
}

function to_script
{
  local source=$1

  local target=$(grep "Description=Run script" $source)
  if [[ $target =~ ^Description=Run\ script\ (.*)$ ]]; then
    target=$(dirname $(readlink -f $source))/${BASH_REMATCH[1]}
  fi

  sed -n '/^###PAYLOAD_BEGIN###/,/^###PAYLOAD_END###/{//!p}' $source | cut -c 2- > $target
}

function main
{
  local file=$1

  local suffix=${file##*.}
  case "$suffix" in
    service) to_script  $file ;;
    *)       to_service $file ;;
  esac
}

### MAIN #######################################################################

if [ -f "$1" ]; then
  main $1
else
  echo "usage: $0 <filename>"
fi
