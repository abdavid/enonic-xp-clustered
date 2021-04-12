#!/bin/bash
set -emu -o pipefail

echo "Moving and chowning configuration files"
cd /tmp-config
cp com.enonic.xp.* system.properties $XP_HOME/config
chown 1337 $XP_HOME/config/*
chown 1337 $XP_HOME/snapshots
chown 1337 $XP_HOME/data
chown -R 1337 $XP_HOME/repo
cd -
echo "Done. Starting Enonic XP server.."

server.sh
