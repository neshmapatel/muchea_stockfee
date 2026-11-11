# Muchea Stockfeed & Hardware - Technical Architecture & Implementation Plan

## Executive Overview
**Muchea Stockfeed & Hardware** is a dedicated Australian e-commerce platform and rural merchandise hub engineered specifically for the rural community of Muchea, the Chittering Valley, Bullsbrook, Gingin, Bindoon, and surrounding Western Australian pastoral, equine, and hobby-farming regions.

Following a thorough analysis of regional competitors (**Wanneroo Stock Feeders** and **All Things Stock, Muchea**), this solution delivers a modern, high-performance, mobile-first web application powered by **Ruby on Rails 8 (latest 8.1.x omakase stack)**, incorporating Hotwire (Turbo 8 + Stimulus), Solid Queue, Solid Cache, SQLite3/PostgreSQL, Stripe payments with Australian payment methods (Cards, Apple Pay, Google Pay, Afterpay), tiered rural delivery routing, click-and-collect warehouse drive-thru loading, real-time inventory management with multi-packaging variants, and enterprise-grade Australian Local SEO.

---

## 1. Reference Site Analysis & Competitive Strategy

| Feature / Dimension | Wanneroo Stock Feeders (`wanneroostockfeeders.com.au`) | All Things Stock (`allthingsstock.com.au`) | **Muchea Stockfeed & Hardware (Our Solution)** |
| :--- | :--- | :--- | :--- |
| **Location & Identity** | Wangara / Wanneroo, Perth Metro/North | Muchea East Road, Muchea WA 6501 | **Muchea Town Centre / Great Northern Hwy, WA 6501** |
| **Product Scope** | Focus on Equine, Tack, Dog/Cat, Vet | Horse, Cattle, Sheep, Hay, Grains, Feed | **Dual Powerhouse: Complete Rural Stockfeed + Comprehensive Farm & Rural Hardware** |
| **Delivery Model** | Fixed weekday suburb routes (Mon-Fri) | Radius/Distance brackets ($10 / $20 / +$1.50/km) | **Hybrid Model: Zone Delivery Days + Dynamic Distance Radius + Warehouse Drive-Thru Click & Collect** |
| **Packaging & Bulk** | Retail bag quantities | 20kg bags & bulk repacked ATS grain | **Multi-tier: Single bag (20kg), Bale/Roll, Tonne Bulk Bag, Full Pallet with tiered pricing** |
| **Customer Experience** | Traditional catalog / legacy WooCommerce | Standard Shopify / e-commerce theme | **Modern Rails 8 Hotwire SPA-speed: Instant search, live cart drawer, mobile one-thumb checkout** |
| **Trade & Commercial** | Phone / in-store trade accounts | Manual enquiry | **Integrated Trade Accounts (ABN registration, 30-day billing, bulk order sheets)** |

---

## 2. Technical Stack (All Latest Versions)

- **Language & Runtime:** Ruby `3.2.2+` / `3.3.x`
- **Application Framework:** Ruby on Rails `8.1.x`
- **Frontend Architecture:** 
  - Rails Hotwire (`Turbo 8` for morphing page transitions and instant partial updates; `Stimulus 3` for micro-interactions)
  - Custom Tailwind-styled modern Australian rural design system (responsive, accessible, clean typography)
  - Propshaft asset pipeline & ESM Importmaps (zero node/npm runtime dependency, rock-solid stability)
- **Database & Persistence:** Active Record with SQLite3 (development/production-ready with WAL mode) / PostgreSQL compatible
- **Background Jobs & Caching:** 
  - `Solid Queue` (Rails 8 default database-backed queue for asynchronous email receipts, tracking updates, and stock alerts)
  - `Solid Cache` (High-speed database-backed fragment & page caching)
  - `Solid Cable` (Real-time live inventory and order status notifications)
- **Payments & Billing:**
  - `Stripe Elements` & `Stripe Checkout` optimized for Australia
  - Payment rails: Visa, Mastercard, AMEX, Apple Pay, Google Pay, and Australian BNPL (**Afterpay** & **Zip**)
  - Australian 10% Goods & Services Tax (**GST**) inclusive pricing model (with itemized tax invoice generation complying with ATO standards)
