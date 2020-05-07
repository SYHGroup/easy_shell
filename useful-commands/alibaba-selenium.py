import asyncio
import importlib
import os
import pickle
import re
import sys
import time
import itertools
import aiohttp
from selenium import webdriver
from yarl import URL
import logging

logging.basicConfig(
    format="%(asctime)s - %(filename)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)

logger = logging.getLogger("Alibaba Image Fetcher Selenium")

headers = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36",
}


async def get_id_list(s, begin_page):
    async with s.get(
        URL(
            f"https://search.1688.com/service/marketOfferResultViewService?keywords=****&beginPage={begin_page}&pageSize=20"
        )
    ) as resp:
        result = await resp.json(content_type=None)
    results = result.get("data").get("data").get("offerList")
    result_ids = [results[i].get("id") for i in range(len(results))]
    return result_ids


# https://stackoverflow.com/questions/53039551/selenium-webdriver-modifying-navigator-webdriver-flag-to-prevent-selenium-detec
# https://stackoverflow.com/questions/33225947/can-a-website-detect-when-you-are-using-selenium-with-chromedriver
def hide_driver(driver):
    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {
            "source": """
                Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
                })
            """
        },
    )
    driver.execute_cdp_cmd("Network.enable", {})
    driver.execute_cdp_cmd(
        "Network.setExtraHTTPHeaders", {"headers": {"User-Agent": "QQBrowser"}}
    )


async def main():
    pages = 100
    async with aiohttp.ClientSession(headers=headers) as s:
        tasks = [get_id_list(s, begin_page=i) for i in range(pages)]
        results = await asyncio.gather(*tasks)
    result_ids = list(dict.fromkeys(itertools.chain.from_iterable(results)))
    logger.info(result_ids)
    logger.info(f"Got {len(result_ids)} tiles")

    options = webdriver.ChromeOptions()
    driver = webdriver.Chrome(options=options)

    for result_id in result_ids:
        logger.info(result_id)
        url = f"https://detail.1688.com/offer/{result_id}.html"
        driver.get(url=url)
        hide_driver(driver)
        while (
            "https://detail.1688.com/offer/" not in driver.current_url
            or "nocaptcha" in driver.page_source
        ):
            time.sleep(1)
        logger.info(driver.current_url)
        result = driver.page_source
        imgs = re.findall(r"&quot;original&quot;:&quot;(\S+.jpg)&quot;", result)
        logger.info(imgs)
        with open("images.txt", "a", encoding="utf8") as file:
            for i in imgs:
                file.write(f"{i}\n")


if __name__ == "__main__":
    asyncio.run(main())
