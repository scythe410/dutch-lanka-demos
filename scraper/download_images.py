#!/usr/bin/env python3
"""
Post-process menu.json:
  1. Remove items without images
  2. Remove empty categories
  3. Download images with clean filenames (kebab-case of item name)
  4. Update imageUrl to local path
"""

import json
import re
import urllib.request
from pathlib import Path

MENU_FILE = Path(__file__).parent / "menu.json"
IMAGES_DIR = Path(__file__).parent / "images"


def slugify(name: str) -> str:
    """Convert item name to a clean kebab-case filename."""
    s = name.lower().strip()
    s = re.sub(r"[^\w\s-]", "", s)       # remove special chars
    s = re.sub(r"[\s_]+", "-", s)         # spaces/underscores → hyphens
    s = re.sub(r"-+", "-", s)             # collapse multiple hyphens
    return s.strip("-")


def download_image(url: str, filepath: Path) -> bool:
    """Download an image from URL to filepath."""
    try:
        req = urllib.request.Request(url, headers={
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
        })
        with urllib.request.urlopen(req, timeout=15) as resp:
            filepath.write_bytes(resp.read())
        return True
    except Exception as e:
        print(f"    ❌ Failed: {e}")
        return False


def main():
    print("Loading menu.json...")
    menu = json.loads(MENU_FILE.read_text(encoding="utf-8"))

    total_before = menu["totalItems"]
    cats_before = menu["totalCategories"]

    # Create images directory
    IMAGES_DIR.mkdir(exist_ok=True)

    # Process categories
    cleaned_categories = []
    total_downloaded = 0
    total_kept = 0

    for cat in menu["categories"]:
        # Keep only items with images
        items_with_images = [item for item in cat["items"] if item["imageUrl"]]

        if not items_with_images:
            print(f"  🗑  Removing empty category: {cat['name']}")
            continue

        removed = len(cat["items"]) - len(items_with_images)
        if removed > 0:
            removed_names = [i["name"] for i in cat["items"] if not i["imageUrl"]]
            print(f"  ⚠️  {cat['name']}: removed {removed} items without images: {removed_names}")

        # Download images and update paths
        for item in items_with_images:
            slug = slugify(item["name"])
            filename = f"{slug}.jpeg"
            filepath = IMAGES_DIR / filename

            if filepath.exists():
                print(f"  ⏭  {item['name']} — already downloaded")
            else:
                print(f"  ⬇  {item['name']} → {filename}")
                success = download_image(item["imageUrl"], filepath)
                if not success:
                    # Keep the remote URL if download fails
                    continue
                total_downloaded += 1

            # Update to local path
            item["imageUrl"] = f"images/{filename}"
            total_kept += 1

        cat["items"] = items_with_images
        cleaned_categories.append(cat)

    menu["categories"] = cleaned_categories
    menu["totalItems"] = sum(len(c["items"]) for c in cleaned_categories)
    menu["totalCategories"] = len(cleaned_categories)

    # Save updated menu
    MENU_FILE.write_text(json.dumps(menu, indent=2, ensure_ascii=False), encoding="utf-8")

    print(f"\n{'='*50}")
    print(f"  Before: {total_before} items, {cats_before} categories")
    print(f"  After:  {menu['totalItems']} items, {menu['totalCategories']} categories")
    print(f"  Removed: {total_before - menu['totalItems']} items without images")
    print(f"  Downloaded: {total_downloaded} images to scraper/images/")
    print(f"{'='*50}")
    print(f"\n[SUCCESS] Updated menu.json and downloaded images!")


if __name__ == "__main__":
    main()