- **Fulfillment & Logistics:**
  - Custom WA Freight & Delivery Matrix (Local Chittering/Muchea zones + Distance-based kilometer calculator)
  - Australia Post Shipping API adapter for postal parcel goods (veterinary supplies, small hardware, tack, supplements)
  - Warehouse Drive-Through Loading Click-and-Collect scheduling

---

## 3. Australian Rural Localization & Compliance

1. **Taxation & Invoicing (ATO Compliance):**
   - Prices displayed as **AU$ (inc. GST)** everywhere on product pages, cart, and checkout.
   - Explicit breakdown on order summary: *Subtotal (ex. GST)*, *GST (10%)*, *Delivery Fee*, *Total AU$*.
   - Automated Tax Invoice PDF generation with Registered **ABN**, business address, invoice number, and date.
2. **Local Geography & Suburbs:**
   - Dedicated delivery zones: Muchea (6501), Bullsbrook (6084), Lower Chittering (6084), Bindoon (6502), Gingin (6503), Wannamal (6505), Upper Swan (6069), Ellenbrook (6069), Brigadoon (6069), Gidgegannup (6083).
   - "Gate Code & Dog on Property" delivery instructions field at checkout (vital for Australian rural properties).
3. **Contact & Operation:**
   - Phone format: `(08) 9571 XXXX` / `0480 XXX XXX`.
   - Operating Hours: Mon-Fri 7:30 AM - 5:00 PM (early rural trade opening), Sat 8:00 AM - 4:00 PM, Sun 9:00 AM - 2:00 PM.

---

## 4. Product Catalog & Category Taxonomy

### Department A: Stockfeed & Animal Nutrition
1. **Equine (Horse):**
   - Premium feeds (Cool Conditioner, Pellets, Breaker, Sweetfeed)
   - Chaff (Steam-cleaned Lucerne Chaff, Oaten Chaff, Wheaten Chaff)
   - Hay (Top-grade Oaten Round Bales, Rhodes Grass square bales, Meadow Hay)
   - Equine Supplements (Electrolytes, Biotin hoof care, Joint supplements, Wormers)
2. **Livestock (Cattle, Sheep, Goats, Alpacas, Pigs):**
   - Beef Cattle Grower/Finisher pellets, Calf milk replacer
   - Sheep & Lamb maintenance nuts, Mineral lick blocks (dry season & high phosphorus)
   - Goat mix, Alpaca maintenance pellets, Pig grower meals
3. **Poultry & Game Birds:**
   - Vegetarian Layer Pellets, Free-Range Scratch Mix, Chick Starter Crumbles, Coarse Shell Grit
4. **Working Dog & Pets:**
   - High-energy Australian Working Dog kibble, Kangaroo & Beef formulas, Pet flea/tick care, Bird seeds

### Department B: Rural Hardware & Farm Supplies
1. **Fencing & Wire:**
   - Heavy-duty Star Pickets (black bitumen & hot-dip galvanized), Cyclone rural wire, Wire strainers, Droppers, Farm gates (mesh & 5-bar)
2. **Water, Plumbing & Troughs:**
   - Philmac rural poly fittings, Metric & Rural B-class Poly Pipe, Concrete & Poly stock water troughs, Brass float valves
3. **Farm Tools, Oils & Workshop:**
   - Post-hole diggers, fencing pliers, grease guns, agricultural lubricants, fencing staples, galvanized fasteners
4. **Pasture, Seed & Pest Management:**
   - Clover & pasture seed blends, Gypsum & rural fertilizers, Rodent & fox control, Weed sprayers

---

## 5. Database Schema Architecture

