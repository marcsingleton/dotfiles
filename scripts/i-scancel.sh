#!/bin/bash

# Interactive cancellation of Slurm jobs
#
# Requires AWK and fzf

set -e

# Get the list of running jobs for the current user
output=$(squeue -u $USER --format="%10i %9P %12j %2t %10M %6D %N")
header=$(head -n 1 <<< $output)
header+=$'\n\nSelect jobs to cancel (Select/deselect multiple with tab/shift-tab):'
jobs=$(tail -n +2 <<< $output)

# Check if there are any jobs to cancel
if [ -z "$jobs" ]; then
    echo "No running jobs found."
    exit 1
fi

# Use fzf to select multiple jobs to cancel
selected_jobs=$(fzf --header="${header}"  --multi --height=25% <<< $jobs)
# Check if any jobs were selected
if [ -z "$selected_jobs" ]; then
    echo "No jobs selected."
    exit 1
fi

# Extract the job IDs from the selected jobs
job_ids=$(echo "$selected_jobs" | awk '{print $1}')

# Cancel the selected jobs
for job_id in $job_ids; do
    scancel "$job_id"
    
    # Confirm cancellation
    if [ $? -eq 0 ]; then
        echo "Job $job_id has been cancelled."
    else
        echo "Failed to cancel job $job_id."
    fi  
done
