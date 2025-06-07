#!/usr/bin/env python3

"""
# bili-rename

用于解析bilibili APP内缓存的视频标题
"""

import argparse
import json
import os
import sys


def log_info(msg: str) -> None:
    """
    log info
    """
    sys.stdout.write(msg + "\n")


def log_error(msg: str) -> None:
    """
    log error
    """
    sys.stderr.write(msg + "\n")


def get_video_id(data: dict) -> str:
    """
    获取视频av或bv，优先bv
    """
    if "bvid" in data and data["bvid"] != "":
        return data["bvid"]
    if "avid" not in data:
        return "null"
    return av_to_bv(data["avid"])


def av_to_bv(x: int) -> str:
    """
    将视频av号转化为bv号
    """

    table = "fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF"
    tr = {}
    for i in range(58):
        tr[table[i]] = i
    s = [11, 10, 3, 8, 4, 6]
    xor = 177451812
    add = 8728348608

    x = (x ^ xor) + add
    r = list("BV1  4 1 7  ")
    for i in range(6):
        r[s[i]] = table[x // 58**i % 58]
    return "".join(r)


def get_content_path(video_path: str) -> bool:
    """
    获取音视频文件夹路径
    """
    entry_file = video_path + "/entry.json"

    with open(entry_file, encoding="UTF-8") as f:
        entry_json = json.load(f)
        content_path = video_path + "/" + entry_json["type_tag"]
        if os.path.isdir(content_path):
            log_info(content_path)
            return True

    log_error("无法读取entry.json: " + entry_file)
    return False


def get_video_title(video_path: str) -> bool:
    """
    生成视频输出路径
    """
    video_path = os.path.abspath(video_path)
    entry_file = video_path + "/entry.json"

    with open(entry_file, encoding="UTF-8") as f:
        entry_json = json.load(f)
        title: str = entry_json["title"].replace("/", "_")
        owner: str = entry_json["owner_name"].replace("/", "_")
        owner_id: number = entry_json["owner_id"]
        sub_title = ""

        if "page_data" in entry_json:
            page_data = entry_json["page_data"]
            sub_title = page_data["part"].replace("/", "_")

            if sub_title == "":
                sub_title = "page " + str(page_data["page"])

            if title != sub_title:
                title = title + "/" + sub_title + "(" + owner + "_" + owner_id + ")"

        # FIXME: 重构ep部分
        elif "ep" in entry_json:
            ep = entry_json["ep"]
            sub_title = ep["index_title"].replace("/", "_")
            title = title + "/" + sub_title + "(" + owner + "_" + owner_id + ")"

        log_info(title + "[" + get_video_id(entry_json) + "]" + ".mp4")
        return True

    log_error("无法读取entry.json: " + entry_file)
    return False


if __name__ == "__main__":
    argparser = argparse.ArgumentParser()
    argparser.description = """
    获取bilibili缓存视频的标题。
    合集会获取合集名称与分集名称，并以'/'划分。
    """
    argparser.add_argument(
        "video_path", help="视频文件夹路径，文件内有个entry.json文件"
    )
    argparser.add_argument(
        "--content",
        "-c",
        help="获取音视频存放路径，默认获取视频标题",
        action="store_true",
    )
    args = argparser.parse_args()
    if args.content:
        if not get_content_path(os.path.abspath(args.video_path)):
            log_error("无法获取音视频文件夹路径")
            sys.exit(1)
    else:
        if not get_video_title(os.path.abspath(args.video_path)):
            log_error("无法获取视频标题")
            sys.exit(1)
    sys.exit()
