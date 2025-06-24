#!/bin/bash

LOGFILE="/var/log/hh-update.log"
BOT_TOKEN="your_token"
CHAT_ID="your_chat_id"

send_telegram() {
    local MESSAGE="$1"
    # Экранируем спецсимволы Markdown для безопасности
    local ESCAPED_MESSAGE=$(echo "$MESSAGE" | sed -e 's/_/\\_/g' -e 's/\*/\\*/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/`/\\`/g')
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$ESCAPED_MESSAGE" \
        -d parse_mode="Markdown" > /dev/null
}

format_duration() {
    local D=$1
    if (( D >= 60 )); then
        echo "$((D / 60))m $((D % 60))s"
    else
        echo "${D}s"
    fi
}

run_cmd() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Running: $*" >> "$LOGFILE"
    "$@" >> "$LOGFILE" 2>&1
    if [ $? -ne 0 ]; then
        ERROR_MSG="❌ *hh-update.sh* — ошибка при выполнении команды:\n\`$*\`"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $*" >> "$LOGFILE"
        send_telegram "$ERROR_MSG"
        exit 1
    fi
}

START_TIME=$(date +%s)
START_HUMAN=$(date '+%Y-%m-%d %H:%M:%S')

echo "-----------------------------" >> "$LOGFILE"
echo "$START_HUMAN - Начало обновления HH" >> "$LOGFILE"

run_cmd /root/.local/bin/hh-applicant-tool clear-negotiations
run_cmd /root/.local/bin/hh-applicant-tool update-resumes

END_TIME=$(date +%s)
DIFF=$((END_TIME - START_TIME))
TIME_STR=$(format_duration $DIFF)

echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Успешно очищены отклонённые заявки и обновлены резюме" >> "$LOGFILE"
echo "Время выполнения: $TIME_STR" >> "$LOGFILE"

MSG="✅ HH обновление успешно завершено на сервере *$(hostname)* в $START_HUMAN.
Время выполнения: $TIME_STR

*hh-update.sh* — успешно выполнен!"

send_telegram "$MSG"
