#! /bin/bash
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
OPERATOR_SDK_PATH=$([ "${OS_NAME}" == "Darwin" ] && echo "operator-sdk" || echo "${PWD}/operator-sdk")
HELM_CHART_NAME="snyk-monitor"
OPERATOR_NAME="snyk-operator"
OPERATOR_LOCATION="${PWD}/${OPERATOR_NAME}"
HELM_CHART_LOCATION="${PWD}/${HELM_CHART_NAME}"
# The location of this Helm chart's copy must match what the Dockerfile of the Operator
OPERATOR_HELM_CHARTS_LOCATION="${OPERATOR_LOCATION}/helm-charts"
OPERATOR_HELM_VALUES_LOCATION="${OPERATOR_HELM_CHARTS_LOCATION}/${HELM_CHART_NAME}/values.yaml"

# The end location should be helm-charts, as this is what the operator-sdk expects!
mkdir -p "${OPERATOR_HELM_CHARTS_LOCATION}" || : # Ignore error code if it exists
cp -R "${HELM_CHART_LOCATION}" "${OPERATOR_HELM_CHARTS_LOCATION}"

sed -i.bak "s|IMAGE_TAG_OVERRIDE_WHEN_PUBLISHING|${SNYK_MONITOR_IMAGE_TAG}|g" "${OPERATOR_HELM_VALUES_LOCATION}"

cd "${OPERATOR_LOCATION}"

"${OPERATOR_SDK_PATH}" build "${SNYK_OPERATOR_IMAGE_NAME_AND_TAG}"
