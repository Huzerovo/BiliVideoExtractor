#!/bin/bash

CODE_RED="\033[31m"
CODE_WARN="\033[32m"
CODE_NORMAL="\033[0m"
PYTHON_BILI_TITLE="$(dirname "$(realpath "$0")")/bili_video_title.py"

warn () {
    printf "$CODE_WARN%s$CODE_NORMAL\n" "$*"
}

error() {
    printf "$CODE_RED%s$CODE_NORMAL\n" "$*"
}

die () {
    printf "$CODE_RED%s$CODE_NORMAL\n" "$*"
    exit 1
}


show_help() {
cat <<_EOF_
Usage: ${0##*/} [options] VIDEO_DIRECTORY

    VIDEO_DIRECTORY is the top directory of the video you want to extrace

Options:
    -h, --help          Show this help
    -d, --directory     Video directory (default: $PWD/download)
    -o, --output        Output directory (default: $PWD/output)

_EOF_
}

VIDEO_DIR="$PWD/download"
OUTPUT_DIR="$PWD/output"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h | --help)
            show_help
            exit 0
            ;;
        -d | --directory)
            shift
            export VIDEO_DIR="$1"
            ;;
        -o | --output)
            shift
            export OUTPUT_DIR="$1"
            ;;
        *)
            echo "Unknow option: $1"
            exit 2
            ;;
    esac
    shift
done

c=$(find "$VIDEO_DIR" -maxdepth 1 -type d | wc -l)
((c--))
if [[ $c -le 0 ]] ; then
    die "没有在 $VIDEO_DIR 目录下找到视频文件夹"
fi

for video in "$VIDEO_DIR"/*; do
    if [[ ! -d "$video" ]]; then
        warn "$video 不是一个视频文件夹，忽略"
        continue
    fi
    echo "处理视频：$video"

    c=$(find "$video" -maxdepth 1 -type d | wc -l)
    ((c--))
    if [[ $c -le 0 ]]; then
        warn "没有在视频文件夹 $video 下找到视频"
        rm -rf "$video"
        continue
    fi
    for part in "$video"/*; do
        if [[ ! -d "$part" ]]; then
            warn "$part 不是一个视频分集文件夹，忽略"
            continue
        fi

        ###
        video_file_base="$(python3 "$PYTHON_BILI_TITLE" -c "$part" 2> /dev/null)"
        if [[ -z "$video_file_base" ]]; then
            python3 "$PYTHON_BILI_TITLE" -c "$part"
            warn "失败：无法获取音视频所在文件夹 $part"
            continue
        fi

        blv_file=""
        if [[ -f "$video_file_base"/0.blv ]]; then
            blv_file="$video_file_base/0.blv"
        fi

        if [[ -z "$blv_file" ]]; then
            audio="$video_file_base/audio.m4s"
            video="$video_file_base/video.m4s"
        fi

        output_file="$OUTPUT_DIR/$(python3 "$PYTHON_BILI_TITLE" "$part")"
        output_dir="$(dirname "$output_file")"
        if [[ ! -d "$output_dir" ]]; then
            warn "创建文件夹：$output_dir"
            mkdir -p "$output_dir"
        fi

        if [[ -f "$blv_file" ]]; then
            ffmpeg -n -quiet -i "$blv_file" -codec copy -- "$output_file" || continue
        else
            if [[ ! -f "$audio" ]]; then
                warn "失败：$audio 文件不存在"
                continue
            fi

            if [[ ! -f "$video" ]]; then
                warn "失败：$video 文件不存在"
                continue
            fi
            ffmpeg -n -v quiet -i "$audio" -i "$video" -codec copy -- "$output_file" || continue
        fi
        ###
        rm -rf "$part"
        
    done
    rm -rf "$video"
done
