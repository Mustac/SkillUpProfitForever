# SkillUp & Profit Forever

## 1.6.0

- **Make your own mats**: when a recipe needs something you can make yourself (Bolt of Silk Cloth, cured hides, Bronze Tubes, bars from Mining), each such mat gets a **Buy / Make** switch. Make shows the raw mats under it with their own Buy buttons, the Buy button becomes **Make N**, and Craft makes them first. Until you choose, the cheaper way is used.
- Making those mats counts toward your skill points in the cost per point.
- **Enchanting**: an **Enchant** button puts the enchant on gear with no enchant (in your bags or worn), or on your own gear (asks for a second click). One click per skill-up.
- **Craft Queue** puts the mats you make yourself in front of the recipe that needs them.
- **Simple view**: a small window with just your recipes, how many you can make from your bags, and a Craft / Enchant button on each (Shift-click crafts all). Switch with Simple / Full; remembered. `/csu simple`.
- **Crafting bar**: recipe icon, crafts left and seconds. Drag it anywhere; on/off and size in Options (`/csu bar` to move it).
- **Clear errors**: no materials, no anvil, no cooking fire and other crafting errors show in red above the crafting bar and on the window. Craft (0) tells you what's missing.
- **What's new** window after an update (`/csu news`), and a notice when someone in your guild or group has a newer version.
- **Graphite** theme (dark grey) is the new default. Mats bought on the AH show **In Mail** until you take them out.

## 1.5.0 (first public release)

- Four modes: **Normal** (every recipe A to Z), **Cheapest** (cheapest mats per skill point), **Level + Earn** (skill up and sell what you make at the vendor or the AH, whichever pays more) and **Best Profit** (most gold per craft).
- **Real profit** counts the Auction House: the 5% cut comes off, and the deposit is shown (8h auction by default, `/csu ah 2|8|24` to change; you get it back when the item sells) with what you lose if it doesn't sell.
- Clear numbers for every recipe: what the mats cost, what comes from your bags (and what those would sell for), what the item sells for, and the profit.
- **Mats From Bags**: OFF / ON (mats you have count as free) / Only Bag Items (only what you can make from the items you tick in the bag list).
- Scan AH, then buy exactly the cheapest ones you need in one click. If someone was faster, it goes back to Scan AH. What you bought counts as yours while it waits in the mailbox, so Buy only asks for what's still missing.
- Groups (Chest, Legs, Potion, Elixir...), hide gear below a level, resizable window.
- **Craft Queue**: queue recipes and amounts; it adds up all the mats and shows bags, bank, mailbox and what's left to buy, with a Buy button per mat. **Count bank** makes bank items count as yours, and when you open your bank the mats the queue still misses go to your bags by themselves (just enough, stacks are split). **Craft next** crafts down the queue.
- **Options**: five layouts (Classic, list and recipe side by side, bag items as a tab, list on top, profession tabs) and a scale for the whole addon (window, icon, arrow).
- Tells you when you can learn the next rank (Journeyman, Expert, Artisan) and where: trainer, book or quest, for your faction.
- **Show the way**: a step-by-step route to the trainer (walk, fly, boat, zeppelin, portal) with a map pin and its own on-screen arrow (like TomTom's) pointing at the next stop: green ahead, yellow to the side, red behind, plus distance and time to arrive. No TomTom needed. `/csu arrow` shows or hides it.
- Craft from this window: Blizzard's profession window stays open but hidden (switch back with the Window button).
- Floating icon; X hides the window into it and keeps everything open.
- Fishing, Herbalism and Skinning are left out (nothing to craft).
