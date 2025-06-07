#!/bin/bash

CODE_RED="\033[31m"
CODE_WARN="\033[33m"
CODE_NORMAL="\033[0m"
PYTHON_BILI_TITLE="$(dirname "$(realpath "$0")")/bili_video_title.py"
DELETE_AFTER_EXTRACT="false"
DRY_RUN="false"

delete() {
    if [[ "$DELETE_AFTER_EXTRACT" == "true" && "$DRY_RUN" == "false" ]]; then
        if [[ -d "$*" ]]; then
            rm -rf "$*"
        else
            warn "$* is not a folder, ignore"
        fi
    fi
}

warn () {
    printf "${CODE_WARN}warn: %s${CODE_NORMAL}\n" "$*"
}

error() {
    printf "${CODE_RED}error: %s${CODE_NORMAL}\n" "$*"
}

die () {
    printf "${CODE_RED}exited with error: %s${CODE_NORMAL}\n" "$*"
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

    --delete            Delete video folder after extracted.
    --dry-run           Skip extract video and delete folder.

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
        --delete)
            DELETE_AFTER_EXTRACT="true"
            ;;
        --dry-run)
            DRY_RUN="true"
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

if [[ "$DRY_RUN" == "true" ]]; then
    warn "Dry run"
fi

for video_dir in "$VIDEO_DIR"/*; do
    if [[ ! -d "$video_dir" ]]; then
        warn "$video_dir 不是一个视频文件夹，忽略"
        continue
    fi
    echo "处理视频：$video_dir"

    c=$(find "$video_dir" -maxdepth 1 -type d | wc -l)
    ((c--))
    if [[ $c -le 0 ]]; then
        warn "没有在视频文件夹 $video_dir 下找到视频"
        delete "$video_dir"
        continue
    fi
    for part_dir in "$video_dir"/*; do
        if [[ ! -d "$part_dir" ]]; then
            warn "$part_dir 不是一个视频分集文件夹，忽略"
            continue
        fi

        ###
        video_file_base="$(python3 "$PYTHON_BILI_TITLE" -c "$part_dir" 2> /dev/null)"
        if [[ -z "$video_file_base" ]]; then
            python3 "$PYTHON_BILI_TITLE" -c "$part_dir"
            error "失败，无法获取音视频所在文件夹 $part_dir"
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

        output_file="$OUTPUT_DIR/$(python3 "$PYTHON_BILI_TITLE" "$part_dir")"
        output_dir="$(dirname "$output_file")"
        if [[ ! -d "$output_dir" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                warn "创建文件夹：$output_dir"
                mkdir -p "$output_dir"
            fi
        fi

        if [[ -f "$blv_file" ]]; then
            if [[ "$DRY_RUN" == "false" ]]; then
                ffmpeg -n -quiet -i "$blv_file" -codec copy -- "$output_file" || continue
            fi
        else
            if [[ ! -f "$audio" ]]; then
                warn "音频文件 $audio 不存在，将忽略使用音频文件输入"
                if [[ "$DRY_RUN" == "false" ]]; then
                    ffmpeg -n -v quiet -i "$video" -codec copy -- "$output_file" || continue
                fi
                continue
            fi

            if [[ ! -f "$video" ]]; then
                warn "视频文件 $video 不存在，将忽略使用视频文件输入"
                if [[ "$DRY_RUN" == "false" ]]; then
                    ffmpeg -n -v quiet -i "$audio" -codec copy -- "$output_file" || continue
                fi
                continue
            fi
            if [[ "$DRY_RUN" == "false" ]]; then
                ffmpeg -n -v quiet -i "$audio" -i "$video" -codec copy -- "$output_file" || continue
            fi
        fi
        ###
        delete "$part_dir"
        
    done
    delete "$video_dir"
done
