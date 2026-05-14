#!/usr/bin/env python3
"""
Selenium-based scraper to extract menu item images from the Uber Eats
Dutch Lanka page.

Opens Chrome in visible mode (non-headless) to avoid bot detection,
scrolls to trigger lazy-loading, then matches image URLs to items
in menu.json.

Usage:
  source .venv/bin/activate
  python scrape_images.py
"""

import json
import re
import time
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

UBER_EATS_URL = "https://www.ubereats.com/store/dutch-lanka-restaurant-galle/sY5MHrxOWGyZfL7rXQKm4g"
MENU_FILE = Path(__file__).parent / "menu.json"
OUTPUT_FILE = Path(__file__).parent / "menu.json"


def create_driver() -> webdriver.Chrome:
    """Create a Chrome driver (visible, not headless) to bypass bot detection."""
    options = Options()
    # NOT headless — Uber Eats blocks headless Chrome
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument(
        "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    )
    options.add_experimental_option("excludeSwitches", ["enable-automation"])
    options.add_experimental_option("useAutomationExtension", False)

    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=options)

    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {"source": "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"},
    )
    return driver


def slow_scroll(driver: webdriver.Chrome, pause: float = 2.0, scroll_px: int = 500):
    """Scroll slowly to mimic human behavior and trigger lazy loads."""
    page_height = driver.execute_script("return document.body.scrollHeight")
    current = 0
    scroll_num = 0

    while current < page_height:
        current += scroll_px
        driver.execute_script(f"window.scrollTo({{top: {current}, behavior: 'smooth'}});")
        time.sleep(pause)
        scroll_num += 1
        # Page might grow as new content loads
        page_height = driver.execute_script("return document.body.scrollHeight")
        pos = driver.execute_script("return window.pageYOffset + window.innerHeight")
        print(f"  Scroll {scroll_num}: {pos}/{page_height}")
        if pos >= page_height - 10:
            break

    # Second pass — scroll back up and down faster
    print("  Second pass (up then down)...")
    driver.execute_script("window.scrollTo({top: 0, behavior: 'smooth'});")
    time.sleep(2)
    page_height = driver.execute_script("return document.body.scrollHeight")
    current = 0
    while current < page_height:
        current += 800
        driver.execute_script(f"window.scrollTo({{top: {current}, behavior: 'smooth'}});")
        time.sleep(0.8)
        page_height = driver.execute_script("return document.body.scrollHeight")
        pos = driver.execute_script("return window.pageYOffset + window.innerHeight")
        if pos >= page_height - 10:
            break


def extract_item_images(driver: webdriver.Chrome) -> dict[str, str]:
    """
    Extract item name → image URL mapping from the fully-loaded page.
    """
    images = {}

    # Find all store-item elements (both carousel and grid)
    store_items = driver.find_elements(By.CSS_SELECTOR, '[data-testid^="store-item-"]')
    print(f"\n  Found {len(store_items)} store-item elements")

    for item_el in store_items:
        try:
            # Get item name
            name_spans = item_el.find_elements(By.CSS_SELECTOR, '[data-testid="rich-text"]')
            if not name_spans:
                continue

            name = name_spans[0].text.strip()
            name = re.sub(r'\s+', ' ', name).strip()

            if not name or name.startswith("LKR") or name.startswith("•") or len(name) < 3:
                continue

            if name in images:
                continue

            # Find image
            img_url = None

            # <img> tags
            img_tags = item_el.find_elements(By.TAG_NAME, "img")
            for img in img_tags:
                src = img.get_attribute("src") or ""
                srcset = img.get_attribute("srcset") or ""

                if "tb-static.uber.com" in src and "image-proc" in src:
                    img_url = src
                    break
                if "tb-static.uber.com" in srcset:
                    # Take the highest-res from srcset
                    parts = [p.strip() for p in srcset.split(",") if "tb-static.uber.com" in p]
                    if parts:
                        img_url = parts[-1].split(" ")[0]
                    break

            # background-image
            if not img_url:
                all_divs = item_el.find_elements(By.CSS_SELECTOR, "div")
                for div in all_divs:
                    bg = driver.execute_script(
                        "return window.getComputedStyle(arguments[0]).backgroundImage;", div
                    )
                    if bg and "tb-static.uber.com" in bg:
                        url_match = re.search(r'url\(["\']?(https://[^"\')\s]+)["\']?\)', bg)
                        if url_match:
                            img_url = url_match.group(1)
                            break

            if img_url:
                images[name] = img_url
                print(f"    ✓ {name}")

        except Exception as e:
            continue

    return images


