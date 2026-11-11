puts "== Clearing old data =="
OrderItem.destroy_all
Order.destroy_all
InventoryLog.destroy_all
ProductVariant.destroy_all
Product.destroy_all
Category.destroy_all
DeliveryZone.destroy_all

puts "== Seeding Delivery Zones =="
DeliveryZone.create!([
  {
    name: "Zone 1 — Muchea & Bullsbrook Local",
    postcodes: "6501, 6084",
    fee_cents: 1500,
    free_threshold_cents: 30000,
    scheduled_days: "Monday, Wednesday & Friday",
    description: "Daily warehouse truck route covering Muchea, Bullsbrook, and immediate surrounding paddocks."
  },
  {
    name: "Zone 2 — Chittering Valley & Upper Swan",
    postcodes: "6084, 6069, 6083",
    fee_cents: 2500,
    free_threshold_cents: 45000,
    scheduled_days: "Tuesday & Thursday",
    description: "Servicing Lower Chittering, Chittering, Upper Swan, and Gidgegannup properties."
  },
  {
    name: "Zone 3 — Gingin, Bindoon & Wannamal Pastoral",
    postcodes: "6503, 6502, 6505",
    fee_cents: 4000,
    free_threshold_cents: 60000,
    scheduled_days: "Every Wednesday",
    description: "Northern regional pastoral run for cattle stations, orchards, and rural properties."
  },
  {
    name: "Zone 4 — Ellenbrook & Perth Hills Foothills",
    postcodes: "6069, 6056",
    fee_cents: 3000,
    free_threshold_cents: 50000,
    scheduled_days: "Every Friday",
    description: "Southern route covering Ellenbrook, The Vines, and surrounding equine properties."
  }
])

puts "== Seeding Categories =="
equine_cat = Category.create!(
  name: "Equine Feed & Nutrition",
  slug: "equine-feed-nutrition",
  department: "Stockfeed & Animal Nutrition",
  icon: "horse",
  description: "Complete nutrition, steam-rolled grains, high-fiber chaffs, and premium pellets for performance and pleasure horses.",
  display_order: 1
)

hay_cat = Category.create!(
  name: "Hay, Chaff & Bedding",
  slug: "hay-chaff-bedding",
  department: "Stockfeed & Animal Nutrition",
  icon: "wheat",
  description: "WA grown meadow and oaten hay rolls, clean steamed lucerne chaff, and dust-extracted pine shavings.",
  display_order: 2
)

livestock_cat = Category.create!(
  name: "Cattle, Sheep & Livestock",
  slug: "cattle-sheep-livestock",
  department: "Stockfeed & Animal Nutrition",
  icon: "cow",
  description: "Cattle grower pellets, calf milk replacers, sheep nuts, and multi-species mineral lick blocks for WA pastures.",
  display_order: 3
)

poultry_cat = Category.create!(
  name: "Poultry & Bird Seed",
  slug: "poultry-bird-seed",
  department: "Stockfeed & Animal Nutrition",
  icon: "egg",
  description: "Layer pellets, free-range scratch mixes, chick starter crumbles, and Western Australian native bird seeds.",
  display_order: 4
)

dog_cat = Category.create!(
  name: "Working Dog & Pet Food",
  slug: "working-dog-pet-food",
  department: "Stockfeed & Animal Nutrition",
  icon: "dog",
  description: "High-protein working dog kibble, kangaroo and beef formulas, tick collars, and veterinarian supplements.",
  display_order: 5
)

fencing_cat = Category.create!(
  name: "Fencing, Wire & Gates",
  slug: "fencing-wire-gates",
  department: "Rural Hardware & Farm Supplies",
  icon: "fence",
  description: "Australian-standard Waratah Cyclone wire, bitumen star pickets, farm gates, strainers, and post drivers.",
  display_order: 6
)

water_cat = Category.create!(
  name: "Plumbing, Pipe & Water Troughs",
  slug: "plumbing-pipe-troughs",
  department: "Rural Hardware & Farm Supplies",
  icon: "droplet",
  description: "Philmac poly pipe fittings, rural B-class poly coils, float valves, and heavy concrete livestock troughs.",
  display_order: 7
)

tools_cat = Category.create!(
  name: "Farm Hardware & Tools",
  slug: "farm-hardware-tools",
  department: "Rural Hardware & Farm Supplies",
  icon: "wrench",
  description: "Heavy-duty farm tools, grease guns, fencing pliers, galvanized fasteners, and agricultural lubricants.",
  display_order: 8
)

