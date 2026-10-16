local J=require('portrait_joker_missions')
local def={key='wayfinder',atlas='wayfinder',name='Wayfinder',mission='wayfinder',cost_key='wayfinder_cost',
    initial_state={stage=1,seen={},progress=0},
    stages={
        {loc_key='j_upg_wayfinder_1',sprite={x=0,y=0}},
        {loc_key='j_upg_wayfinder_2',sprite={x=1,y=0}},
        {loc_key='j_upg_wayfinder_3',sprite={x=2,y=0},final=true},
    },
    loc_vars=function(s) return {s.progress or 0,4,7} end,
}
function def.calculate(card,c,R,E)
    local s=card.ability.extra
    if c.repetition and c.cardarea==G.play then
        local hand=c.scoring_hand or {}
        if c.other_card==hand[1] or (s.stage>=2 and c.other_card==hand[#hand]) or s.stage==3 then
            return {repetitions=1,message=localize('k_again_ex'),card=c.blueprint_card or card}
        end
    end
    if c.after and J.real(c) and card.area==G.jokers and c.scoring_name and not s.seen[c.scoring_name] then
        s.seen[c.scoring_name]=true;s.progress=J.count(s.seen)
        if (s.stage==1 and s.progress>=4) or (s.stage==2 and s.progress>=7) then return E.upgrade(def,card) end
        return {message=tostring(s.progress),colour=G.C.RARITY.upg_upgraded}
    end
end
return def
