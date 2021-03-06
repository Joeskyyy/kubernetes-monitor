#! /bin/bash
#
# Inputs:
# - $1: The full Operator image name and tag, e.g. "snyk/kubernetes-operator:1.2.3"
# - $2: The snyk-monitor image tag, e.g. "1.2.3"
#
# Output:
# - Creates a copy of the snyk-monitor Helm chart under the snyk-operator
# - Builds a Docker image with the name passed in input "$1"
#
# Creates an Operator using Operator template files in this repository.
# The template files should have been previously generated by using the operator-sdk.
#
# By using the template files, this script copies over the Helm chart and makes some minor
# replacements to ensure the latest built snyk-monitor tag is used in the Operator. This way
# users get all the default values of the chart, and are always pointing to the correct image tag.
#

set -e

SNYK_OPERATOR_IMAGE_NAME_AND_TAG="$1"
SNYK_MONITOR_IMAGE_TAG="$2"

PWD="$(pwd)"
OS_NAME="$(uname -s)"
# Expects the "operator-sdk" binary to be present in PATH for Mac, or in the current directory for every other platform.
OPERATOR_SDK_PATH=$([ "${OS_NAME}" == "Darwin" ] && echo "operator-sdk" || echo "${PWD}/operator-sdk")
HELM_CHART_NAME="snyk-monitor"
OPERATOR_NAME="snyk-operator"
OPERATOR_LOCATION="${PWD}/${OPERATOR_NAME}"
HELM_CHART_LOCATION="${PWD}/${HELM_CHART_NAME}"
# The location of this Helm chart's copy must match what the Dockerfile of the Operator.
# Also, the end location should be "helm-charts", as this is what the operator-sdk expects when building the Operator image!
OPERATOR_HELM_CHARTS_LOCATION="${OPERATOR_LOCATION}/helm-charts"
OPERATOR_HELM_VALUES_LOCATION="${OPERATOR_HELM_CHARTS_LOCATION}/${HELM_CHART_NAME}/values.yaml"
OPERATOR_HELM_DEPLOYMENT_LOCATION="${OPERATOR_HELM_CHARTS_LOCATION}/${HELM_CHART_NAME}/templates/deployment.yaml"

mkdir -p "${OPERATOR_HELM_CHARTS_LOCATION}"

cp -R "${HELM_CHART_LOCATION}" "${OPERATOR_HELM_CHARTS_LOCATION}"

# The following fields will be automatically generated by OpenShift when deploying the snyk-monitor; we can't hardcode them.
sed -i.bak "s|runAsUser: 10001|# runAsUser: 10001|g" "${OPERATOR_HELM_DEPLOYMENT_LOCATION}"
sed -i.bak "s|runAsGroup: 10001|# runAsGroup: 10001|g" "${OPERATOR_HELM_DEPLOYMENT_LOCATION}"
rm "${OPERATOR_HELM_DEPLOYMENT_LOCATION}.bak"

sed -i.bak "s|IMAGE_TAG_OVERRIDE_WHEN_PUBLISHING|${SNYK_MONITOR_IMAGE_TAG}|g" "${OPERATOR_HELM_VALUES_LOCATION}"
rm "${OPERATOR_HELM_VALUES_LOCATION}.bak"

cd "${OPERATOR_LOCATION}"

"${OPERATOR_SDK_PATH}" build "${SNYK_OPERATOR_IMAGE_NAME_AND_TAG}"