puts "== Seeding Products & Variants =="

# 1. Hygain Balanced
p1 = Product.create!(
  category: equine_cat,
  name: "Hygain Balanced Concentrated Equine Feed",
  slug: "hygain-balanced-concentrated-equine-feed",
  brand: "Hygain",
  short_description: "All-in-one concentrated pellet packed with essential vitamins, chelated minerals, and quality protein.",
  full_description: "Hygain Balanced is a scientifically formulated, concentrated feed balancer designed for all horse breeds and life stages. Enriched with Bio-Available Selenium, Vitamin E, and Biotin for optimum coat, muscle tone, and hoof development. High in essential amino acids to support lean muscle maintenance without the excitability of grain.",
  specifications: "Crude Protein: 25.0% | Crude Fat: 5.0% | Max Crude Fibre: 9.0% | Calcium: 3.5% | Phosphorus: 1.8% | Vitamin E: 1,000 IU/kg",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=800&q=80"
)
p1.variants.create!([
  { name: "20kg Bag", sku: "HYG-BAL-20KG", price_cents: 4250, weight_kg: 20.0, stock_quantity: 48, low_stock_threshold: 8, is_default: true },
  { name: "40-Bag Full Pallet (Save 8%)", sku: "HYG-BAL-PLT", price_cents: 156400, weight_kg: 800.0, stock_quantity: 4, low_stock_threshold: 1, is_default: false }
])

# 2. Mitavite Formula 3
p2 = Product.create!(
  category: equine_cat,
  name: "Mitavite Formula 3 High Performance Feed",
  slug: "mitavite-formula-3-high-performance-feed",
  brand: "Mitavite",
  short_description: "The gold standard oat-free performance muesli for equine athletes, eventers, and active riding horses.",
  full_description: "Mitavite Formula 3 combines steam-extruded grains, vegetable oils, and targeted electrolyte buffers to sustain athletic stamina and accelerate recovery. Ideal for horses in medium-to-hard work across Western Australia.",
  specifications: "Crude Protein: 14.5% | Crude Fat: 6.5% | Crude Fibre: 7.0% | Digestible Energy: 13.8 MJ/kg",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?auto=format&fit=crop&w=800&q=80"
)
p2.variants.create!([
  { name: "20kg Bag", sku: "MIT-F3-20KG", price_cents: 3890, weight_kg: 20.0, stock_quantity: 36, low_stock_threshold: 6, is_default: true }
])

# 3. Thompson & Redwood Steam Rolled Barley
p3 = Product.create!(
  category: equine_cat,
  name: "T&R Steam Rolled Barley with Molasses",
  slug: "tr-steam-rolled-barley-with-molasses",
  brand: "Thompson & Redwood",
  short_description: "Locally sourced Western Australian barley, steam extruded for enhanced digestibility and conditioned with molasses.",
  full_description: "Thompson & Redwood uses locally harvested WA grain. Steam flaking gelatinises the starch, preventing hindgut acidosis while delivering calm, sustained weight gain and energy.",
  specifications: "Crude Protein: 11.2% | Energy: 13.5 MJ/kg | Moisture: 12.0%",
  featured: false,
  hero_image_url: "https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=800&q=80"
)
p3.variants.create!([
  { name: "20kg Bag", sku: "TR-BAR-20KG", price_cents: 2450, weight_kg: 20.0, stock_quantity: 52, low_stock_threshold: 10, is_default: true },
  { name: "1 Tonne Bulk Bag", sku: "TR-BAR-1T", price_cents: 89000, weight_kg: 1000.0, stock_quantity: 3, low_stock_threshold: 1, is_default: false }
])

# 4. Premium Lucerne Chaff
p4 = Product.create!(
  category: hay_cat,
  name: "WA Prime Steam-Cleaned Lucerne Chaff",
  slug: "wa-prime-steam-cleaned-lucerne-chaff",
  brand: "Muchea Farm Select",
  short_description: "Freshly cut, dust-extracted green lucerne chaff. Rich in natural calcium and cool plant protein.",
  full_description: "Sourced directly from irrigated Western Australian growers. Screened and steam-cleaned to eliminate dust, fine powder, and mould spores. Perfect for horses, dairy goats, and calves.",
  specifications: "Crude Protein: 17.5% | Fibre: 26.0% | Calcium: 1.4%",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=800&q=80"
)
p4.variants.create!([
  { name: "25kg Bag", sku: "MFS-LUC-25KG", price_cents: 3400, weight_kg: 25.0, stock_quantity: 40, low_stock_threshold: 8, is_default: true }
])

