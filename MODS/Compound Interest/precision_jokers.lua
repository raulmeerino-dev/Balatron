return function(I)
    local P=PortraitGameplay
    local function register(def)
        SMODS.Atlas{key=def.key,path=def.key..'.png',px=71,py=95}
        def.atlas=def.key;def.pos={x=0,y=0}
        def.unlocked=true;def.discovered=false;def.blueprint_compat=true
        def.eternal_compat=true;def.perishable_compat=true
        local key=def.key
        def.in_pool=function() return I.enabled(key) end
        SMODS.Joker(def)
    end
    register{key='sniper',rarity=3,cost=8,config={extra={xmult=1}},
        loc_vars=function(_,q,card) return {vars={card.ability.extra.xmult}} end,
        calculate=function(_,card,c)
            if card.debuff then return end
            local s=card.ability.extra
            if c.joker_main then return {x_mult=s.xmult} end
            if card.area==G.jokers and not card.getting_sliced and P.won(c) and P.once(s,'last_win',P.token()) then
                -- Inclusive bounds, using the final accumulated blind score.
                if G.GAME.chips<=G.GAME.blind.chips*1.1 then
                    s.xmult=s.xmult+0.25
                    return {message='+X0.25',colour=G.C.MULT,card=card}
                end
            end
        end}
    register{key='second_course',rarity=2,cost=6,config={extra={counts={}}},
        calculate=function(_,card,c)
            if card.debuff then return end
            local s=card.ability.extra
            if c.before and P.real(c) and card.area==G.jokers then
                local blind=P.token()
                if s.blind~=blind then s.blind=blind;s.counts={} end
                if P.once(s,'last_hand',blind..':'..G.GAME.hands_played) then
                    s.counts[c.scoring_name]=(s.counts[c.scoring_name] or 0)+1
                end
            end
            if c.joker_main and s.blind==P.token() and s.counts[c.scoring_name]==2 then
                return {mult=25,card=card}
            end
        end}
end
