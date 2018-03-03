#!/bin/bash
# ConfigMap POC
# Mike Battles (mbattles@redhat.com) - 03/03/18
#
# Process Configmap Process File - demonstrates how to create a dummy random file and pass it in as
# a parameter into the oc apply function

INPUT_FILE=file.txt
TEMPLATE_FILE=configmap-poc-template.yml

# This method of passing parameters into the template only supports files up to 47K.
# Files up to 1M in size can be added via "oc secret new"
dd if=/dev/urandom of=${INPUT_FILE} bs=1024 count=47
echo "TEST_FILE_BASE64='`cat ${INPUT_FILE}| base64 -w 0`'" > params

# "oc apply" will perform a 3-way diff to apply the latest changes while keeping manual edits via the CLI/UI
# See https://www.youtube.com/watch?v=CW3ZuQy_YZw
oc process --param-file=params -f ${TEMPLATE_FILE} | oc apply -f -

# Alternatively, instead of using a param file, you can specify the parameters directly:
# oc process -p TEST_FILE_BASE64="`cat ${INPUT_FILE} | base64`" -f ${TEMPLATE_FILE} | oc apply -f -

# Finally, if you aren't interested in files you can omit that entirely and use the default file:
# oc process -f ${TEMPLATE_FILE} | oc apply -f -


# this pod does not have a proper liveiness probe, so it will wait 30 sec before terminating
# we can bypass that by scaling down and force killing
oc scale --replicas=0 dc/configmap-poc
oc delete pod -l app=configmap-poc --grace-period=0 --force

oc rollout latest dc/configmap-poc
oc scale --replicas=1 --timeout=30s dc/configmap-poc

echo -e "\n\nGenerated File checksum: ${INPUT_FILE} \n"
sha256sum ${INPUT_FILE}

POD=`oc get pod -l app=configmap-poc -o name`

echo -e "\n\nTailing ${POD}.  Output will repeat every 30 seconds.  CTRL+C to stop \n\n"
sleep 5
oc logs -f $POD