# 5. Oaten Hay Bales
p5 = Product.create!(
  category: hay_cat,
  name: "Prime Export-Grade Oaten Hay Round Bale",
  slug: "prime-export-grade-oaten-hay-round-bale",
  brand: "Chittering Valley Hay Co.",
  short_description: "Heavy 4x4 round bales of sweet, leafy green oaten hay. Shed stored and protected from weather.",
  full_description: "Harvested at peak vegetative stage in the Chittering Valley. Sweet aroma, high leaf-to-stem ratio, zero weeds. Heavy net-wrapped bales, stored undercover in our dry Muchea warehouse.",
  specifications: "Bale Dimensions: 4ft x 4ft | Average Weight: ~320kg | Moisture: <12%",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?auto=format&fit=crop&w=800&q=80"
)
p5.variants.create!([
  { name: "Single 4x4 Round Bale (320kg)", sku: "CVH-OAT-RND", price_cents: 14500, weight_kg: 320.0, stock_quantity: 18, low_stock_threshold: 3, is_default: true },
  { name: "Semi-Trailer Load (24 Bales)", sku: "CVH-OAT-SEMI", price_cents: 315000, weight_kg: 7680.0, stock_quantity: 2, low_stock_threshold: 1, is_default: false }
])

# 6. Wesfeeds Cattle Finisher
p6 = Product.create!(
  category: livestock_cat,
  name: "Wesfeeds High-Gain Beef Cattle Grower Pellets",
  slug: "wesfeeds-high-gain-beef-cattle-grower-pellets",
  brand: "Wesfeeds WA",
  short_description: "High-protein beef cattle and weaner pellet formulated with buffers to maximise feed conversion efficiency.",
  full_description: "Formulated specifically for Western Australian grazing cattle facing seasonal summer dry pastures. Contains bypass protein, active rumen buffers, and macro-minerals to boost daily liveweight gain without digestive upset.",
  specifications: "Crude Protein: 16.0% | ME: 11.5 MJ/kg | Urea: 1.0% | Bovatec: Included",
  featured: false,
  hero_image_url: "https://images.unsplash.com/photo-1527153857715-3908f2ae5e81?auto=format&fit=crop&w=800&q=80"
)
p6.variants.create!([
  { name: "20kg Bag", sku: "WES-CAT-20KG", price_cents: 2250, weight_kg: 20.0, stock_quantity: 65, low_stock_threshold: 10, is_default: true },
  { name: "1 Tonne Bulk Bag", sku: "WES-CAT-1T", price_cents: 84000, weight_kg: 1000.0, stock_quantity: 4, low_stock_threshold: 1, is_default: false }
])

# 7. Riverina Multi-Species Lick Block
p7 = Product.create!(
  category: livestock_cat,
  name: "Riverina All-Weather Dry Season Mineral Lick Block",
  slug: "riverina-all-weather-dry-season-mineral-lick-block",
  brand: "Riverina",
  short_description: "Weather-resistant 20kg molasses lick block fortified with phosphorus, sulfur, and urea for cattle & sheep.",
  full_description: "Engineered to withstand heavy rain and scorching WA sun. Stimulates rumen microbes to digest dry standing paddock feed and straw.",
  specifications: "Crude Protein: 18.0% | Urea: 5.0% | Phosphorus: 3.0% | Salt: 25.0%",
  featured: false,
  hero_image_url: "https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=800&q=80"
)
p7.variants.create!([
  { name: "20kg Weather Block", sku: "RIV-BLK-20KG", price_cents: 3100, weight_kg: 20.0, stock_quantity: 24, low_stock_threshold: 5, is_default: true }
])

# 8. Golden Yolk Layer Pellets
p8 = Product.create!(
  category: poultry_cat,
  name: "Golden Yolk Vegetarian Poultry Layer Pellets",
  slug: "golden-yolk-vegetarian-poultry-layer-pellets",
  brand: "Golden Yolk",
  short_description: "Nutrient-dense hen layer pellets packed with calcium and natural yolk-brightening marigold extract.",
  full_description: "Complete diet for laying hens from 18 weeks onward. High in available calcium and grit to ensure strong eggshells and rich golden yolks naturally.",
  specifications: "Crude Protein: 16.5% | Calcium: 3.8% | Crude Fat: 3.0%",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?auto=format&fit=crop&w=800&q=80"
)
p8.variants.create!([
  { name: "20kg Bag", sku: "GY-LAY-20KG", price_cents: 2190, weight_kg: 20.0, stock_quantity: 80, low_stock_threshold: 15, is_default: true }
])

