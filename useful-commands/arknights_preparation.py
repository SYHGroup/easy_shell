import logging
from itertools import product

import requests

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s',
    datefmt='%Y-%m-%dT%H:%M:%S')

logger = logging


def sign(COOKIES: str):
    s = requests.Session()

    def request(method, url, max_retry: int = 2, *args, **kwargs):
        headers = {
            "User-Agent": "user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.85 Safari/537.36 Edg/90.0.818.46",
            "Referer": "https://ak.hypergryph.com/activity/preparation",
            "Cookie": COOKIES
        }
        for i in range(max_retry + 1):
            try:
                response = s.request(
                    method, url, headers=headers, *args, ** kwargs)
            except requests.exceptions.HTTPError as e:
                logger.error(f'HTTP error:\n{e}')
                logger.error(f'The NO.{i + 1} request failed, retrying...')
            except KeyError as e:
                logger.error(f'Wrong response:\n{e}')
                logger.error(f'The NO.{i + 1} request failed, retrying...')
            except Exception as e:
                logger.error(f'Unknown error:\n{e}')
                logger.error(f'The NO.{i + 1} request failed, retrying...')
            else:
                return response

        raise Exception(f'All {max_retry + 1} HTTP requests failed, die.')

    def info():
        response = request("get",
                           "https://ak.hypergryph.com/activity/preparation/activity/userInfo")
        result = response.json()
        data = result["data"]
        logger.info(
            f"{data['uid']}：当前拥有美味值：{data['remainCoin']}，剩余签到次数：{data['rollChance']}")
        return data

    def roll():
        response = request("post",
                           "https://ak.hypergryph.com/activity/preparation/activity/roll")
        result = response.json()
        return result["data"]["coin"]

    def share():
        response = request("post",
                           "https://ak.hypergryph.com/activity/preparation/activity/share", data={"method": 1})
        result = response.json()
        if result["data"]["todayFirst"]:
            logger.info("分享页面")

    def exchange(target):
        response = request("post",
                           "https://ak.hypergryph.com/activity/preparation/activity/exchange", data={"giftPackId": target})
        result = response.json()
        if result["statusCode"] == 201:
            logger.info(f"{target}: {result['message']}")
        elif result["statusCode"] == 403:
            if result["message"] == "未完成兑换前置条件":
                return True

    data = info()
    if data["share"]:
        share()
    if rollChance := data["rollChance"]:
        while rollChance:
            rollChance = rollChance - 1
            earn = roll()
            logger.info(f"美味值+{earn}，剩余签到次数: {rollChance}")
        data = info()
    if data['remainCoin'] > 100:
        for a, b in product(range(1, 6), range(1, 7)):
            if (a, b) in [(1, 5), (1, 6), (2, 6), (3, 6)]:
                continue
            else:
                if exchange(f"g_{a}_{b}"):
                    break


if __name__ == "__main__":
    cookies = [] #ak2nda
    for cookie in cookies:
        sign(cookie)
