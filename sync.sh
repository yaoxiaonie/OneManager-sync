#!/bin/bash

# Copyright (C) 2021 MistyRain <1740621736@qq.com>

function download() {
    if [ -n "$HEADERS" ]; then
        wget --header="$HEADERS" -U --"Mozilla/5.0" "$1" -O "$2"
    else
        wget -U --"Mozilla/5.0" "$1" -O "$2" >/dev/null 2>&1
    fi
    if [ "$?" = "1" ]; then
        echo "接收途中发现错误，已终止！"
        rm -rf $SYNC_OUT
        exit 1
    fi
}

function restore() {
    if [ "$1" = "-c" ]; then
        chmod "$2" "$3"
    elif [ "$1" = "-l" ]; then
        rm -rf "$3"
        ln -s "$2" "$3"
    fi
}

function pull() {
    mkdir -p $SYNC_OUT
    if [ -n "$HEADERS" ]; then
        curl --header "$HEADERS" -sL "$SYNC_URL/sync_dirs.config" -o "$SYNC_OUT/sync_dirs.config"
        curl --header "$HEADERS" -sL "$SYNC_URL/sync_files.config" -o "$SYNC_OUT/sync_files.config"
        curl --header "$HEADERS" -sL "$SYNC_URL/sync_links.config" -o "$SYNC_OUT/sync_links.config"
    else
        curl -sL "$SYNC_URL/sync_dirs.config" -o "$SYNC_OUT/sync_dirs.config"
        curl -sL "$SYNC_URL/sync_files.config" -o "$SYNC_OUT/sync_files.config"
        curl -sL "$SYNC_URL/sync_links.config" -o "$SYNC_OUT/sync_links.config"
    fi
    if [ "$?" = "1" ]; then
        echo "未发现sync_files.config"
        rm -rf $SYNC_OUT
        exit 1
    fi
    SYNC_PROGRESS="0"
    SYNC_NUMBER=$(wc -l $SYNC_OUT/sync_files.config | awk '{print $1}')
    echo "接收进'${SYNC_OUT}'..."
    echo "正在处理结构树..."
    cat $SYNC_OUT/sync_dirs.config | while read SYNC_ONLINE_DIR; do
        SYNC_DIR=$(echo "$SYNC_ONLINE_DIR" | awk '{print $1}')
        SYNC_FS=$(echo "$SYNC_ONLINE_DIR" | awk '{print $2}')
        mkdir -p "$SYNC_OUT/$SYNC_DIR"
        restore -c "$SYNC_FS" "$SYNC_OUT/$SYNC_DIR"
    done
    cat $SYNC_OUT/sync_files.config | while read SYNC_ONLINE_FILE; do
        SYNC_FILE=$(echo "$SYNC_ONLINE_FILE" | awk '{print $1}')
        SYNC_FS=$(echo "$SYNC_ONLINE_FILE" | awk '{print $2}')
        let SYNC_PROGRESS++
        echo -en "接收对象：$(echo $SYNC_PROGRESS*100/$SYNC_NUMBER | bc)%（${SYNC_PROGRESS}/${SYNC_NUMBER}）\r"
        download "$SYNC_URL/$SYNC_FILE" "$SYNC_OUT/$SYNC_FILE"
        restore -c "$SYNC_FS" "$SYNC_OUT/$SYNC_FILE"
    done
    cat $SYNC_OUT/sync_links.config | while read SYNC_ONLINE_LINK; do
        if [ -n "$SYNC_ONLINE_LINK" ]; then
            SYNC_LINK=$(echo "$SYNC_ONLINE_LINK" | awk '{print $1}')
            SYNC_FS=$(echo "$SYNC_ONLINE_LINK" | awk '{print $2}')
            restore -l "$SYNC_FS" "$SYNC_OUT/$SYNC_LINK"
        fi
    done
    echo -en "接收对象：$(echo $SYNC_PROGRESS*100/$SYNC_NUMBER | bc)%（${SYNC_PROGRESS}/${SYNC_NUMBER}），完成！\r"
}

function push() {
    if [ -d "$SYNC_DIR" ]; then
        echo -en "正在生成sync.config...\r"
        true >$SYNC_DIR/sync_dirs.config
        true >$SYNC_DIR/sync_files.config
        true >$SYNC_DIR/sync_links.config
        for SYNC_FILE in $(find $SYNC_DIR -type d); do
            SYNC_FS=$(stat -c %a $SYNC_FILE)
            FS_CONFIG="$(echo "$SYNC_FILE" | sed "s|$SYNC_DIR/||g") 0$SYNC_FS"
            echo "$FS_CONFIG" >>$SYNC_DIR/sync_dirs.config
        done
        sed -i '1d' $SYNC_DIR/sync_dirs.config
        for SYNC_FILE in $(find $SYNC_DIR -type f); do
            SYNC_FS=$(stat -c %a $SYNC_FILE)
            FS_CONFIG="$(echo "$SYNC_FILE" | sed "s|$SYNC_DIR/||g") 0$SYNC_FS"
            echo "$FS_CONFIG" >>$SYNC_DIR/sync_files.config
        done
        for SYNC_FILE in $(find $SYNC_DIR -type l); do
            SYNC_LINK=$(ls -l $SYNC_FILE | awk '{print $NF}')
            FS_CONFIG="$(echo "$SYNC_FILE" | sed "s|$SYNC_DIR/||g") $SYNC_LINK"
            echo "$FS_CONFIG" >>$SYNC_DIR/sync_links.config
        done
        echo -en "正在生成sync.config，完成！\r\n"
    else
        echo "参数为空或是错误的参数！"
        exit 1
    fi
}

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
if [ -f "$PROJECT_DIR/headers.txt" ]; then
    HEADERS="$(cat $PROJECT_DIR/headers.txt)"
fi
if [[ "$1" == "http"* ]]; then
    SYNC_DO="pull"
    SYNC_URL="$1"
elif [[ -d "$1" ]]; then
    SYNC_DO="push"
    SYNC_DIR="$1"
else
    echo "参数为空或是错误的参数！"
    exit 1
fi

if [ ! -n "$2" ]; then
    SYNC_OUT="$(echo "$SYNC_URL" | sed 's|/| |g' | awk '{print $NF}')"
else
    SYNC_OUT="$2"
fi

case $SYNC_DO in
pull)
    pull
    ;;
push)
    push
    ;;
*)
    exit1
    ;;
esac
