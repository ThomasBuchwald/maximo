#!/bin/bash

echo "================ OCP DEPLOY START ================"

 wget -nv https://raw.githubusercontent.com/ThomasBuchwald/maximo/$branchName/src/machinesets/db2.yaml -O /tmp/OCPInstall/db2.yaml
 wget -nv https://raw.githubusercontent.com/ThomasBuchwald/maximo/$branchName/src/machinesets/ocs.yaml -O /tmp/OCPInstall/ocs.yaml


#Setup Zone 1
 export zone=1

if [ "$installCP4D" == "Y" ] || [ "$installCP4D" == "Yes" ] || [ "$installCP4D" == "y" ]
then
    #Setup DB2 MachineSet
    export numReplicas=1
    envsubst < /tmp/OCPInstall/db2.yaml > /tmp/OCPInstall/QuickCluster/db2.yaml
    sudo -E /tmp/OCPInstall/oc apply -f /tmp/OCPInstall/QuickCluster/db2.yaml

fi

if [ "$installOCS" == "Y" ] || [ "$installOCS" == "Yes" ] || [ "$installOCS" == "y" ]
then
    #Setup OCS MachineSet
    export numReplicas=2
    envsubst < /tmp/OCPInstall/ocs.yaml > /tmp/OCPInstall/QuickCluster/ocs.yaml
    sudo -E /tmp/OCPInstall/oc apply -f /tmp/OCPInstall/QuickCluster/ocs.yaml
fi

 #Setup Zone 2
 export zone=2

if [ "$installCP4D" == "Y" ] || [ "$installCP4D" == "Yes" ] || [ "$installCP4D" == "y" ]
then
    #Setup DB2 MachineSet
    export numReplicas=1
    envsubst < /tmp/OCPInstall/db2.yaml > /tmp/OCPInstall/QuickCluster/db2.yaml
    sudo -E /tmp/OCPInstall/oc apply -f /tmp/OCPInstall/QuickCluster/db2.yaml

fi

if [ "$installOCS" == "Y" ] || [ "$installOCS" == "Yes" ] || [ "$installOCS" == "y" ]
then
    #Setup OCS MachineSet
    export numReplicas=2
    envsubst < /tmp/OCPInstall/ocs.yaml > /tmp/OCPInstall/QuickCluster/ocs.yaml
    sudo -E /tmp/OCPInstall/oc apply -f /tmp/OCPInstall/QuickCluster/ocs.yaml
fi

 #Configure Azure Files Standard
 wget -nv https://raw.githubusercontent.com/ThomasBuchwald/maximo/$branchName/src/storageclasses/azurefiles-standard.yaml -O /tmp/OCPInstall/azurefiles-standard.yaml
 envsubst < /tmp/OCPInstall/azurefiles-standard.yaml > /tmp/OCPInstall/QuickCluster/azurefiles-standard.yaml
 sudo -E /tmp/OCPInstall/oc apply -f /tmp/OCPInstall/QuickCluster/azurefiles-standard.yaml

 #Configure Azure Files Premium
 wget -nv "https://raw.githubusercontent.com/ThomasBuchwald/maximo/$branchName/src/installers/azure_premium_files_deploy.sh" -O /tmp/azure_premium_files_deploy.sh
 chmod +x /tmp/azure_premium_files_deploy.sh
 sudo -E /tmp/azure_premium_files_deploy.sh

 sudo -E /tmp/OCPInstall/oc apply -f https://raw.githubusercontent.com/ThomasBuchwald/maximo/$branchName/src/storageclasses/persistent-volume-binder.yaml

 #Set Global Registry Config
 sudo -E /tmp/OCPInstall/oc extract secret/pull-secret -n openshift-config --keys=.dockerconfigjson --to=. --confirm
 export encodedEntitlementKey=$(echo cp:$ENTITLEMENT_KEY | base64 -w0)
 export emailAddress=$(cat .dockerconfigjson | jq -r '.auths["cloud.openshift.com"].email')
 jq '.auths |= . + {"cp.icr.io": { "auth" : "$encodedEntitlementKey", "email" : "$emailAddress"}}' .dockerconfigjson > /tmp/OCPInstall/QuickCluster/dockerconfig.json
 envsubst < /tmp/OCPInstall/QuickCluster/dockerconfig.json > /tmp/OCPInstall/QuickCluster/.dockerconfigjson
 sudo -E /tmp/OCPInstall/oc set data secret/pull-secret -n openshift-config --from-file=/tmp/OCPInstall/QuickCluster/.dockerconfigjson

 echo "================ OCP DEPLOY COMPLETE ================"
