#! /bin/sh

set -eu

_get_dynatrace_env() {
  if test "$1" = "production"; then
    echo "https://bhe21058.live.dynatrace.com/api/v2/metrics/ingest"
  else
    echo "https://khw46367.live.dynatrace.com/api/v2/metrics/ingest"
  fi
}

_get_dynatrace_token() {
  if test "$1" = "production"; then
    token=$(aws secretsmanager get-secret-value --secret-id "arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceProductionVariables" | jq -r '.SecretString' | jq -r '.METRICS_INGEST_API_TOKEN')
    if [ -n "$token" ]; then
      echo $token
    else
      exit 0
    fi
  else
    token=$(aws secretsmanager get-secret-value --secret-id "arn:aws:secretsmanager:eu-west-2:216552277552:secret:DynatraceNonProductionVariables" | jq -r '.SecretString' | jq -r '.METRICS_INGEST_API_TOKEN')
    if [ -n "$token" ]; then
      echo $token
    else
      exit 0
    fi
  fi
}

_format_time() {
  seconds=$1
  export TZ=Europe/London
  # Formats date to YYYY-MM-DD-HH:MM:SS(<london-timezone>)
  echo $(date -d "@$seconds" '+%F-%T(%Z)')
}

_format_time_utc() {
  seconds=$1
  # Formats date to YYYY-MM-DDTHH:MM:SSZ as recommended by ADR 0009
  echo $(date -u --date="@$seconds" "+%FT%TZ")
}

_get_duration() {
  start_time=$1
  end_time=$2
  duration=$((end_time-start_time))

  # Formats time with 2 digits minimum and assigns them to variables
  printf -v hours "%02d" $((duration / 3600))
  printf -v minutes "%02d" $((duration % 3600 / 60))
  printf -v seconds "%02d" $((duration % 60))

  echo "$hours:$minutes:$seconds"
}

# retrieve mergetime and return false if it's not there, else return mergetime
_get_merge_time() {
  CODEBUILD_RESOLVED_SOURCE_VERSION=$1
  ARTIFACTBUCKET=$2
  merge_time=$(aws s3api head-object \
    --version-id $CODEBUILD_RESOLVED_SOURCE_VERSION \
    --bucket $ARTIFACTBUCKET \
    --key template.zip \
    --query='Metadata.[mergetime]' --o text )
  if [ $merge_time = "None" ]; then
    echo False
  else
    echo $merge_time
  fi
}

_get_deployment_time() {
  merge_time=$1
  end_time=$2
  merge_time="$(date --date="$merge_time" +"%s")"
  deployment_time=$((end_time-merge_time))
  echo $deployment_time
}

_format_data() {
  metric_key=$1
  metric_value=$2

  DATA=(
    # Metric Key
    "$metric_key,"
    # Dimensions
    "commit-sha=$COMMIT_SHA,"
    "environment=$ENVIRONMENT,"
    "sam-stack-name=$SAM_STACK_NAME,"
    "account-id=$ACCOUNT_ID,"
    "pipeline-version=$PIPELINE_VERSION,"
    "deployment-status=$STATUS,"
    "start-time=$(_format_time $START_TIME),"
    "end-time=$(_format_time $END_TIME),"
    "start-time-utc=$(_format_time_utc $START_TIME),"
    "end-time-utc=$(_format_time_utc $END_TIME),"
    "duration=$DURATION"
    )
  DATA=$(printf "%s" ${DATA[@]})
  echo $DATA $metric_value
}

_send_metric() {
  data=$1

  curl -L -X POST $DYNATRACE_URL \
    -H "Authorization: Api-Token $DYNATRACE_TOKEN" \
    -H "Content-Type: text/plain" \
    --data-raw "$data"
}

create() {
  COMMIT_SHA=$1
  ENVIRONMENT=$2
  SAM_STACK_NAME=$3
  ACCOUNT_ID=$4
  PIPELINE_VERSION=$5
  STATUS=$6
  START_TIME=$7
  CODEBUILD_RESOLVED_SOURCE_VERSION=$8
  ARTIFACTBUCKET=$9
  END_TIME=$(date +%s)
  MERGE_TIME=$(_get_merge_time $CODEBUILD_RESOLVED_SOURCE_VERSION $ARTIFACTBUCKET)
  echo $MERGE_TIME
  DURATION=$(_get_duration $START_TIME $END_TIME)
  echo "Fetching Dynatrace URL and API token..."
  DYNATRACE_URL=$(_get_dynatrace_env "$ENVIRONMENT")
  DYNATRACE_TOKEN=$(_get_dynatrace_token "$ENVIRONMENT")
  if [ -z "$DYNATRACE_TOKEN" ]; then
        echo "Dynatrace token not found"
        echo "To add secure pipelines metrics, please refer to the DevPlatform documentation."
    exit 0
  fi

# if mergetime = False then return an empty string else, carry out get_deployment_time and format_data
DEPLOYMENT_DATA=$(_format_data "devplatform.sam-pipelines.deployment" 1)
  if [[ $MERGE_TIME = "False" ]]; then
    _send_metric "$DEPLOYMENT_DATA"
  else
    DEPLOYMENT_TIME=$(_get_deployment_time "$MERGE_TIME" $END_TIME)
    DEPLOYMENT_TIME_DATA=$(_format_data "devplatform.sam-pipelines.deployment.time" "$DEPLOYMENT_TIME");
    _send_metric \
      "$DEPLOYMENT_DATA
      $DEPLOYMENT_TIME_DATA"
  fi
}

"$@"
