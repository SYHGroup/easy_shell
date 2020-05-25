import asyncio
import json
import logging
import os
import re
import sys
import time

import aiohttp
from bs4 import BeautifulSoup

###
ASF = False
ASF_interface = "https://***/api/command"
ASF_password = "***"
###

logging.basicConfig(
    format="%(asctime)s - %(filename)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

logger = logging.getLogger("Steam")

headers = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36",
}
cookies = {"wants_mature_content": 1, "birthtime": 312825601}

async def main():
    async def asf(cmd):
        async with s.post(
            ASF_interface,
            json={"Command": cmd},
            params={"password": "simonsmh"},
        ) as resp:
            return await resp.json()

    async def get_id(sku, free=True):
        async with s.get(f"https://store.steampowered.com/app/{sku}/") as resp:
            sub = await resp.text()
        sub_soup = BeautifulSoup(sub, "lxml")
        subname = sub_soup.find(
            "form",
            action="https://store.steampowered.com/checkout/addfreelicense/"
            if free
            else "https://store.steampowered.com/cart/",
        )
        if not subname:
            return
        if not sub_soup.select("p.game_purchase_discount_quantity"):
            return
        logger.info(f"https://store.steampowered.com/app/{sku} Is still discounting.")
        subid = subname.get("name")[12:]
        if ASF:
            result = await asf(f"owns asf sub/{subid}")
            if not re.search(r"Not owned yet", result.get("Result")):
                logger.info(f"app/{sku} Is owned.")
                return
            logger.info(f"app/{sku} Not owned yet sub/{subid}")
        return subid

    async with aiohttp.ClientSession(cookies=cookies, headers=headers) as s:
        async with s.get("https://barter.vg/giveaways/json/") as resp:
            fetch = await resp.json()
        logger.info("Fetching giveaways")
        skus = [
            info.get("sku")
            for num, info in fetch.items()
            if info.get("type_id") == 3 and info.get("platform_id") == 1
        ]
        tasks = [get_id(i) for i in skus]
        subids = [i for i in await asyncio.gather(*tasks) if i]
        if subids:
            if ASF:
                logger.info(f"Adding licenses from asf {subids}")
                result = await asf(f"addlicense asf {' '.join(subids)}")
                logger.info(f"{result.get('Message')}\n{result.get('Result')}")
            else:
                logger.info(f"Games might be avaliable {subids}")
        else:
            logger.info("No games are avaliable for you.")


if __name__ == "__main__":
    asyncio.run(main())