def match_and_update_menu(menu: dict, scraped_images: dict) -> int:
    """Match scraped image URLs to menu items by name."""
    matched = 0

    for category in menu["categories"]:
        for item in category["items"]:
            item_name = item["name"]

            # Direct match
            if item_name in scraped_images:
                item["imageUrl"] = scraped_images[item_name]
                matched += 1
                continue

            # Case-insensitive match
            for scraped_name, url in scraped_images.items():
                if scraped_name.lower().strip() == item_name.lower().strip():
                    item["imageUrl"] = url
                    matched += 1
                    break

    return matched


def main():
    print("Loading menu.json...")
    menu = json.loads(MENU_FILE.read_text(encoding="utf-8"))
    print(f"  {menu['totalItems']} items across {menu['totalCategories']} categories\n")

    print("Launching Chrome (visible mode to bypass bot detection)...")
    print("  ⚠️  A Chrome window will open — please don't interact with it!\n")
    driver = create_driver()

    try:
        print(f"Navigating to Uber Eats page...")
        driver.get(UBER_EATS_URL)

        # Wait for the store to load
        print("Waiting for store content to load...")
        try:
            WebDriverWait(driver, 30).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, '[data-testid="store-loaded"]'))
            )
            print("  ✅ Store loaded!")
        except Exception:
            # Try alternative selector
            try:
                WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located(
                        (By.CSS_SELECTOR, '[data-testid^="store-item-"]')
                    )
                )
                print("  ✅ Store items found!")
            except Exception:
                print("  ⚠️  Timeout — page may not have loaded fully.")
                # Save page source for debugging
                debug_file = Path(__file__).parent / "debug_page.html"
                debug_file.write_text(driver.page_source, encoding="utf-8")
                print(f"  Saved debug page source to {debug_file}")

        # Extra wait
        time.sleep(5)

        # Scroll to trigger lazy loading
        print("\nScrolling page to trigger lazy image loading...")
        slow_scroll(driver, pause=2.0, scroll_px=500)

        # Final wait
        print("\nWaiting for images to finish loading...")
        time.sleep(5)

        # Extract images
        print("\nExtracting item images...")
        scraped_images = extract_item_images(driver)
        print(f"\n📸 Scraped {len(scraped_images)} item images")

        if scraped_images:
            # Match to menu
            print("\nMatching images to menu items...")
            matched = match_and_update_menu(menu, scraped_images)
            print(f"  ✅ Matched {matched}/{menu['totalItems']} items")

            # Save
            OUTPUT_FILE.write_text(json.dumps(menu, indent=2, ensure_ascii=False), encoding="utf-8")
            print(f"\n✅ Updated {OUTPUT_FILE}")
        else:
            print("\n⚠️  No images found. The page may have been blocked or not loaded.")
            debug_file = Path(__file__).parent / "debug_page.html"
            debug_file.write_text(driver.page_source, encoding="utf-8")
            print(f"  Saved page source to {debug_file} for inspection")

        # Summary
        print("\n--- Category Summary ---")
        for cat in menu["categories"]:
            items_with_images = sum(1 for i in cat["items"] if i["imageUrl"])
            total = len(cat["items"])
            status = "✅" if items_with_images == total else ("⚠️" if items_with_images > 0 else "❌")
            print(f"  {status} {cat['name']}: {items_with_images}/{total} with images")

    finally:
        driver.quit()
        print("\nBrowser closed.")


if __name__ == "__main__":
    main()
