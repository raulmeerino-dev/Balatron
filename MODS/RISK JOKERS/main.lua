local mod=SMODS.current_mod
local R=assert(SMODS.load_file('core/registry.lua'))()(mod)
local M=assert(SMODS.load_file('core/mechanics.lua'))()(R)
RiskJokers={registry=R}
SMODS.Rarity{
    key='risk',badge_colour=HEX(PortraitQOL.rarity_colours.RISK),default_weight=0,disable_if_empty=true,pools={Joker=true},
    get_weight=function() return R.weight() end,
    black_market_weight=function() return R.config().risk_black_market_weight end,
}
for _,id in ipairs({'russian_joker','burning_fuse','greed','glass_cannon','all_or_nothing','loan_shark','overheated'}) do
    M.register(assert(SMODS.load_file('jokers/'..id..'.lua'))())
end
-- Only intercept homogeneous RISK pools; native/UPG selection is unchanged.
assert(SMODS.load_file('mission_jokers.lua'))()(R)
-- This also covers native resampling and content generated outside the shop.
local pick=pseudorandom_element
function pseudorandom_element(pool,seed)
    if R.is_risk_pool(pool) then return R.choose(pool,pseudorandom(seed)) end
    return pick(pool,seed)
end
assert(SMODS.load_file('core/menu.lua'))()(R)

mod.affects_gameplay=true
mod.qol_snapshot=function()
    local names={}
    for id,def in pairs(R.entries) do
        if R.enabled(id) then names[id]=def.name end
    end
    return PortraitQOL.config_snapshot(G.GAME.risk_jokers_config,names)
end
