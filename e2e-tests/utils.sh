#!/usr/bin/env bash
################################################################################
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

function wait_for_logs {
  local jm_pod_name=$1
  local successful_response_regex=$2
  local timeout=$3

  # wait or timeout until the log shows up
  echo "Waiting for log \"$2\"..."
  for i in $(seq 1 ${timeout}); do
    if kubectl logs $jm_pod_name | grep -E "${successful_response_regex}" >/dev/null; then
      echo "Log \"$2\" shows up."
      return
    fi

    sleep 1
  done
  echo "Log $2 does not show up within a timeout of ${timeout} sec"
  exit 1
}

function retry_times() {
    local retriesNumber=$1
    local backoff=$2
    local command="$3"

    for i in $(seq 1 ${retriesNumber})
    do
        if ${command}; then
            return 0
        fi

        echo "Command: ${command} failed. Retrying..."
        sleep ${backoff}
    done

    echo "Command: ${command} failed ${retriesNumber} times."
    return 1
}

function debug_and_show_logs {
    echo "Debugging failed e2e test:"
    echo "Currently existing Kubernetes resources"
    kubectl get all
    kubectl describe all

    echo "Flink logs:"
    kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read pod;do
        echo "Current logs for $pod: "
        kubectl logs $pod;
        restart_count=$(kubectl get pod $pod -o jsonpath='{.status.containerStatuses[0].restartCount}')
        if [[ ${restart_count} -gt 0 ]];then
          echo "Previous logs for $pod: "
          kubectl logs $pod --previous
        fi
    done
}
