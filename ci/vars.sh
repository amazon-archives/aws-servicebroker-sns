#!/bin/bash

# AWS params
export aws_access_key=""
export aws_secret_key=""

# SNS params
export stack_identifier="autoprovision0001"
export aws_region="us-west-2"

# OpenShift params
export openshift_namespace="default"

# Automation variables
export aws_svc_name="sns"
export aws_svc_name_pretty="SNS"
export aws_svc_service_class_name="apb-push-ansibleplaybookbundle-sns-apb"
