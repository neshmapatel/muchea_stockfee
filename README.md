# Muchea Stockfeed & Hardware

A dedicated Western Australian e-commerce platform and rural merchandise warehouse application built with **Ruby on Rails 8 (8.1.4)** and modern Hotwire (Turbo 8 + Stimulus).

Engineered specifically for the rural community of Muchea, the Chittering Valley, Bullsbrook, Gingin, Bindoon, and surrounding Western Australian pastoral and equine districts.

---

## Brand Logo & Offline Signage Alignment
The digital brand mark has been directly aligned with the physical storefront signboard at 14 Great Northern Highway, Muchea:
- **Brand Title:** `MUCHEA STOCK FEED & HARDWARE`
- **Tagline:** *"For Farms, Homes & Life"*
- **Motto:** *"Quality for a Strong Tomorrow"*
- **5 Core Pillars:** Stockfeed (feed sack), Hardware (hammer), Farm Supplies (fence), Pet Care (paw print), Rural Essentials (wheelbarrow).
- **Mascot Livestock:** Australian Stock Horse, Holstein Dairy Cow, Merino Sheep, and Rooster in front of the WA countryside panorama.
- **Asset Paths:**
  - `app/assets/images/muchea_logo.jpg`
  - `public/images/muchea_logo.jpg`
  - `public/images/muchea_storefront_board.jpg` (Original photo of the installed store signage)

---

## Key Features

1. **Dual Department Catalog:**
   - **Stockfeed & Animal Nutrition:** Equine feeds (Hygain, Mitavite, Thompson & Redwood), steam-cleaned Lucerne chaff, prime oaten round bales, beef cattle finisher, lick blocks, poultry layer pellets, Cobber working dog food.
   - **Rural Hardware & Farm Supplies:** Waratah Cyclone 7/90/30 fencing wire, bitumen star pickets, Philmac poly pipe fittings, 1000L concrete stock water troughs.
2. **Multi-Variant Packaging & Bulk Savings:**
   - Single 20kg retail bags, 40-bag full pallets (with bulk discounts), and 1-tonne bulk bags.
3. **Australian Rural Logistics & Fulfillment:**
   - **Scheduled Weekly Farm Runs:** Mon/Wed/Fri (Muchea & Bullsbrook), Tue/Thu (Chittering Valley & Upper Swan), Wed (Gingin, Bindoon, Wannamal).
   - **Warehouse Drive-Thru Bag Loading:** Drive-in ute and trailer loading with forklift assistance at 14 Great Northern Highway, Muchea WA 6501.
4. **ATO Compliant Billing & 10% GST:**
   - All prices clearly displayed as `AU$ (inc. GST)`.
   - Automated ATO-compliant Tax Invoice generation with registered **ABN: 48 619 284 921**.
5. **Australian Payment Processing:**
   - Stripe integration supporting AUD Cards (Visa, Mastercard, AMEX), Apple Pay, Google Pay, and Afterpay.
6. **Live Consignment & Order Tracking:**
   - Dedicated tracking portal (`/tracking/:code`) with real-time 4-step progress: *Paid -> Packing at Muchea -> Dispatched on WA Truck / Ready in Bay -> Delivered to Gate/Shed*.
7. **Warehouse Operations Admin:**
   - Live Inventory Manager with safety stock threshold alerts, inline stock adjustments, and inventory audit logs.
   - Order Dispatch Manager with 1-click status transitions and printable warehouse packing slips.
8. **Western Australian Local SEO:**
   - JSON-LD Structured Data for `LocalBusiness` and `Product`.
   - Dynamic Google XML Sitemap (`/sitemap.xml`).

---

## Quick Start

### 1. Requirements
- Ruby `3.2.2+`
- SQLite 3 with WAL mode

### 2. Setup & Database
```bash
bundle install
bundle exec rails db:migrate
bundle exec rails db:seed
```

### 3. Start the Server
```bash
bundle exec rails server -p 3000
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## Key URLs

- **Storefront:** `http://localhost:3000/`
- **Product Catalog:** `http://localhost:3000/products`
- **Delivery Schedule & Zones:** `http://localhost:3000/delivery-schedule`
- **Drive-Thru Bag Loading:** `http://localhost:3000/drive-thru-pickup`
- **Cart & Checkout:** `http://localhost:3000/cart`
- **Order Tracking:** `http://localhost:3000/tracking` (Demo code: `WA7821AU` or `WA9934AU`)
- **Warehouse Admin Portal:** `http://localhost:3000/admin`
- **Live Inventory Manager:** `http://localhost:3000/admin/inventory`
- **Google Dynamic Sitemap:** `http://localhost:3000/sitemap.xml`

---

## Test Suite
Run the comprehensive integration test suite:
```bash
bundle exec rails test test/integration/storefront_flow_test.rb
```
