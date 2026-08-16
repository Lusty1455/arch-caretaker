#!/usr/bin/env bash

API_URL='http://127.0.0.1:3876'
MODE_FILE=${SUPER_PRODUCTIVITY_DISPLAY_MODE_FILE:-"${XDG_CACHE_HOME:-$HOME/.cache}/waybar/super-productivity-display-mode"}

emit_status() {
    jq -cn --arg text "$1" --arg tooltip "$2" --arg class "$3" \
        '{text: $text, tooltip: $tooltip, class: $class}'
}

format_duration() {
    local milliseconds=$1
    local minutes=$((milliseconds / 60000))
    local hours=$((minutes / 60))
    local remaining_minutes=$((minutes % 60))

    if ((hours == 0)); then
        printf '%dm' "$minutes"
    elif ((remaining_minutes == 0)); then
        printf '%dh' "$hours"
    else
        printf '%dh%dm' "$hours" "$remaining_minutes"
    fi
}

response=$(curl --noproxy 127.0.0.1 --fail --silent --show-error \
    --connect-timeout 1 --max-time 2 \
    "$API_URL/task-control/current" 2>/dev/null) || {
    emit_status '󰄬' 'Super Productivity API 未连接' 'offline'
    exit 0
}

title=$(jq -r '(.data.title // .data.task.title // .data.currentTask.title // empty)' <<<"$response")
if [[ -z "$title" ]]; then
    emit_status '󰄬' '无当前专注任务' 'idle'
    exit 0
fi

time_spent=$(jq -r '(.data.timeSpent // .data.task.timeSpent // .data.currentTask.timeSpent // 0)' <<<"$response")
time_estimate=$(jq -r '(.data.timeEstimate // .data.task.timeEstimate // .data.currentTask.timeEstimate // 0)' <<<"$response")
parent_id=$(jq -r '(.data.parentId // .data.task.parentId // .data.currentTask.parentId // empty)' <<<"$response")

[[ $time_spent =~ ^[0-9]+$ ]] || time_spent=0
[[ $time_estimate =~ ^[0-9]+$ ]] || time_estimate=0

display_mode=detailed
[[ -r $MODE_FILE ]] && read -r display_mode <"$MODE_FILE"

text="󰄬 $title"
tooltip="当前专注任务: $title"

if [[ -n "$parent_id" ]]; then
    tasks_response=$(curl --noproxy 127.0.0.1 --fail --silent --show-error \
        --connect-timeout 1 --max-time 2 \
        "$API_URL/tasks?includeDone=true" 2>/dev/null) || tasks_response=''

    if [[ -n "$tasks_response" ]]; then
        parent_title=$(jq -r --arg parent_id "$parent_id" \
            'first(.data[] | select(.id == $parent_id) | .title) // empty' <<<"$tasks_response")
        subtask_stats=$(jq -r --arg parent_id "$parent_id" '
            [.data[] | select(.parentId == $parent_id)]
            | {
                total: length,
                completed: map(select(.isDone == true)) | length,
                time_spent: map(.timeSpent // 0) | add // 0,
                time_estimate: map(.timeEstimate // 0) | add // 0
            }
            | [.total, .completed, .time_spent, .time_estimate] | @tsv
        ' <<<"$tasks_response")

        IFS=$'\t' read -r subtask_total subtask_completed subtask_time_spent subtask_time_estimate <<<"$subtask_stats"
        [[ $subtask_time_spent =~ ^[0-9]+$ ]] || subtask_time_spent=0
        [[ $subtask_time_estimate =~ ^[0-9]+$ ]] || subtask_time_estimate=0

        if [[ -n "$parent_title" && $subtask_total =~ ^[1-9][0-9]*$ && $subtask_completed =~ ^[0-9]+$ ]]; then
            if [[ $display_mode == compact ]]; then
                parent_spent_display=$(format_duration "$subtask_time_spent")
                text="${parent_title}-${title}(${subtask_completed}/${subtask_total}) $parent_spent_display"
                tooltip="父任务: $parent_title\n当前子任务: $title\n子任务进度: ${subtask_completed}/${subtask_total}\n子任务累计已用: $parent_spent_display"
            else
                parent_spent_display=$(format_duration "$subtask_time_spent")
                parent_estimate_display=$(format_duration "$subtask_time_estimate")
                child_display=$(format_duration "$time_spent")
                child_estimate_display=$(format_duration "$time_estimate")
                text="󰄬 ${parent_title}-${parent_spent_display}/${parent_estimate_display}——${title}(${subtask_completed}/${subtask_total})-${child_display}/${child_estimate_display}"
                tooltip="父任务: $parent_title\n子任务累计已用/预估: $parent_spent_display/$parent_estimate_display\n当前子任务: $title\n子任务进度: ${subtask_completed}/${subtask_total}\n当前子任务已用/预估: $child_display/$child_estimate_display"
            fi
        fi
    fi
elif ((time_estimate > 0)); then
    spent_display=$(format_duration "$time_spent")
    estimate_display=$(format_duration "$time_estimate")
    text+=" · $spent_display/$estimate_display"
    tooltip+="\n已用/预估: $spent_display/$estimate_display"
fi

emit_status "$text" "$tooltip" 'active'
