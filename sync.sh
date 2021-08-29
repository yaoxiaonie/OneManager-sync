#!/bin/bash

# Copyright (C) 2021 MistyRain <1740621736@qq.com>

SYNC_URL="$1"
if [ ! -n "$2" ]; then
    SYNC_OUT="$(echo "$SYNC_URL" | sed 's|/| |g' | awk '{print $NF}')"
else
    SYNC_OUT="$2"
fi

if [ ! -n "$SYNC_URL" ]; then
    echo "没有任何参数！"
    exit 1
fi

function download() {
    curl -sL "$1" -o "$2"
    if [ "$?" = "1" ]; then
        echo "接收途中发现错误，已终止！"
        rm -rf $SYNC_OUT
        exit 1
    fi
}

mkdir -p $SYNC_OUT
curl -sL "$SYNC_URL/sync.config" -o "$SYNC_OUT/sync.config"
if [ "$?" = "1" ]; then
    echo "未发现sync.config"
    rm -rf $SYNC_OUT
    exit 1
fi

SYNC_PROGRESS="0"
SYNC_NUMBER=$(wc -l $SYNC_OUT/sync.config | awk '{print $1}')
echo "接收进'${SYNC_OUT}'..."
for SYNC_FILE in $(cat $SYNC_OUT/sync.config); do
    let SYNC_PROGRESS++
    echo -en "接收对象：$(echo $SYNC_PROGRESS*100/$SYNC_NUMBER | bc)%（${SYNC_PROGRESS}/${SYNC_NUMBER}）\r"
    SYNC_FILE_PDIR=$(dirname $SYNC_FILE)
    mkdir -p $SYNC_OUT/$SYNC_FILE_PDIR
    download "$SYNC_URL/$SYNC_FILE" "$SYNC_OUT/$SYNC_FILE"
done
echo -en "接收对象：$(echo $SYNC_PROGRESS*100/$SYNC_NUMBER | bc)%（${SYNC_PROGRESS}/${SYNC_NUMBER}），完成！\r"
