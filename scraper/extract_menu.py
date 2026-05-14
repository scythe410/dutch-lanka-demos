#!/usr/bin/env python3
"""
Extract Dutch Lanka menu data from Uber Eats page source.
Parses the JSON-LD structured data embedded in the HTML, and also
scrapes item-level image URLs from the HTML DOM where available.

Outputs: menu.json  — ready to seed Firestore or use in the app.
"""

import json
import re
import sys
from pathlib import Path

HTML_FILE = Path(__file__).parent / "page-source.html"
OUTPUT_FILE = Path(__file__).parent / "menu.json"


def extract_jsonld(html: str) -> dict:
    """Pull the Restaurant JSON-LD block from the page."""
    # The JSON-LD is inside a <script type="application/ld+json"> tag
    # The HTML uses HTML entities so we look for the pattern
    pattern = r'type="application/ld\+json">(\{[^<]+\})</script>'
    matches = re.findall(pattern, html)
    for raw in matches:
        # Uber Eats uses unicode escapes like \u002F for /
        decoded = raw.replace("\\u002F", "/")
        try:
            data = json.loads(decoded)
            if data.get("@type") == "Restaurant":
                return data
        except json.JSONDecodeError:
            continue
    raise ValueError("Could not find Restaurant JSON-LD in page source")


def extract_item_images(html: str) -> dict[str, str]:
    """
    Extract per-item image URLs from the HTML.
    Uber Eats uses data-testid="store-item-<uuid>" and nearby <img> or
    background-image style attributes.  Since most images are lazy-loaded
    (placeholder divs), we also look for srcSet/src attributes on <img> tags
    near the item UUIDs.
    """
    images = {}

    # Find all item UUIDs used in the page
    item_uuids = re.findall(r'data-testid="store-item-([0-9a-f\-]{36})"', html)

    # For each UUID, look for nearby image references
    # The carousel items have actual <img> tags with srcSet
    for uuid in set(item_uuids):
        # Look for image URLs near this UUID (within ~2000 chars after the UUID reference)
        uuid_positions = [m.start() for m in re.finditer(re.escape(uuid), html)]
        for pos in uuid_positions:
            chunk = html[pos:pos + 3000]
            # Look for srcSet or src with image URLs
            src_match = re.search(
                r'(?:src|srcSet)="(https://tb-static\.uber\.com/prod/image-proc/processed_images/[^"]+)"',
                chunk
            )
            if src_match:
                url = src_match.group(1)
                # If srcSet, take the first (smallest) URL
                if "," in url:
                    url = url.split(",")[0].strip()
                if " " in url:
                    url = url.split(" ")[0]
                images[uuid] = url
                break

    return images


def extract_item_uuid_name_map(html: str) -> dict[str, str]:
    """
    Build a map from item UUID to item name by parsing the HTML.
    Each store-item div is followed by rich-text spans containing the name.
    """
    uuid_to_name = {}
    # Pattern: data-testid="store-item-UUID" ... rich-text with name
    item_blocks = re.finditer(
        r'data-testid="store-item-([0-9a-f\-]{36})"',
        html
    )
    for match in item_blocks:
        uuid = match.group(1)
        if uuid in uuid_to_name:
            continue
        # Get the chunk after this match to find the item name
        start = match.end()
        chunk = html[start:start + 2000]
        # The first rich-text span with class containing "_di" is the item name
        name_match = re.search(
            r'class="[^"]*_di[^"]*"[^>]*>([^<]+)</span>',
            chunk
        )
        if name_match:
            name = name_match.group(1).strip()
            # Clean up multi-line names
            name = re.sub(r'\s+', ' ', name)
            uuid_to_name[uuid] = name

    return uuid_to_name


def build_menu(jsonld: dict, item_images: dict, uuid_name_map: dict) -> dict:
    """Transform the JSON-LD into a clean app-ready format."""
    # Reverse the uuid_name_map: name -> uuid
    name_to_uuid = {}
    for uuid, name in uuid_name_map.items():
        name_lower = name.lower().strip()
        name_to_uuid[name_lower] = uuid

    restaurant = {
        "name": jsonld.get("name", ""),
        "cuisines": jsonld.get("servesCuisine", []),
        "rating": jsonld.get("aggregateRating", {}).get("ratingValue"),
        "reviewCount": jsonld.get("aggregateRating", {}).get("reviewCount"),
        "phone": jsonld.get("telephone", ""),
        "location": {
            "latitude": jsonld.get("geo", {}).get("latitude"),
            "longitude": jsonld.get("geo", {}).get("longitude"),
        },
        "restaurantImages": jsonld.get("image", []),
    }

    categories = []
    menu_sections = jsonld.get("hasMenu", {}).get("hasMenuSection", [])

    for section in menu_sections:
        category = {
            "name": section.get("name", ""),
            "items": [],
        }

        for item in section.get("hasMenuItem", []):
            name = item.get("name", "")
            description = item.get("description", "")
            price_str = item.get("offers", {}).get("price", "0")
            currency = item.get("offers", {}).get("priceCurrency", "LKR")

            # Try to match with an image
            name_lower = name.lower().strip()
            uuid = name_to_uuid.get(name_lower)
            image_url = item_images.get(uuid, None) if uuid else None

            menu_item = {
                "name": name,
                "description": description if description else None,
                "price": float(price_str),
                "currency": currency,
                "imageUrl": image_url,
            }
            category["items"].append(menu_item)

        categories.append(category)

    return {
        "restaurant": restaurant,
        "categories": categories,
        "totalItems": sum(len(c["items"]) for c in categories),
        "totalCategories": len(categories),
    }


def main():
    print(f"Reading {HTML_FILE}...")
    html = HTML_FILE.read_text(encoding="utf-8")

    print("Extracting JSON-LD structured data...")
    jsonld = extract_jsonld(html)

    print("Extracting item images from HTML...")
    item_images = extract_item_images(html)
    print(f"  Found {len(item_images)} item images")

    print("Building UUID → name map...")
    uuid_name_map = extract_item_uuid_name_map(html)
    print(f"  Mapped {len(uuid_name_map)} unique items")

    print("Building menu JSON...")
    menu = build_menu(jsonld, item_images, uuid_name_map)

    OUTPUT_FILE.write_text(json.dumps(menu, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\n✅ Saved {menu['totalItems']} items across {menu['totalCategories']} categories to {OUTPUT_FILE}")

    # Print summary
    for cat in menu["categories"]:
        items_with_images = sum(1 for i in cat["items"] if i["imageUrl"])
        print(f"  • {cat['name']}: {len(cat['items'])} items ({items_with_images} with images)")


if __name__ == "__main__":
    main()
