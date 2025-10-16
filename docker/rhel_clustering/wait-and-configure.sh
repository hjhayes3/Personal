#!/bin/bash
set -e

NODE1=node1
NODE2=node2
CLUSTER_NAME=mycluster
PCSD_PORT=2224
MAX_WAIT=60     # total wait time in seconds
SLEEP_INTERVAL=3
COUNTER=0

echo "[node1] Waiting for ${NODE2}:${PCSD_PORT} (max ${MAX_WAIT}s)..."

until nc -z "${NODE2}" "${PCSD_PORT}"; do
  sleep "${SLEEP_INTERVAL}"
  COUNTER=$((COUNTER + SLEEP_INTERVAL))
  echo "[node1] Still waiting... ${COUNTER}s elapsed."

  if [ "${COUNTER}" -ge "${MAX_WAIT}" ]; then
    echo "[node1] ERROR: ${NODE2}:${PCSD_PORT} not reachable after ${MAX_WAIT}s — aborting cluster setup."
    exit 1
  fi
done

echo "[node1] ${NODE2} is reachable after ${COUNTER}s, proceeding."

# Set hacluster password on node1
echo "${hapwd}" | passwd --stdin hacluster

# Authenticate and configure cluster
echo "[node1] Authenticating cluster nodes..."
pcs host auth ${NODE1} ${NODE2} -u hacluster -p "${hapwd}"

if ! pcs cluster status >/dev/null 2>&1; then
  echo "[node1] Creating cluster ${CLUSTER_NAME}..."
  pcs cluster setup --name "${CLUSTER_NAME}" ${NODE1} ${NODE2}
  pcs cluster start --all
  pcs property set stonith-enabled=false
  pcs property set no-quorum-policy=ignore
else
  echo "[node1] Cluster already configured, skipping setup."
fi

pcs status
