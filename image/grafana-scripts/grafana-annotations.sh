#! /bin/sh

set -eu

_get_grafana_url() {
  if test "$1" = "production"; then
    echo "https://g-8e26091ad7.grafana-workspace.eu-west-2.amazonaws.com/api/annotations/"
  else
    echo "https://g-9908ef36be.grafana-workspace.eu-west-2.amazonaws.com/api/annotations/"
  fi
}

_get_grafana_token() {
  token=$(aws secretsmanager get-secret-value --secret-id "pipeline-grafana-api-key" | jq -r '.SecretString')
  if [ -n "$token" ]; then
    echo "$token"
  else
    exit 0
  fi
}

create() {
  COMMIT_SHA=$1
  ENVIRONMENT=$2
  SAM_STACK_NAME=$3
  ACCOUNT_ID=$4
  PIPELINE_VERSION=$5
  GRAFANA_TOKEN=$(_get_grafana_token)
  if [ -z "$GRAFANA_TOKEN" ]; then
    exit 0
  fi
  ANNOTATIONS_URL=$(_get_grafana_url "$ENVIRONMENT")

  RESPONSE=$(curl -X POST "$ANNOTATIONS_URL" \
  --header "Authorization: Bearer $GRAFANA_TOKEN" \
  --header "Content-Type: application/json; charset=UTF-8" \
  --header "Accept: */*" \
  -d '{ "time":'"$(date +%s000)"', "tags":["'"$COMMIT_SHA"'","'"$ENVIRONMENT"'", "'"$SAM_STACK_NAME"'", "'"$ACCOUNT_ID"'", "'"pipeline_version=$PIPELINE_VERSION"'"], "text":"Update to '"$SAM_STACK_NAME"' in progress" }')

  ANNOTATION_ID=$(echo "$RESPONSE"| jq '.id')

  echo "$ANNOTATION_ID"
}

update() {
  STATE=$1
  ENVIRONMENT=$2
  SAM_STACK_NAME=$3

  # Check if annotation ID has been supplied
  if [ -z ${4+x} ]; then
    echo "No annotation ID supplied; not adding annotation"
    exit 0
  fi
  ANNOTATION_ID_TO_UPDATE=$4

  GRAFANA_TOKEN="$(_get_grafana_token)"
  if [ -z "$GRAFANA_TOKEN" ]; then
      echo "Token not found; not adding annotation"
      exit 0
  fi

  ANNOTATIONS_URL=$(_get_grafana_url "$ENVIRONMENT")

  echo "Updating Grafana annotation [$ANNOTATION_ID_TO_UPDATE] to deployment $STATE"

  FORMATTED_URL="$ANNOTATIONS_URL""$ANNOTATION_ID_TO_UPDATE"

  curl -X PATCH "$FORMATTED_URL" \
  --header "Authorization: Bearer $GRAFANA_TOKEN" \
  --header "Content-Type: application/json; charset=UTF-8" \
  --header "Accept: */*" \
  -d '{ "timeEnd":'"$(date +%s000)"', "text":"Update of '"$SAM_STACK_NAME"' '"$STATE"'" }'
}

"$@"
