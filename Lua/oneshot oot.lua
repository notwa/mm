local addrs = require "addrs"
require "item values"

local inv = addrs.inventory
local quantities = addrs.quantities

_=addrs.target_style and addrs.target_style(1)

addrs.hearts        (16*20)
addrs.max_hearts    (16*20)
addrs.doubled_hearts(20)
addrs.has_magic     (1)
addrs.magic         (0x60)
addrs.rupees        (500)

addrs.tunic_boots  (0xFF) -- normally 0x77
addrs.sword_shield (0xF7) -- normally 0x77?
addrs.upgrades     (0x36E458) -- normally ?
addrs.quest_items  (0x00FFFFFF)

inv.deku_stick     (0x00)
inv.deku_nut       (0x01)
inv.bombs          (0x02)
inv.bow            (0x03)
inv.fire_arrows    (0x04)
inv.dins_fire      (0x05)
inv.slingshot      (0x06)
inv.ocarina        (0x08)
inv.bombchu        (0x09)
inv.hookshot       (0x0B)
inv.ice_arrows     (0x0C)
inv.farores_wind   (0x0D)
inv.boomerang      (0x0E)
inv.lens_of_truth  (0x0F)
inv.magic_beans    (0x10)
inv.hammer         (0x11)
inv.light_arrows   (0x12)
inv.nayrus_love    (0x13)
inv.bottle_1       (0x14)
inv.bottle_2       (0x18)
inv.bottle_3       (0x19)
inv.bottle_4       (0x1C)
--trade_1             (0xFF)
--trade_2             (0xFF)

quantities.sticks  (69)
quantities.nuts    (69)
quantities.bombs   (69)
quantities.arrows  (69)
quantities.seeds   (69)
quantities.bombchu (69)
quantities.beans   (69)
