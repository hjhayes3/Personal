#!/bin/bash

domain_group=$1
host=$2
#host=csc2cxn00001823.cloud.kp.org
#domain_group=d_testcn
user=$(whoami)a
SESSION="$(echo ${host}| cut -d. -f1)_Troubleshooting"

healthcheck="/cerner/scripts/be_verify.ksh"
new_group="newgrp - ${domain_group}"
ssh_connect="ssh -q ${user}@${host}"
sleep_cmd="sleep 5"

function tsend {
tmux send-keys -t $SESSION "$@"
}

# Check if the session already exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already exists. Exiting."
  exit 1
fi

# Start a new detached session
tmux new-session -d -s $SESSION -n main

# Pane 0: SSH to server1 and run CMD1
tsend "$ssh_connect" C-m
tsend "$healthcheck" C-m

# Split horizontally to create Pane 1
tmux split-window -h -t $SESSION
tsend "$ssh_connect" C-m
tsend "$new_group" C-m
$sleep_cmd
tsend "msgview" C-m
tsend "select cmb_0051" C-m
tsend "dir" C-m
tsend "select cmb_0000" C-m
tsend "dir" C-m

## Split Pane 1 horzontally to create Pane 2
tmux select-pane -t $SESSION:0.1
tmux split-window -h -t $SESSION
tmux select-layout -t $SESSION even-horizontal 
tsend "$ssh_connect" C-m
tsend "top" C-m


# Split Pane 1 again 
tmux select-pane -t $SESSION:0.1
tmux split-window -v -t $SESSION
tsend "$ssh_connect" C-m
tsend "$new_group" C-m
$sleep_cmd
tsend "spsmon -state working" C-m

# Split Pane 3 
tmux select-pane -t $SESSION:0.3
tmux split-window -v -t $SESSION
tsend "$ssh_connect" C-m
tsend "$new_group" C-m
$sleep_cmd
tsend "spsmon -snapshot -state working " C-m
tsend "ccl" C-m
tsend  C-m
tsend  C-m
tsend  C-m
tsend  C-m
tsend  C-m
tsend  C-m
tsend  C-m
tsend  C-m
tsend  "monsql go" C-m

## Optional: rearrange layout
#tmux select-layout -t $SESSION main-vertical

# Attach to the session
tmux attach-session -t $SESSION


