#!/bin/bash

CUR_DIR="$(dirname "${BASH_SOURCE}")"
OPENSHIFT_DIR="${CUR_DIR}/openshift"
BASH_DIR="${CUR_DIR}/bash"

# Load functions from other bash scripts
source "${BASH_DIR}/logs.sh"
source "${BASH_DIR}/error.sh"

# Load vars for customizing CI run per application/service
source "${CUR_DIR}/vars.sh"

BIND_ERROR=false
PROVISION_ERROR=false
POD_PRESET_ERROR=false
VERIFY_CI_ERROR=false

RESOURCE_ERROR="${RESOURCE_ERROR:-false}"
BUILD_ERROR="${BUILD_ERROR:-false}"
MAKE_DEPLOY_ERROR="${MAKE_DELOY_ERROR:-false}"
CLUSTER_SETUP_ERROR="${CLUSTER_SETUP_ERROR:-false}"

LOCAL_CI="${LOCAL_CI:-true}"

declare -r color_start="\033["
declare -r color_red="${color_start}0;31m"
declare -r color_yellow="${color_start}0;33m"
declare -r color_green="${color_start}0;32m"
declare -r color_norm="${color_start}0m"

function precheck {
  # Ensure all required parameters are defined
  for r in aws_access_key           \
           aws_secret_key           \
           stack_identifier         \
           aws_region               \
           openshift_namespace; do
    if [ -z "${!r}" ]; then
      echo "Missing required parameter: ${r}"
      missing_params=true
    fi
  done

  if [ "$missing_params" = true ]; then
    echo "Exiting due to missing parameters..."
    exit 1
  fi
}

function provision {
  # Create the desired namespace if it doesn't exist already
  oc new-project ${openshift_namespace}

  # Create AWS service instance from OpenShift template
  oc process -f ${OPENSHIFT_DIR}/${aws_svc_name}.yaml   \
    service_class_name="${aws_svc_service_class_name}"  \
    namespace="${openshift_namespace}"                  \
    stack_identifier="${stack_identifier}"              \
    aws_access_key="${aws_access_key}"                  \
    aws_secret_key="${aws_secret_key}"                  \
    aws_region="${aws_region}" | oc create -f - || PROVISION_ERROR=true

  # Wait for AWS CloudFormation service provision to complete before continuing...
  ${BASH_DIR}/wait-for-resource.sh completed apb ${aws_svc_name} 50 5
  error-check "provision"

  if ${RESOURCE_ERROR}; then
    echo
    echo "One or more resources didn't come up as expected. Exiting..."
    exit 3
  fi
}

function bind {
  print-with-green "Creating binding between ${app_name_pretty} and ${aws_svc_name_pretty}..."

  oc process -f ${OPENSHIFT_DIR}/binding-template.yaml         \
    namespace="${openshift_namespace}"                         \
    bind_credential_name="${bind_credential_name}"             \
    app_name="${app_name}"                                     \
    aws_svc_name="${aws_svc_name}" | oc create -f - || BIND_ERROR=true

  ${OPENSHIFT_DIR}/wait-for-resource.sh create bindings.v1alpha1.servicecatalog.k8s.io ${bind_credential_name} >> /tmp/wait-for-pods-log 2>&1
  error-check "bind"
}

function bind-credential-check {
  RETRIES=10
  for x in $(seq $RETRIES); do
    oc delete pods $(oc get pods -o name -l app=${app_name} -n ${openshift_namespace} | head -1 | cut -f 2 -d '/') -n ${openshift_namespace} || BIND_ERROR=true
    ${BASH_DIR}/wait-for-resource.sh create pod ${app_name}

  	# Filter for 'podpreset.admission.kubernetes.io' in the pod
  	preset_test=$(oc get pods $(oc get pods -n ${openshift_namespace} | grep ${app_name} | awk $'{ print $1 }') -o yaml -n ${openshift_namespace} | grep podpreset | awk $'{ print $1}' | cut -f 1 -d '/')
  	if [ "${preset_test}" = "podpreset.admission.kubernetes.io" ]; then
      print-with-green "Pod presets found in the ${app_name} pod"
      break
  	else
      print-with-yellow "Pod presets not found in the ${app_name} pod"
      print-with-yellow "Retrying..."
  	fi
  done

  if [ "${x}" -eq "${RETRIES}" ]; then
    print-with-red "Pod presets aren't in the ${app_name} pod"
    BIND_ERROR=true
  fi
}

function pickup-pod-presets {
  print-with-green "Checking if ${app_name} recieved bind credentials"
  bind-credential-check

  error-check "pickup-pod-presets"
}

function verify-ci-run {
  # This section is specific to SNS APB
  export AWS_ACCESS_KEY_ID="${aws_access_key}"
  export AWS_SECRET_ACCESS_KEY="${aws_secret_key}"

  print-with-yellow "Retrieving list of SNS topics in ${aws_region}..."
  sns_topic_arn=$(aws sns list-topics --region $aws_region | grep $stack_identifier)

  if [ -z "${sns_topic_arn}" ]; then
    print-with-red "FAILURE - Couldn't find SNS topic in ${aws_region} with expected ARN."
    VERIFY_CI_ERROR=true
  else
    print-with-green "SUCCESS"
    print-with-green "Topic ARN found: ${sns_topic_arn}"
  fi

  error-check "verify-ci-run"
}

######
# Main
######
precheck
provision
#bind
#pickup-pod-presets
verify-ci-run
convert-to-red
error-variables