# 9. Cobber Working Dog
p9 = Product.create!(
  category: dog_cat,
  name: "Cobber 'The Working Dog' High-Energy Formula",
  slug: "cobber-the-working-dog-high-energy-formula",
  brand: "Cobber",
  short_description: "Fuel for the Australian working dog. 22% protein, 12% fat with prebiotic digestive support.",
  full_description: "Formulated specifically for hard-working kelpies, border collies, and farm dogs that work paddocks day in and day out. Packed with real Australian meat and balanced dietary fiber.",
  specifications: "Crude Protein: 22.0% | Crude Fat: 12.0% | Vitamin E: 100 mg/kg",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?auto=format&fit=crop&w=800&q=80"
)
p9.variants.create!([
  { name: "20kg Bag", sku: "COB-WRK-20KG", price_cents: 5490, weight_kg: 20.0, stock_quantity: 32, low_stock_threshold: 6, is_default: true }
])

# 10. Waratah Cyclone Fencing Wire
p10 = Product.create!(
  category: fencing_cat,
  name: "Waratah Cyclone 7/90/30 Rural Boundary Fencing Wire",
  slug: "waratah-cyclone-7-90-30-rural-boundary-wire",
  brand: "Waratah Cyclone",
  short_description: "Australian-made 200m roll of high-tensile galvanized boundary and paddock ringlock wire.",
  full_description: "Built to handle harsh Australian sun and livestock pressure. Features Longlife Blue wire coating for up to 4x the corrosion resistance of standard galvanising. Ideal for sheep, cattle, and rural boundary fences.",
  specifications: "Roll Length: 200m | Line Wires: 7 | Fence Height: 90cm | Stay Distance: 30cm | Tensile: High",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1508873696983-2df5293cb32b?auto=format&fit=crop&w=800&q=80"
)
p10.variants.create!([
  { name: "200m Roll", sku: "WAR-CYC-200M", price_cents: 29500, weight_kg: 68.0, stock_quantity: 14, low_stock_threshold: 3, is_default: true }
])

# 11. Star Pickets Bundle
p11 = Product.create!(
  category: fencing_cat,
  name: "Heavy Duty 180cm Black Bitumen Star Pickets (Pack of 10)",
  slug: "heavy-duty-180cm-black-bitumen-star-pickets-pack-of-10",
  brand: "Muchea Rural Iron",
  short_description: "Trade-grade 1.8m steel fence posts pre-drilled for fence wire. Weatherproof dip-coated bitumen.",
  full_description: "High tensile steel fence posts with precision drilled holes for plain, barbed, or ringlock wire. Pointed tips for easy driving in gravel and clay soils.",
  specifications: "Length: 1.8m (6ft) | Weight per post: 3.4kg | Pack Qty: 10 Posts | Coating: Black Bitumen Dip",
  featured: false,
  hero_image_url: "https://images.unsplash.com/photo-1589939705384-5185137a7f0f?auto=format&fit=crop&w=800&q=80"
)
p11.variants.create!([
  { name: "Pack of 10 Pickets", sku: "MSH-PCK-10PK", price_cents: 8900, weight_kg: 34.0, stock_quantity: 45, low_stock_threshold: 8, is_default: true },
  { name: "Full Sling (200 Pickets - Save 12%)", sku: "MSH-PCK-SLING", price_cents: 156000, weight_kg: 680.0, stock_quantity: 5, low_stock_threshold: 1, is_default: false }
])

# 12. Philmac Poly Fittings Kit
p12 = Product.create!(
  category: water_cat,
  name: "Philmac 32mm Rural B Metric Poly Joiner",
  slug: "philmac-32mm-rural-b-metric-poly-joiner",
  brand: "Philmac Australia",
  short_description: "The trusted Australian slide-and-tighten compression coupling for rural polyethylene pipe.",
  full_description: "Engineered in Australia for extreme rural conditions. No loose rings or inserts; connects instantly without tools. Rated to PN16 for reliable stock trough lines.",
  specifications: "Pipe Size: 32mm Rural Class B | Material: UV Stabilised Polypropylene | Pressure Rating: PN16 (1600 kPa)",
  featured: false,
  hero_image_url: "https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=800&q=80"
)
p12.variants.create!([
  { name: "Single Joiner", sku: "PHL-J32-EA", price_cents: 1350, weight_kg: 0.3, stock_quantity: 85, low_stock_threshold: 15, is_default: true },
  { name: "Contractor Box of 10", sku: "PHL-J32-BX10", price_cents: 11500, weight_kg: 3.0, stock_quantity: 12, low_stock_threshold: 2, is_default: false }
])

