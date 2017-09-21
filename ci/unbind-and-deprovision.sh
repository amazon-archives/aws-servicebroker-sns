#!/bin/bash

CUR_DIR="$(dirname "${BASH_SOURCE}")"
BASH_DIR="${CUR_DIR}/bash"

# Load vars for customizing CI run per application/service
source "${CUR_DIR}/vars.sh"

# Delete service instances
oc delete instance ${aws_svc_name} -n ${openshift_namespace}

# Wait for SNS deprovision to complete
$BASH_DIR/wait-for-resource.sh completed apb ${aws_svc_name} 50 5
