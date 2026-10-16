-- One recipe matcher and transaction; acquisition adapters own payment/claim only.
return function(F,P)
    F.sources={};F.source_order={}
    function F.contains(area,card)
        for _,v in ipairs(area and area.cards or {}) do if v==card then return true end end
        return false
    end
    function F.register_source(id,adapter)
        assert(not F.sources[id],'Duplicate Fusion acquisition source: '..id)
        F.sources[id]=adapter;F.source_order[#F.source_order+1]=id
    end
    function F.source_valid(s)
        local c=s and s.card;local adapter=s and F.sources[s.kind]
        return adapter and s.game==G.GAME and G.STAGE==G.STAGES.RUN and c and
            not c.removed and not c.getting_sliced and not c.added_to_deck and
            c.ability.set=='Joker' and adapter.valid(s)
    end
    function F.source_afford(s)
        local adapter=F.sources[s.kind]
        return not adapter.afford or adapter.afford(s)
    end
    function F.source_pay(s)
        local adapter=F.sources[s.kind];if adapter.pay then adapter.pay(s) end
    end
    function F.source_finish(s,result) F.sources[s.kind].finish(s,result) end
    function F.acquisition(card)
        if not card or not card.ability or card.ability.set~='Joker' or not G.GAME or not F.enabled() then return end
        for _,id in ipairs(F.source_order) do
            local s=F.sources[id].resolve(card)
            if s then
                s.kind=id;s.card=card;s.game=G.GAME
                if F.source_valid(s) then return s end
            end
        end
    end
    function F.context_options(card,source)
        local out={};source=source or F.acquisition(card)
        if not source or not G.jokers then return out end
        for _,id in ipairs(F.order) do
            local d=F.entries[id]
            for _,owned in ipairs(G.jokers.cards) do
                local a,b
                if card.config.center.key==d.components[1] then a,b=card,owned
                elseif card.config.center.key==d.components[2] then a,b=owned,card end
                if a and F.can(d,a,b,source) then out[#out+1]={id=id,a=a,b=b,source=source} end
            end
        end
        return out
    end
    function F.context_ready()
        return not F.busy and not G.CONTROLLER.locked and not G.CONTROLLER.locks.use and
            not G.CONTROLLER.locks.toggle_shop and not G.TAROT_INTERRUPT and
            not (G.GAME.STOP_USE and G.GAME.STOP_USE>0)
    end

    F.register_source('shop',{
        resolve=function(c) if c.area==G.shop_jokers then return {area=c.area} end end,
        valid=function(s) return P.normal_shop() and s.area==G.shop_jokers and
            s.card.area==s.area and F.contains(s.area,s.card) end,
        afford=function(s) return s.card.cost==0 or s.card.cost<=G.GAME.dollars-G.GAME.bankrupt_at end,
        pay=function(s)
            s.paid=s.card.cost -- The live vanilla price already includes discounts/modifiers.
            if s.paid~=0 then ease_dollars(-s.paid,true) end
            inc_career_stat('c_shop_dollars_spent',s.paid)
            G.GAME.round_scores.cards_purchased.amt=G.GAME.round_scores.cards_purchased.amt+1
            G.GAME.current_round.jokers_purchased=G.GAME.current_round.jokers_purchased+1
        end,
        finish=function(s)
            discover_card(s.card.config.center)
            local eval,post=eval_card(s.card,{buying_card=true,buying_self=true,card=s.card})
            SMODS.trigger_effects({eval,post},s.card)
            SMODS.calculate_context{buying_card=true,card=s.card}
            if G.GAME.modifiers.inflation then
                G.GAME.inflation=G.GAME.inflation+1
                for _,c in pairs(G.I.CARD) do if not c.removed and c.set_cost then c:set_cost() end end
            end
        end,
    })
    F.register_source('pack',{
        resolve=function(c)
            if c.area and c.area==G.pack_cards and SMODS.OPENED_BOOSTER then
                return {area=c.area,booster=SMODS.OPENED_BOOSTER}
            end
        end,
        valid=function(s)
            if G.STATE~=G.STATES.SMODS_BOOSTER_OPENED or not G.booster_pack or
                s.booster~=SMODS.OPENED_BOOSTER or s.area~=G.pack_cards or
                s.card.area~=s.area or not F.contains(s.area,s.card) or
                (G.GAME.pack_choices or 0)<1 or (P.roulette and P.roulette.active()) then return false end
            local pack=s.booster.config.center
            for _,key in ipairs(pack.select_exclusions or {}) do if key==s.card.config.center.key then return false end end
            local area=SMODS.card_select_area(s.card,pack)
            if type(area)=='table' then area=area.Joker end
            return area==nil or area=='jokers'
        end,
        pay=function(s)
            F.track_pack(s.booster)
            G.GAME.pack_choices=G.GAME.pack_choices-1
        end,
        finish=function(s)
            discover_card(s.card.config.center)
            if s.card.config.center.on_select then s.card.config.center:on_select(s.card) end
            if G.GAME.pack_choices<=0 then G.FUNCS.end_consumeable(nil,0.2) end
        end,
    })
    F.register_source('roulette',{
        resolve=function(c)
            local R=P.roulette;local s=R and R.state()
            if s and c==R.feature then return {area=c.area,round=s,winner=s.winner} end
        end,
        valid=function(s)
            local R=P.roulette
            return R.active() and R.state()==s.round and s.round.phase=='result' and
                s.round.winner==s.winner and not R.animation and s.card==R.feature and
                s.card.area==G.pg_roulette_area and F.contains(G.pg_roulette_area,s.card)
        end,
        finish=function(s)
            -- The displayed winning copy was consumed; the actual prize must not be awarded again.
            P.roulette.finish(false,true)
        end,
    })
end