# 13. Heavy Duty Stock Trough
p13 = Product.create!(
  category: water_cat,
  name: "1000L Reinforced Concrete Stock Water Trough",
  slug: "1000l-reinforced-concrete-stock-water-trough",
  brand: "Muchea Precast",
  short_description: "Heavy 1000-litre livestock water trough with enclosed brass float valve guard to prevent livestock damage.",
  full_description: "Cattle and horse proof. Cast from 40MPa reinforced concrete. Includes pre-plumbed 1-inch brass inlet and high-flow float valve. Forklift-accessible base for easy farm placement.",
  specifications: "Capacity: 1,000 Litres | Diameter: 1800mm | Height: 600mm | Weight: 680kg | Valve: 1\" High Flow Brass",
  featured: true,
  hero_image_url: "https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=800&q=80"
)
p13.variants.create!([
  { name: "1000L Trough with Float Valve", sku: "MPC-TRG-1000", price_cents: 88000, weight_kg: 680.0, stock_quantity: 6, low_stock_threshold: 2, is_default: true }
])

puts "== Seeding Demo Orders for Admin & Tracking =="
order1 = Order.create!(
  customer_name: "Lachlan Evans",
  customer_email: "lachlan@chitteringpastoral.com.au",
  customer_phone: "0489 123 456",
  fulfillment_type: "delivery",
  delivery_address: "Lot 142 Chittering Road",
  suburb: "Lower Chittering",
  postcode: "6084",
  delivery_notes: "Leave pallets under open machinery shed on right of cattle grid. Gate code #7712.",
  status: "dispatched",
  payment_status: "completed",
  payment_method: "Credit Card (Visa ending in 4242)",
  stripe_payment_intent_id: "pi_demo_chittering_9812",
  tracking_code: "WA7821AU",
  carrier_name: "Muchea Rural Fleet — Truck 02 (Driver: Dave)",
  subtotal_cents: 48500,
  gst_cents: 4636,
  delivery_fee_cents: 2500,
  total_cents: 51000,
  estimated_delivery_at: 2.hours.from_now,
  dispatched_at: 1.hour.ago
)
order1.items.create!([
  { product_variant: p1.variants.first, quantity: 4, unit_price_cents: 4250, total_price_cents: 17000 },
  { product_variant: p10.variants.first, quantity: 1, unit_price_cents: 29500, total_price_cents: 29500 },
  { product_variant: p8.variants.first, quantity: 1, unit_price_cents: 2190, total_price_cents: 2190 }
])

order2 = Order.create!(
  customer_name: "Sarah Jenkins",
  customer_email: "sarah.jenkins@equinewa.com",
  customer_phone: "0412 889 001",
  fulfillment_type: "pickup",
  suburb: "Muchea",
  postcode: "6501",
  delivery_notes: "Will arrive in silver Toyota Hilux ute with trailer at 2:30pm for drive-thru forklift loading.",
  status: "packing",
  payment_status: "completed",
  payment_method: "Apple Pay (Stripe)",
  stripe_payment_intent_id: "pi_demo_muchea_4419",
  tracking_code: "WA9934AU",
  carrier_name: "Muchea Warehouse Drive-Thru Bay 2",
  subtotal_cents: 72900,
  gst_cents: 6627,
  delivery_fee_cents: 0,
  total_cents: 72900,
  estimated_delivery_at: 1.hour.from_now
)
order2.items.create!([
  { product_variant: p5.variants.first, quantity: 4, unit_price_cents: 14500, total_price_cents: 58000 },
  { product_variant: p4.variants.first, quantity: 3, unit_price_cents: 3400, total_price_cents: 10200 },
  { product_variant: p3.variants.first, quantity: 2, unit_price_cents: 2450, total_price_cents: 4900 }
])

puts "== Seed Data Completed Successfully =="
puts "Created #{Category.count} categories, #{Product.count} products, #{ProductVariant.count} variants, #{DeliveryZone.count} delivery zones, and #{Order.count} sample orders."