```
+--------------------+        +-----------------------+        +----------------------+
|     categories     |<-------|       products        |------->|   product_variants   |
|--------------------|        |-----------------------|        |----------------------|
| id                 |        | id                    |        | id                   |
| name               |        | category_id           |        | product_id           |
| slug               |        | name                  |        | name (e.g. 20kg Bag) |
| description        |        | slug                  |        | sku                  |
| department         |        | description           |        | price_cents (AUD)    |
| icon               |        | brand                 |        | weight_kg            |
+--------------------+        | featured              |        | stock_quantity       |
                              | active                |        | low_stock_threshold  |
                              +-----------------------+        +----------------------+
                                         |                                |
                                         |                                |
                                         v                                v
+--------------------+        +-----------------------+        +----------------------+
|       orders       |<-------|      order_items      |        |   inventory_logs     |
|--------------------|        |-----------------------|        |----------------------|
| id                 |        | id                    |        | id                   |
| order_number       |        | order_id              |        | product_variant_id   |
| user_id (optional) |        | product_variant_id    |        | change_amount        |
| customer_name      |        | quantity              |        | reason (sale/restock)|
| customer_email     |        | unit_price_cents      |        | recorded_at          |
| customer_phone     |        | total_price_cents     |        +----------------------+
| fulfillment_type   |        +-----------------------+
| delivery_address   |
| suburb / postcode  |
| delivery_notes     |
| status             |
| payment_status     |
| payment_intent_id  |
| tracking_code      |
| total_cents (AUD)  |
| gst_cents (AUD)    |
| delivery_cents     |
+--------------------+
```

---

## 6. Inventory & Order Management Engine

1. **Multi-Variant Stock Control:**
   - Products have multiple packaged variants (e.g. `20kg Single Bag`, `40x Bag Pallet (Save 10%)`, `1 Tonne Bulka Bag`).
   - Each variant tracks exact weight, barcode/SKU, and stock quantity.
   - Low-stock visual flags and automated alert triggers when inventory dips below thresholds.
2. **Order Lifecycle Pipeline:**
   - `pending` -> `paid` -> `processing / picking` -> `ready_for_pickup` or `dispatched_for_delivery` -> `completed` / `cancelled`.
3. **Live Shipment & Local Delivery Tracking:**
   - Dedicated customer tracking portal (`/orders/:order_number/tracking`).
   - Visual progress tracker:
     - Step 1: Order Confirmed (Invoice generated)
     - Step 2: Packed at Muchea Warehouse
     - Step 3: Loaded on Rural Delivery Truck (with scheduled delivery day)
     - Step 4: Delivered to Gate / Feed Shed (with driver delivery photo option)
   - Australia Post tracking link auto-generated for postal consignments.

---

## 7. SEO & Schema.org Strategy (Built for Western Australia)

1. **Structured Data (JSON-LD):**
   - `LocalBusiness` / `Store` schema targeting `"Stockfeed Muchea"`, `"Rural Supplies Chittering"`, `"Horse Feed Perth Hills"`, `"Fencing Hardware Muchea"`.
   - Rich `Product` snippets with live `offers` (priceCurrency: AUD), `availability`, and `aggregateRating`.
   - `BreadcrumbList` for category indexing.
2. **Targeted Regional Keywords:**
   - "Horse feed Muchea WA", "Hay and chaff delivery Bullsbrook", "Cyclone fencing supplies Chittering", "Lupins and grain Muchea Western Australia", "Rural hardware Gingin Bindoon".
3. **OpenGraph & Twitter Card Metadata:** Dynamic sharing cards previewing product titles, prices, and high-res imagery.

---

## 8. Implementation Roadmap

1. **Step 1: Brand Assets & Visual Identity**
   - Generate bespoke vector badge logo: Australian Stock Horse silhouette, golden wheat ear, forged iron tool crest, eucalyptus green and red earth palette.
2. **Step 2: Core Data Models & Database Migrations**
   - Categories, Products, ProductVariants, Orders, OrderItems, DeliveryZones.
   - High-quality seed data covering all authentic Australian feed brands (Mitavite, Hygain, Thompson & Redwood, Wesfeeds) and rural hardware items.
3. **Step 3: Storefront & Customer Experience UI**
   - Australian-themed navbar, department mega-menu, responsive product cards with variant selector, drive-thru click & collect selector.
   - Turbo Cart Drawer (add to cart without page reload).
4. **Step 4: Checkout & Australian Payment Processing**
   - Express checkout with AU address lookup, suburb delivery zone selector, and Stripe Elements integration with AUD currency formatting.
5. **Step 5: Warehouse Admin Dashboard**
   - Inventory manager (live stock adjustments, restock logs), Order manager with status transitions, shipment tracking code generator, printable packing slips & tax invoices.
6. **Step 6: Real-Time Shipment Tracking & SEO**
   - Public order tracking page, dynamic sitemap, and rich JSON-LD meta tags.

