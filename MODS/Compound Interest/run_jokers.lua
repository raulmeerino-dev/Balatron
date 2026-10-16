-- All durable progress lives in native Card.ability.extra and is saved by Card.
return function(I)
    local function growth(card,context,event)
        local token=context[event]
        if not token or not PortraitGameplay.real(context) or card.area~=G.jokers or card.debuff then return end
        local extra=card.ability.extra
        if not PortraitGameplay.once(extra,'last_event',token) then return end
        extra.gains=extra.gains+1
        return {message=localize('k_incj_up'),colour=G.C.MULT,card=card}
    end
    local function factor(extra) return 1+extra.gains*extra.gain end
    -- The current play has already incremented native stats before joker_main.
    -- Compare the counts at selection, so playing a tied least-used hand qualifies.
    function I.least_played(key,current_play)
        local hands=G.GAME and G.GAME.hands or {}
        local selected=hands[key]
        if not selected then return false end
        local minimum=math.huge
        for name,hand in pairs(hands) do
            minimum=math.min(minimum,math.max(0,(hand.played or 0)-(current_play and name==key and 1 or 0)))
        end
        return math.max(0,(selected.played or 0)-(current_play and 1 or 0))==minimum
    end
    function I.modification_count()
        local seen={}
        for _,card in ipairs(G.playing_cards or {}) do
            for key,present in pairs(SMODS.get_enhancements(card)) do
                if present and key~='c_base' then seen['enhancement:'..key]=true end
            end
            if card.seal then seen['seal:'..card.seal]=true end
            local edition=card.edition
            if edition then
                for _,def in ipairs(G.P_CENTER_POOLS.Edition or {}) do
                    if def.key~='e_base' and (edition.key==def.key or edition[def.key:sub(3)]) then
                        seen['edition:'..def.key]=true
                    end
                end
            end
            -- Registered custom card stickers count; bookkeeping flags do not.
            for key in pairs(SMODS.Stickers or {}) do
                if card.ability[key] then seen['sticker:'..key]=true end
            end
        end
        local count=0;for _ in pairs(seen) do count=count+1 end
        return count
    end
    local function register(def)
        local key=def.key
        SMODS.Atlas{key=key,path=key..'.png',px=71,py=95}
        def.atlas=key;def.pos={x=0,y=0}
        def.unlocked=true;def.discovered=false
        def.blueprint_compat=true;def.eternal_compat=true
        if def.perishable_compat==nil then def.perishable_compat=true end
        def.in_pool=function() return I.enabled(key) end
        SMODS.Joker(def)
    end
    local function additive(key,rarity,cost,event,gain)
        register{key=key,rarity=rarity,cost=cost,perishable_compat=false,
            config={extra={gains=0,gain=gain,last_event=''}},
            loc_vars=function(self,queue,card)
                local e=card.ability.extra;return {vars={e.gain,e.gains*e.gain}}
            end,
            calculate=function(self,card,context)
                if card.debuff then return end
                if context.joker_main then return {mult=card.ability.extra.gains*card.ability.extra.gain} end
                return growth(card,context,event)
            end}
    end
    additive('tax_collector',2,5,'portrait_overkill',1)
    additive('world_record',2,6,'portrait_hand_record',6)
    local function olympic_factor(extra) return (10+3*extra.streak)/10 end
    register{key='olympico',rarity=3,cost=8,
        config={extra={streak=0,last_event=''}},
        loc_vars=function(self,queue,card)
            local e=card.ability.extra
            local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
            return {vars={I.logic.format(0.3,es),I.logic.format(olympic_factor(e),es),e.streak}}
        end,
        calculate=function(self,card,context)
            if card.debuff then return end
            local e=card.ability.extra
            if context.joker_main then return {x_mult=olympic_factor(e)} end
            local token=context.portrait_hand_result
            if not token or not PortraitGameplay.real(context) or card.area~=G.jokers or card.getting_sliced then return end
            if not PortraitGameplay.once(e,'last_event',token) then return end
            local before=olympic_factor(e)
            if context.portrait_hand_record==token then e.streak=e.streak+1 else e.streak=0 end
            local after=olympic_factor(e)
            if before==after then return end
            local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
            return {message=localize{type='variable',key=after>before and 'a_incj_olympico_up' or 'a_incj_olympico_reset',
                vars={I.logic.format(before,es),I.logic.format(after,es)}},
                colour=after>before and G.C.MULT or G.C.FILTER,card=card}
        end}
    register{key='excessive_force',rarity=3,cost=8,perishable_compat=false,
        config={extra={gains=0,gain=0.1,last_event=''}},
        loc_vars=function(self,queue,card)
            local e=card.ability.extra
            local es=(G.SETTINGS.language or ''):sub(1,2)=='es'
            return {vars={I.logic.format(e.gain,es),I.logic.format(factor(e),es)}}
        end,
        calculate=function(self,card,context)
            if card.debuff then return end
            if context.joker_main then return {x_mult=factor(card.ability.extra)} end
            if (context.overkill_log10 or 0)>=1 then return growth(card,context,'portrait_overkill') end
        end}
    register{key='hipster',rarity=3,cost=8,config={extra={xmult=2}},
        loc_vars=function(self,queue,card) return {vars={card.ability.extra.xmult}} end,
        calculate=function(self,card,context)
            if not card.debuff and context.joker_main and I.least_played(context.scoring_name,true) then
                return {x_mult=card.ability.extra.xmult}
            end
        end}
    register{key='collector',rarity=2,cost=6,config={extra={mult_per_type=3}},
        loc_vars=function(self,queue,card)
            local count=I.modification_count();local gain=card.ability.extra.mult_per_type
            return {vars={gain,count*gain,count}}
        end,
        calculate=function(self,card,context)
            if not card.debuff and context.joker_main then
                return {mult=I.modification_count()*card.ability.extra.mult_per_type}
            end
        end}
end
