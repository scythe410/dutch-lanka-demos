# Design system — Dutch Lanka

The visual language for the Dutch Lanka bakery app. Both the customer app and the manager app pull from this single system. Every component, color, and spacing rule below has a place in `packages/shared/lib/theme/` or `packages/shared/lib/widgets/` — nothing in this doc should be reimplemented inside an app.

---

## 1. Brand

Dutch Lanka is a single-location bakery in Sri Lanka. The visual language is **warm, friendly, appetizing** — built around large, high-quality food photography and a signature scalloped frame that suggests soft pastry edges. The palette leans into oranges and creams (think golden croissant glaze on a cream-colored tablecloth) without ever feeling clinical or fast-food.

Core feelings to evoke: freshly baked, family-run, gentle. Avoid: corporate, sterile, edgy, neon.

---

## 2. Color palette

| Token | Name | Hex | RGB | Usage |
|---|---|---|---|---|
| `colorPrimary` | Warm Orange | `#FFA951` | 255, 169, 81 | Primary CTAs, brand accents, active icons, the wordmark |
| `colorSurface` | Soft Cream | `#FAF3E1` | 250, 243, 225 | Page backgrounds, default surfaces |
| `colorOnPrimary` | White | `#FFFFFF` | 255, 255, 255 | Text/icons on orange, lifted CTA cards |
| `colorMuted` | Silver | `#C0C0C0` | 192, 192, 192 | Disabled states, subtle borders, inactive dividers |
| `colorOnSurface` | Black | `#000000` | 0, 0, 0 | Body text and headings on cream |

### Usage rules

- **Cream is the canvas.** Most screens have a Soft Cream background, with white cards or orange highlights floating on it.
- **Orange anchors action.** Every primary button, the brand wordmark, the active item in a list, the badge on a bell icon — all Warm Orange.
- **Pure white is reserved** for surfaces that need to lift off the cream — primary buttons-with-orange-text, product card backgrounds, the inner CTA pill on the product detail screen. Not used as a page background.
- **Black for text.** On Soft Cream, you can drop body copy to ~80% opacity to soften it. Headings stay full black.
- **Silver only** for disabled states, dividers, and subtle borders. It's not a "light gray" — it's a specific token for "this is inactive."
- **No additional accent colors.** Status (success, error, warning) is communicated through iconography and copy, not green/red/yellow. If a real need emerges (e.g. a destructive confirm), bring it back to design — don't drop a Material red into the codebase.

### Don'ts

- Don't put black text on Warm Orange — use white.
- Don't use Soft Cream on Warm Orange (low contrast).
- Don't introduce additional grays. Use Silver, or a percentage opacity of black.

---

## 3. Typography

Work Sans, three weights only.

| Style | Weight | Size | Line height | Use |
|---|---|---|---|---|
| Display | Semi Bold (600) | 28 | 1.2 | Screen-level titles, hero headers |
| Heading | Semi Bold (600) | 20 | 1.3 | Section titles, dialog titles |
| Subheading | Medium (500) | 16 | 1.4 | List item titles, inline emphasis |
| Body | Regular (400) | 14 | 1.5 | Paragraph text, descriptions |
| Caption | Regular (400) | 12 | 1.4 | Helper text, metadata, "Recent Code" links |
| Button | Medium (500) | 16 | 1.0 | All button labels |

### Two-tone titles

A signature pattern: titles split into orange and black halves to draw the eye. Used on onboarding, profile, and section dividers.

> **Order your <span style="color:#FFA951">favorite treat</span> just a few taps.**
>
> **Other <span style="color:#FFA951">Pages</span>**
>
> **Welcome <span style="color:#FFA951">to Dutch Lanka!</span>**

The orange portion is always the noun being celebrated (the item or the brand). Implement with `RichText` or a small `TwoToneTitle` widget in `shared/widgets/`.

### Loading the font

```dart
// theme/text_theme.dart
import 'package:google_fonts/google_fonts.dart';

final TextTheme appTextTheme = GoogleFonts.workSansTextTheme().copyWith(
  displayLarge:  GoogleFonts.workSans(fontSize: 28, fontWeight: FontWeight.w600),
  headlineSmall: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w600),
  titleMedium:   GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w500),
  bodyMedium:    GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall:     GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w400),
  labelLarge:    GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w500),
);
```

