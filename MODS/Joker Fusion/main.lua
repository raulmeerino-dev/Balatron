local P=PortraitGameplay
local F=P.register(SMODS.current_mod)
PortraitFusion=F
if F.mod.config.recipes.broken_copier==nil then F.mod.config.recipes.broken_copier=true end
SMODS.Rarity{key='fusion',badge_colour=HEX(PortraitQOL.rarity_colours.FUSION),default_weight=0,disable_if_empty=true,pools={Joker=true}}
assert(SMODS.load_file('core.lua'))()(F,P)
for _,d in ipairs(assert(SMODS.load_file('recipes.lua'))()) do F.register(d) end
assert(SMODS.load_file('jokers.lua'))()(F,P)
assert(SMODS.load_file('copier.lua'))()(F,P)
assert(SMODS.load_file('animation.lua'))()(F,P)
assert(SMODS.load_file('context.lua'))()(F,P)
assert(SMODS.load_file('context_save.lua'))()(F,P)
assert(SMODS.load_file('context_rewards.lua'))()(F,P)
assert(SMODS.load_file('ui.lua'))()(F,P)
assert(SMODS.load_file('context_ui.lua'))()(F,P)
F.mod.calculate=function(_,context)
    if P.real(context) and context.buying_card and P.normal_shop() then P.schedule_offers() end
end
