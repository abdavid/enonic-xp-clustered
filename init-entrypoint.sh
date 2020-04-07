#!/bin/bash
set -emu -o pipefail

echo "args: $@"

DUMP_FILE="$(echo /init-data/${DUMP_NAME}.zip)"
echo "Loading data dump ${DUMP_FILE} ..."
ls -la /init-data
unzip "${DUMP_FILE}" -d ${XP_HOME}/data/dump/ && mv ${XP_HOME}/data/dump/${DUMP_NAME} ${XP_HOME}/data/dump/from_init && chown -R ${XP_USER} ${XP_ROOT}


exec /launcher.sh &
#exec "$@" &
pid=$!

trap " kill ${pid}; exit 1" INT

SCRIPT_NAME=$(basename $0)


echo "Waiting for Enonic to launch on port 8080..."
while ! curl --fail --silent -o /dev/null localhost:8080; do
  sleep 3
done
echo "Enonic launched, running data import for $0"

exec /usr/bin/enonic dump load -a su:fivetimes05 -d from_init -f &

echo "${SCRIPT_NAME} - Waiting for child (pid ${pid}) to exit"
trap " kill ${pid}; exit 1" INT
wait
