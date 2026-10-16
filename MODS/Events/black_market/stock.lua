return function(B)
    function B.eligible(center)
        if not center or center.unlocked==false or G.GAME.banned_keys[center.key] or not B.registry.mod_enabled(center) then return false end
        if center.set=='Joker' and (center.rarity==4 or center.rarity=='Legendary') then return false end
        if center.no_pool_flag and G.GAME.pool_flags[center.no_pool_flag] then return false end
        if center.yes_pool_flag and not G.GAME.pool_flags[center.yes_pool_flag] then return false end
        return center.set~='Joker' or not G.GAME.used_jokers[center.key] or SMODS.showman(center.key)
    end
    function B.pool(set,rarity)
        local result={}
        local pool=get_current_pool(set,rarity,false,'evt_bm')
        for _,key in ipairs(pool) do
            local center=G.P_CENTERS[key]
            if center and not center.bm_contraband and B.eligible(center) and
                SMODS.add_to_pool(center,{source='evt_bm'}) and
                (not rarity or center.rarity==rarity or (rarity=='Common' and center.rarity==1) or (rarity=='Uncommon' and center.rarity==2) or (rarity=='Rare' and center.rarity==3)) then
                if set~='Voucher' or not G.GAME.used_vouchers[key] then result[#result+1]=key end
            end
        end
        return result
    end
    function B.opted_jokers()
        local result={}
        for _,center in ipairs(G.P_CENTER_POOLS.Joker) do
            if center.black_market_weight and center.black_market_in_pool and B.eligible(center) and center:black_market_in_pool() then
                local weight=type(center.black_market_weight)=='function' and center:black_market_weight() or center.black_market_weight
                if weight>0 then result[#result+1]={key=center.key,weight=weight} end
            end
        end
        return result
    end
    function B.normal_joker_groups()
        local groups={}
        for _,rarity in ipairs(SMODS.ObjectTypes.Joker.rarities) do
            if rarity.key~='Legendary' then
                local definition=SMODS.Rarities[rarity.key]
                local weight=rarity.weight or 0
                if definition and definition.get_weight then weight=definition:get_weight(weight,SMODS.ObjectTypes.Joker) end
                weight=(weight or 0)*(G.GAME[tostring(rarity.key):lower()..'_mod'] or 1)
                if weight>0 then groups[#groups+1]={keys=B.pool('Joker',rarity.key),weight=weight} end
            end
        end
        local included={}
        for _,group in ipairs(groups) do for _,key in ipairs(group.keys) do included[key]=true end end
        for _,item in ipairs(B.opted_jokers()) do
            if not included[item.key] then groups[#groups+1]={keys={item.key},weight=item.weight} end
        end
        return groups
    end
    function B.joker_key(special,rare_only)
        local c=B.config()
        local groups={}
        local function group(keys,weight)
            if #keys>0 and weight>0 then groups[#groups+1]={keys=keys,weight=weight} end
        end
        if not rare_only then group(B.pool('Joker','Uncommon'),special and c.slot2_uncommon_weight or c.slot1_uncommon_weight) end
        group(B.pool('Joker','Rare'),rare_only and 1 or special and c.slot2_rare_weight or c.slot1_rare_weight)
        if special then
            local rarities={}
            for key in pairs(SMODS.Rarities) do rarities[#rarities+1]=key end
            table.sort(rarities)
            for _,key in ipairs(rarities) do
                if key~='Common' and key~='Uncommon' and key~='Rare' and key~='Legendary' then
                    local r=SMODS.Rarities[key]
                    local weight=r.get_weight and r:get_weight(r.default_weight,SMODS.ObjectTypes.Joker) or r.default_weight
                    if r.black_market_weight then
                        weight=type(r.black_market_weight)=='function' and r:black_market_weight() or r.black_market_weight
                    end
                    local overrides=c.black_market_rarity_weights or B.registry.mod.config.black_market_rarity_weights
                    if overrides and overrides[key]~=nil then weight=overrides[key] end
                    group(B.pool('Joker',key),weight or 0)
                end
            end
            -- Opt-in for rare shop-only cards; each mod owns its eligibility.
            for _,center in ipairs(G.P_CENTER_POOLS.Joker) do
                if center.black_market_weight and center.black_market_in_pool and B.eligible(center) and center:black_market_in_pool() then
                    local weight=type(center.black_market_weight)=='function' and center:black_market_weight() or center.black_market_weight
                    group({center.key},weight)
                end
            end
        end
        local total=0
        for _,g in ipairs(groups) do total=total+g.weight end
        if total==0 then return end
        local draw=B.roll('rarity')*total
        for _,g in ipairs(groups) do
            draw=draw-g.weight
            if draw<0 then return B.choose(g.keys,'joker') end
        end
    end
    function B.create(key,area)
        if not key then return end
        local center=G.P_CENTERS[key]
        local card=SMODS.create_card{set=center.set,key=key,area=area,key_append='evt_bm_'..B.current().id,skip_materialize=true}
        SMODS.calculate_context({modify_shop_card=true,card=card,black_market=true})
        card.ability.evt_bm_price=B.current().heat_factor*(center.bm_contraband and 1 or B.config().black_market_price_multiplier)
        card:set_cost()
        create_shop_card_ui(card)
        return card
    end
    function B.fill_stock()
        for i=1,2 do
            local card=B.create(B.joker_key(i==2),G.shop_jokers)
            if card then G.shop_jokers:emplace(card); card:start_materialize() end
        end
        local c=B.config()
        local kinds={{'Tarot',c.tarot_weight},{'Planet',c.planet_weight},{'Spectral',c.spectral_weight}}
        local choices,total={},0
        for _,k in ipairs(kinds) do
            local pool=B.pool(k[1])
            if #pool>0 then choices[#choices+1]={pool=pool,weight=k[2]}; total=total+k[2] end
        end
        local draw=B.roll('consumable')*total
        for _,choice in ipairs(choices) do
            draw=draw-choice.weight
            if draw<0 then
                local card=B.create(B.choose(choice.pool,'consumable_key'),G.shop_vouchers)
                G.shop_vouchers:emplace(card); card:start_materialize(); break
            end
        end
    end
end
