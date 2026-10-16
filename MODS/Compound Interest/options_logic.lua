-- Pure distribution and durable hand state. Randomness is injected by the caller.
local L={}
local function integer(r,lo,hi)
    return math.min(hi,lo+math.floor((hi-lo+1)*r*r))
end
-- All integer values in each band are reachable, including the upper endpoint.
local function magnitude(r,normal,good,rare,maximum,minimum)
    if r<0.90 then return integer(r/0.90,minimum or 1,normal),'normal' end
    if r<0.99 then return integer((r-0.90)/0.09,normal+1,good),'good' end
    if r<0.9999 then return integer((r-0.99)/0.0099,good+1,rare),'rare' end
    return integer((r-0.9999)/0.0001,rare+1,maximum),'jackpot'
end
function L.interest_base(g)
    if g.modifiers and g.modifiers.no_interest then return 0 end
    return (g.interest_amount or 1)*math.min(math.floor(math.max(0,g.dollars or 0)/5),(g.interest_cap or 25)/5)
end
function L.roll(random,interest)
    local kind,r=random(),random()
    local effect={}
    if kind<0.30 then
        effect.kind='chips';effect.value,effect.band=magnitude(r,80,300,700,1000,10)
    elseif kind<0.55 then
        effect.kind='mult';effect.value,effect.band=magnitude(r,8,30,70,100)
    elseif kind<0.80 then
        effect.kind='xmult'
        local cents
        if r<0.20 then cents=integer(r/0.20,25,99);effect.band='harmful'
        elseif r<0.94 then cents=integer((r-0.20)/0.74,100,150);effect.band='normal'
        elseif r<0.995 then cents=integer((r-0.94)/0.055,151,400);effect.band='good'
        elseif r<0.9999 then cents=integer((r-0.995)/0.0049,401,1200);effect.band='rare'
        else cents=integer((r-0.9999)/0.0001,1201,5000);effect.band='jackpot' end
        effect.value=cents/100
    elseif kind<0.92 then
        effect.kind='dollars';effect.value,effect.band=magnitude(r,6,25,75,100)
    elseif kind<0.97 then
        effect.kind='interest';effect.value,effect.band=magnitude(r,2,5,10,20)
        -- An immediate payment of current vanilla interest, not a permanent cap
        -- increase. Snapshot the amount so A/B and copied payouts stay predictable.
        effect.dollars=effect.value*(interest or 0)
    else
        effect.kind='combo';effect.value,effect.band=magnitude(r,6,20,60,100)
        effect.chips=effect.value*10
    end
    return effect
end
function L.prepare(extra,hand_key,random,interest)
    if extra.hand_key==hand_key and extra.a and extra.b then return false end
    extra.selected=extra.selected=='B' and 'B' or 'A'
    extra.a=L.roll(random,interest);extra.b=L.roll(random,interest)
    extra.hand_key=hand_key
    return true
end
function L.active(extra)
    return extra[extra.selected=='B' and 'b' or 'a']
end
function L.effect(option)
    if not option then return end
    if option.kind=='chips' then return {chips=option.value} end
    if option.kind=='mult' then return {mult=option.value} end
    if option.kind=='xmult' then return {x_mult=option.value} end
    if option.kind=='dollars' then return {dollars=option.value} end
    if option.kind=='interest' then return {dollars=option.dollars} end
    if option.kind=='combo' then return {chips=option.chips,mult=option.value} end
end
return L