---

## 4. Spacing

Use an **8pt grid**. Allowed values: `4, 8, 12, 16, 24, 32, 48`. Define as constants in `theme/spacing.dart`:

```dart
abstract class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}
```

Standard screen edge padding: **`24px`** (`Space.xl`). Standard vertical rhythm between blocks: **`24px`**. Within a card: **`16px`**.

---

## 5. Border radius

| Component | Radius |
|---|---|
| Cards / containers | `16px` |
| Primary buttons (full-width CTAs) | `28px` (pill — half of 56px height) |
| Secondary buttons | `28px` (matches primary) |
| Icon tiles | `12px` |
| Input fields | `12px` |
| Bottom sheets | `24px` (top corners only) |
| Avatar | `50%` (circular) |

---

## 6. Iconography

Lucide icon set, used consistently. From the design: arrow-left, mail, lock, map-pin, shopping-cart, bell, search, sliders, heart, alarm-clock, star, home, sparkles (magic-wand), calendar, phone, users, settings, chevron-right.

Default presentation: a Warm Orange icon on a Soft Cream rounded-square tile (12px corners, 48×48 tile, 24px icon). Inactive: Silver icon on cream tile.

In navigation contexts (back arrows, chevrons), drop the tile and render the icon alone in Warm Orange.

Use the `lucide_icons` Flutter package — line weights match the design. **Do not mix in icons from Material or Cupertino sets** — the line weights clash.

---

## 7. Signature pattern: scalloped edge

The most distinctive visual element. An orange section meets a cream section with a soft scalloped (wavy) curve, like the rim of a fluted tart shell. It appears:

- Below the hero photo on the **product detail** screen — the photo floats above, the orange panel curves up to meet it
- Above the bottom CTA area on **onboarding** screens
- On the **add-reminder** form, between the date picker and the form fields
- On the **delivery tracking** card

### Implementation

A custom `ClipPath` clipper, defined once in `shared/widgets/scalloped_clipper.dart`:

- Wave amplitude: ~12px
- Wave period: ~40px
- Direction: convex bumps point upward when the orange is below, downward when the orange is above

Wrap the orange section in a `ClipPath(clipper: ScallopedClipper(direction: ScallopDirection.top), child: ...)`. Alternative: pre-render an SVG asset for the wave edge if performance is an issue, but the ClipPath approach is fine on modern devices.

---

## 8. Components

Every component below lives in `packages/shared/lib/widgets/` and is imported by both apps.

### Primary button — `PrimaryButton`
The dominant CTA. Used for "Get Started", "Verify", "Sign Up", "Save", "Next".

- Background: Warm Orange `#FFA951`
- Text: White, Work Sans Medium 16
- Height: `56px`
- Radius: `28px` (pill)
- Horizontal padding: `24px`
- Optional leading icon: 20px, white, 8px gap before label
- Disabled: 40% opacity, no shadow
- Tap: scale to 0.97 over 100ms, then back

### Secondary button — `SecondaryButton`
Used inside orange contexts (e.g. "Add to cart" on the product detail orange panel).

- Background: White
- Text: Warm Orange, Work Sans Medium 16
- Same dimensions, radius, animation as primary

### OTP input — `OtpInput`
A row of N digit boxes (default 4, configurable to 6).

- Each box: `56×64`, Soft Cream background, `12px` radius
- Resting border: none
- Focused border: `1.5px` Warm Orange
- Filled digit: black, Work Sans Semi Bold 24, centered
- Gap between boxes: `12px`
- Auto-advance on input, auto-focus-prev on backspace
- Below the input: caption row "Didn't receive OTP? **Recent Code**" — link in Warm Orange, underlined

### Input field — `AppTextField`
Standard form field.

