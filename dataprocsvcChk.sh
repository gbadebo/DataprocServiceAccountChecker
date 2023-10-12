#!/bin/bash

while getopts n:r: flag
do
    case "${flag}" in
        n) clustername=${OPTARG};;
        r) location=${OPTARG};;
    esac
done

echo "Clustername: $clustername";
echo "Region: $location";
# read -p 'Enter name of dataproc cluster: ' clustername
# read -p 'Enter region of the dataproc instance (eg: us-central1): ' location
service_account=$(gcloud dataproc clusters describe $clustername --region $location --format='value(config.gceClusterConfig.serviceAccount)')
project_id=$(gcloud dataproc clusters describe $clustername --region $location --format='value(projectId)')
echo $service_account
echo $project_id

# get the network URI to get know if shardvpc s being used
# if networkuri is empty check in subnetworkuri

networkuri=$(gcloud dataproc clusters describe $clustername --region $location --format='value(config.gceClusterConfig.networkUri)')
if [ -z "$networkuri" ]; then
	networkuri=$(gcloud dataproc clusters describe $clustername --region $location --format='value(config.gceClusterConfig.subnetworkUri)')
fi

host_project_id=`echo $networkuri | awk -F'/' '{print $7}'`
echo "hp $host_project_id"
if [ $project_id != $host_project_id ]; then
    is_sharedVPC='True'
else
    is_sharedVPC='False'
fi
echo $networkuri
echo $host_project_id
echo $is_sharedVPC

project_number=$(gcloud projects describe $project_id --format="value(projectNumber)")
default_sa=$project_number-compute@developer.gserviceaccount.com


condition="roles/editor"

echo ""
echo custom SA $service_account
echo ------------configured roles------------------
gcloud projects get-iam-policy $project_id  \
--flatten="bindings[].members" \
--format='table[box,no-heading](bindings.role)' \
--filter="bindings.members:$service_account" | GREP_COLOR='01;32' egrep --color -E $condition'|$'
echo ==============================================

echo ""
echo Default SA $default_sa
echo ------------configured roles------------------
gcloud projects get-iam-policy $project_id  \
--flatten="bindings[].members" \
--format='table[box,no-heading](bindings.role)' \
--filter="bindings.members:$default_sa" | GREP_COLOR='01;32' egrep --color -E $condition'|$'
echo ==============================================



dataproc_agent_sa=service-$project_number@dataproc-accounts.iam.gserviceaccount.com
echo ""
echo Dataproc agent SA $dataproc_agent_sa
echo ------------configured roles------------------
gcloud projects get-iam-policy $project_id  \
--flatten="bindings[].members" \
--format='table[box,no-heading](bindings.role)' \
--filter="bindings.members:$dataproc_agent_sa" | GREP_COLOR='01;32' egrep --color -E $condition'|$'
echo ==============================================


# If sharedVPC, check for computer network user is added in the host project
if [ "$is_sharedVPC" == 'True' ];then

	condition=roles/compute.networkUser

	dataproc_agent_sa=service-$project_number@dataproc-accounts.iam.gserviceaccount.com
	echo ""
	echo Dataproc agent SA $dataproc_agent_sa
	echo ------------configured roles------------------
	gcloud projects get-iam-policy $host_project_id  \
	--flatten="bindings[].members" \
	--format='table[box,no-heading](bindings.role)' \
	--filter="bindings.members:$dataproc_agent_sa" | GREP_COLOR='01;32' egrep --color -E $condition'|$'
	echo ==============================================

	dataproc_cloud_sa=$project_number@cloudservices.gserviceaccount.com
	echo ""
	echo Dataproc cloud SA $dataproc_cloud_sa
	echo ------------configured roles------------------
	gcloud projects get-iam-policy $host_project_id  \
	--flatten="bindings[].members" \
	--format='table[box,no-heading](bindings.role)' \
	--filter="bindings.members:$dataproc_cloud_sa" | GREP_COLOR='01;32' egrep --color -E $condition'|$'
``	echo ==============================================

fi
