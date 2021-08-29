#!/bin/bash

# Copyright (C) 2021 MistyRain <1740621736@qq.com>

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
SYNC_URL="$1"
if [ ! -n "$2" ]; then
    SYNC_OUT="$PROJECT_DIR/$(echo "$SYNC_URL" | sed 's|/| |g' | awk '{print $NF}')"
else
    SYNC_OUT="$2"
fi

if [ ! -n "$SYNC_URL" ]; then
    echo "没有任何参数！"
    exit 1
fi

function download() {
    curl -sL "$1" -o "$2"
}

mkdir -p $SYNC_OUT
curl -sL "$SYNC_URL/sync.config" -o "$SYNC_OUT/sync.config"
if [ "$?" = "1" ]; then
    echo "未发现sync.config"
    exit 1
fi

SYNC_PROGRESS="0"
SYNC_NUMBER=$(wc -l $SYNC_OUT/sync.config | awk '{print $1}')
for SYNC_FILE in $(cat $SYNC_OUT/sync.config); do
    let SYNC_PROGRESS++
    echo "正在拉取$SYNC_FILE （${SYNC_PROGRESS}/${SYNC_NUMBER}）"
    SYNC_FILE_PDIR=$(dirname $SYNC_FILE)
    mkdir -p $SYNC_OUT/$SYNC_FILE_PDIR
    download "$SYNC_URL/$SYNC_FILE" "$SYNC_OUT/$SYNC_FILE"
done