- Background: Soft Cream slightly darkened (or `colorSurface` over cream — same color = subtle inset look)
- Resting border: none
- Focused border: `1.5px` Warm Orange
- Text: black, Work Sans Regular 14
- Placeholder: black at 50% opacity
- Helper text below: `12px`, Silver
- Error text: `12px`, black (no red — use copy + an alert icon)

### Product card — `ProductCard`
Used in the home/browse grid.

- Background: White, `16px` radius
- Square product image at top, fills the card width, `12px` radius on top corners
- Below image, `16px` padding: title (Subheading), price in Warm Orange (Heading), star rating row
- Subtle shadow: `blur 8px, y-offset 2px, 8% black`
- Tap target: full card

### Product detail panel — `ProductDetailPanel`
The signature layout. The full screen consists of:

1. **Top half** (~40% of screen): cream background, large product photo floating, optional back button (top-left) and favorite heart (top-right).
2. **Bottom half**: Warm Orange panel with a **scalloped top edge**. The product photo dips into the panel slightly (the photo's bottom 10–15% overlaps the orange).
3. Inside the orange panel:
   - Title (Heading, black)
   - Star rating (4–5 small stars in white, filled)
   - "Description" subheading (Subheading, black) + paragraph (Body, black) with "Read More" truncation in white
   - "Ingredients" subheading + horizontal scroll of small white square tiles (`64×64`, `12px` radius) with ingredient thumbnails. "See All" link top-right.
4. **Floating CTA** (bottom): a white pill button "Add to cart" with orange text, plus a quantity stepper at top-right of the orange panel. Total price displayed bottom-left.

This same panel is reused for any "drill into one item" experience.

### Quantity stepper — `QuantityStepper`
A pill control: `−`, count, `+`. Two variants:

- **On orange**: white circles for the buttons, white count text
- **On cream**: orange circles, black count

`32px` button diameter, `48px` between buttons (with the count centered).

### Bottom sheet
- Top corners `24px`, bottom corners `0`
- Cream background
- Drag handle: `40×4`, Silver, centered, `12px` from top
- Content padding: `24px`
- Used for: address picker, quick filters, customization options that don't warrant a full screen.

### Floating tracking card — `DeliveryTrackingCard`
Sits at the bottom of the order tracking screen, above the map.

- Warm Orange background, `16px` radius (all corners)
- `24px` padding
- Left column: courier name (Heading, black), "Food Courier" caption (Caption, black 80%), location (Body, black), ETA (Body, black)
- Right column: circular phone-call icon button (white background, orange icon, `48px`)

### KPI tile — `KpiTile` (manager app only)
Dashboard at-a-glance metric.

- White background, `16px` radius, `16px` padding
- Top: caption label (Caption, black 60%) — e.g. "Today's sales"
- Center: value (Display, Warm Orange) — e.g. "LKR 24,500"
- Bottom-right: small chevron-right icon if tappable for drill-down

---

## 9. Screen archetypes

The customer app has 8 archetype screens; every other customer screen is a variant of one.

| Archetype | Pattern | Reference |
|---|---|---|
| **Onboarding carousel** | Full-bleed photo top, scalloped cream panel bottom, two-tone title, page dots, primary CTA. 3 slides: Welcome / Browse / Order. | "Other Pages" image, slides 1–3 |
| **Auth — email + code** | Cream bg, centered title ("Verify Code"), email shown in orange below, OTP input, system numpad at bottom, primary CTA. | "Other Pages" image, OTP slide |
| **Home / browse** | Search bar with orange icon (top), category pill row (horizontal scroll), grid of `ProductCard`s (2 columns), bottom nav bar. | (To be designed in next iteration) |
| **Product detail** | `ProductDetailPanel` as described in §8. | "Add to cart" full-screen image |
| **Cart / Checkout** | List of line items with `QuantityStepper`s on cream, totals card (white, `16px` radius), address card, primary CTA at bottom. | (To be designed) |
| **Order tracking** | Map fills upper ~65%, `DeliveryTrackingCard` with scalloped top edge at bottom, status pills overlaying the map. | "Other Pages" image, last slide |
| **Profile / Settings** | Avatar + name on cream (centered), vertical list of menu rows (orange icon + label + chevron-right), "Sign Up"/"Sign Out" primary CTA at bottom. | "Other Pages" image, profile slide |
| **Form (e.g. add reminder, add address)** | Cream bg, scalloped orange section at top with the picker/headline, white input fields below, primary CTA at bottom. | "Other Pages" image, "Add your reminder" slide |

---

## 10. Manager app design

The manager app uses the **same palette, type system, and component library**. Differences from the customer app:

- **Less photography, more data density.** Where the customer app uses a hero image, the manager app often uses a `KpiTile` row.
- **Dashboard screen** with three KPI tiles in a row (Today's sales, Active orders, Low stock count) above a list of incoming orders.
- **Orders list** uses compact rows (avatar + customer name + total + status pill) rather than the customer app's image-heavy cards.
- **Charts** (sales over time, top products) use `fl_chart` with the data line in Warm Orange against a cream background. Axes in Silver. No multi-color chart palettes.
- **The scalloped pattern still appears** on the dashboard header banner and the login screen — but mostly absent from data-heavy screens to keep them scannable.
- **Bottom nav has 4 tabs:** Dashboard, Orders, Products, More.

These manager screens are not in the design files yet — design them before implementing to match the system established in the customer app. When in doubt, copy a customer-app pattern and strip the photography.

---

## 11. Asset pipeline

| Asset | Dimensions | Format | Notes |
|---|---|---|---|
| Product main image | 1080×1080 | JPEG, ≤ 200KB | Square, transparent background preferred (cookies/donuts on white) |
| Ingredient thumbnail | 256×256 | PNG, transparent | For the "Ingredients" tiles |
| Topping thumbnail | 256×256 | PNG, transparent | For customization screens |
| Onboarding photo | 1242×1564 | JPEG | High-saturation food photography |
| Marketing banner | 1242×620 | JPEG | Promo carousel on home screen |

Storage layout in Firebase Storage:
```
products/{productId}/main.jpg
products/{productId}/extra_1.jpg
ingredients/{ingredientId}.png
toppings/{toppingId}.png
marketing/onboarding/welcome.jpg
marketing/banners/{bannerId}.jpg
```

All product/marketing assets are uploaded by managers via the manager app. Only managers (write) and authenticated users (read) per `storage.rules`.

---

## 12. Don'ts (consolidated)

- Don't introduce additional accent colors (greens, blues, reds) for status. Use orange + iconography.
- Don't use sharp corners on tappable elements. Everything that's tapped rounds (12, 16, or 28).
- Don't use drop shadows beyond `8px blur, 8% black`. The look is flat-warm, not skeuomorphic.
- Don't mix icon families. Lucide only.
- Don't put black text on Warm Orange.
- Don't hardcode hex codes, font weights, or radii in widget files. Reach for the theme.
- Don't reimplement a component locally if it exists in `shared/widgets/`. Extend it instead.
- Don't add a "dark mode" without designing it deliberately. The current palette is light-mode-only.

---

## 13. Component checklist

Build order, with dependencies. Each component lives in `packages/shared/lib/widgets/` (or `theme/`) and is exported from `package:dutch_lanka_shared`.

- [ ] `theme/colors.dart` — color tokens
- [ ] `theme/spacing.dart` — spacing constants
- [ ] `theme/text_theme.dart` — text styles
- [ ] `theme/app_theme.dart` — `ThemeData` composition
- [ ] `widgets/scalloped_clipper.dart`
- [ ] `widgets/two_tone_title.dart`
- [ ] `widgets/primary_button.dart`
- [ ] `widgets/secondary_button.dart`
- [ ] `widgets/app_text_field.dart`
- [ ] `widgets/otp_input.dart`
- [ ] `widgets/quantity_stepper.dart`
- [ ] `widgets/icon_tile.dart`
- [ ] `widgets/product_card.dart`
- [ ] `widgets/product_detail_panel.dart`
- [ ] `widgets/delivery_tracking_card.dart`
- [ ] `widgets/kpi_tile.dart`
- [ ] `widgets/bottom_sheet_scaffold.dart`

Build in this order so each component can compose the ones above it.
