#!/usr/bin/env bash
#
# SPDX-License-Identifier: MIT
# (c) 2020 Generali Deutschland Informatik Services GmbH
#

### create systemd service from script #########################################

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

### create script from systemd service #########################################

# This is of course only intended to work on services created by the above
# function (it's like an "undo").

function to_script
{
  local source=$1

  # extract script name from service
  local target=$(grep "Description=Run script" $source)
  if [[ $target =~ ^Description=Run\ script\ (.*)$ ]]; then
    target=$(dirname $(readlink -f $source))/${BASH_REMATCH[1]}

    # put script from comment block into file
    sed -n '/^###PAYLOAD_BEGIN###/,/^###PAYLOAD_END###/{//!p}' $source | cut -c 2- > $target
  else
    echo "error: $source is not a service created by this script"
  fi
}

### check argument and decide what to do #######################################

function main
{
  local file=$1

  local suffix=${file##*.}
  case "$suffix" in
    service) to_script  $file ;;
    *)       to_service $file ;;
  esac
}

### main #######################################################################

if [ -f "$1" ]; then
  main $1
else
  echo "usage: $0 <file>"
  echo ""
  echo "   Create systemd service file from script <file>."
  echo "   If <file> is a systemd service created by this script,"
  echo "   reverse the operation and recreate the original script it."
  echo ""
fi
