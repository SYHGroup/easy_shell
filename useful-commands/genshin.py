import hashlib
import json
import logging
import random
import string
import time
import uuid
import httpx
import asyncio

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging


class _Config:
    APP_VERSION = "2.34.1"
    SALT = "9nQiU3AV0rJSIBWgdynfoGMGKaklfbM7"
    ACT_ID = "e202009291139501"
    AWARD_URL = (
        f"https://api-takumi.mihoyo.com/event/bbs_sign_reward/home?act_id={ACT_ID}"
    )
    ROLE_URL = "https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie?game_biz=hk4e_cn"
    INFO_URL = "https://api-takumi.mihoyo.com/event/bbs_sign_reward/info?region={}&act_id={}&uid={}"
    SIGN_URL = "https://api-takumi.mihoyo.com/event/bbs_sign_reward/sign"
    USER_AGENT = f"Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/{APP_VERSION}"
    MESSAGE_TEMPLATE = """
    {today:#^28}
    🔅[{region_name}]{uid}
    今日奖励: {award_name} × {award_cnt}
    本月累签: {total_sign_day} 天
    签到结果: {status}
    {end:#^28}"""
    MAX_RETRY = 2
    MAX_WORKER = 4


CONFIG = _Config()


class Sign:
    def __init__(self, cookies: str):
        self.cookies = cookies
        self.s = httpx.AsyncClient(
            follow_redirects=True,
            verify=False,
            headers={
                "User-Agent": CONFIG.USER_AGENT,
                "Cookie": self.cookies,
            },
            timeout=None,
        )
        self._region_list = []
        self._region_name_list = []
        self._uid_list = []

    async def request(self, method, url, **kwargs):
        for i in range(CONFIG.MAX_RETRY + 1):
            try:
                response = (await self.s.request(method, url, **kwargs)).json()
            except Exception as e:
                logger.error(f"Unknown error:\n{e}")
                logger.error(f"The NO.{i + 1} request failed, retrying...")
            else:
                return response
        raise Exception(f"All {CONFIG.MAX_RETRY + 1} HTTP requests failed, die.")

    @staticmethod
    def get_ds():
        r = "".join(random.sample(string.ascii_lowercase + string.digits, 6))
        i = int(time.time())
        target = f"salt={CONFIG.SALT}&t={i}&r={r}"
        c = hashlib.md5(target.encode()).hexdigest()
        return "{},{},{}".format(i, r, c)

    async def get_roles(self):
        logger.info("准备获取账号信息...")
        response = {}
        try:
            response = await self.request("get", CONFIG.ROLE_URL)
            message = response["message"]
        except Exception as e:
            raise Exception(e)
        if response.get("retcode", 1) != 0 or response.get("data", None) is None:
            raise Exception(message)
        logger.info("账号信息获取完毕")
        return response

    async def get_info(self):
        user_game_roles = await self.get_roles()
        role_list = user_game_roles.get("data", {}).get("list", [])
        if not role_list:
            raise Exception(user_game_roles.get("message", "Role list empty"))
        logger.info(f"当前账号绑定了 {len(role_list)} 个角色")
        info_list = []
        # cn_gf01:  天空岛
        # cn_qd01:  世界树
        self._region_list = [(i.get("region", "NA")) for i in role_list]
        self._region_name_list = [(i.get("region_name", "NA")) for i in role_list]
        self._uid_list = [(i.get("game_uid", "NA")) for i in role_list]
        logger.info("准备获取签到信息...")
        for i in range(len(self._uid_list)):
            info_url = CONFIG.INFO_URL.format(
                self._region_list[i], CONFIG.ACT_ID, self._uid_list[i]
            )
            try:
                content = await self.request("get", info_url)
                info_list.append(content)
            except Exception as e:
                raise Exception(e)
        if not info_list:
            raise Exception("User sign info list is empty")
        logger.info("签到信息获取完毕")
        return info_list

    async def run(self):
        info_list = await self.get_info()
        message_list = []
        for i in range(len(info_list)):
            today = info_list[i]["data"]["today"]
            total_sign_day = info_list[i]["data"]["total_sign_day"]
            awards_rsp = await self.request("get", CONFIG.AWARD_URL)
            awards = awards_rsp["data"]["awards"]
            uid = str(self._uid_list[i])
            logger.info(f"准备为旅行者 {i + 1} 号签到...")
            message = {
                "today": today,
                "region_name": self._region_name_list[i],
                "uid": uid,
                "total_sign_day": total_sign_day,
                "end": "",
            }
            if info_list[i]["data"]["is_sign"] is True:
                message["award_name"] = awards[total_sign_day - 1]["name"]
                message["award_cnt"] = awards[total_sign_day - 1]["cnt"]
                message["status"] = f"👀 旅行者 {i + 1} 号, 你已经签到过了哦"
                message_list.append(CONFIG.MESSAGE_TEMPLATE.format(**message))
                continue
            else:
                message["award_name"] = awards[total_sign_day]["name"]
                message["award_cnt"] = awards[total_sign_day]["cnt"]
            if info_list[i]["data"]["first_bind"] is True:
                message["status"] = f"💪 旅行者 {i + 1} 号, 请先前往米游社App手动签到一次"
                message_list.append(CONFIG.MESSAGE_TEMPLATE.format(**message))
                continue
            data = {
                "act_id": CONFIG.ACT_ID,
                "region": self._region_list[i],
                "uid": self._uid_list[i],
            }
            self.s.headers.update(
                {
                    "x-rpc-device_id": uuid.uuid3(
                        uuid.NAMESPACE_URL, self.cookies
                    ).hex.upper(),
                    "x-rpc-client_type": "5",
                    "x-rpc-app_version": CONFIG.APP_VERSION,
                    "DS": self.get_ds(),
                }
            )
            try:
                response = await self.request(
                    "post",
                    CONFIG.SIGN_URL,
                    json=data,
                )
                logger.info(response)
            except Exception as e:
                logger.exception(e)
                raise Exception(e)
            code = response.get("retcode")
            # 0:      success
            # -5003:  already signed in
            if code != 0:
                message_list.append(response.get("message", json.dumps(response)))
                continue
            message["total_sign_day"] = total_sign_day + 1
            message["status"] = response["message"]
            message_list.append(CONFIG.MESSAGE_TEMPLATE.format(**message))
        logger.info("签到完毕")
        return "".join(message_list)


async def main(cookie_list):
    sem = asyncio.Semaphore(CONFIG.MAX_WORKER)
    task_list = []
    async with sem:
        for cookie in cookie_list:
            task_list.append(asyncio.tasks.create_task(Sign(cookie).run()))
    return await asyncio.gather(*task_list)


if __name__ == "__main__":
    # login_ticket account_id cookie_token
    cookie_list = []
    logger.info(f"🌀原神签到小助手检测到共配置了 {len(cookie_list)} 个帐号")
    result = asyncio.run(main(cookie_list))
    for item in result:
        logger.info(item)
    logger.info(f"任务结束")
