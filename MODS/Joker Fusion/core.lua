return function(F,P)
    F.entries={};F.order={}
    function F.discovered(id)
        local profile=G.PROFILES[G.SETTINGS.profile]
        local center=G.P_CENTERS['j_fuse_'..id]
        return (profile.joker_fusion_recipes and profile.joker_fusion_recipes[id]) or (center and center.discovered)
    end
    function F.sync_discovery()
        -- Preserve discoveries from older profiles and seeded fusion runs too.
        -- Only Fusion centers are reconciled; vanilla discovery rules stay intact.
        local known=G.PROFILES[G.SETTINGS.profile].joker_fusion_recipes or {}
        local changed=false
        for _,id in ipairs(F.order) do
            local center=G.P_CENTERS['j_fuse_'..id]
            if known[id] and center and not center.discovered then
                center.discovered=true;center.alert=true;changed=true
            end
        end
        if changed then set_discover_tallies();G:save_progress() end
    end
    function F.inherit(a,b)
        -- Recipe-order priority: first component's edition wins a conflict.
        -- No edition mixing; an Eternal result cannot also be Perishable.
        local eternal=a.ability.eternal or b.ability.eternal
        return {edition=(a.edition or b.edition) and copy_table(a.edition or b.edition),eternal=eternal,
            rental=a.ability.rental or b.ability.rental,
            perishable=not eternal and (a.ability.perishable or b.ability.perishable),
            perish_tally=math.min(a.ability.perishable and a.ability.perish_tally or G.GAME.perishable_rounds,
                b.ability.perishable and b.ability.perish_tally or G.GAME.perishable_rounds)}
    end
    function F.register(d)
        d.inherit=d.inherit or F.inherit
        d.can_fuse=d.can_fuse or function(a,b)
            for _,card in ipairs({a,b}) do
                if SMODS.is_eternal(card,{fusion=true}) and not card.ability.eternal then return false end
                if card.edition and not (card.edition.foil or card.edition.holo or card.edition.polychrome or card.edition.negative) then return false end
            end
            return true
        end
        -- Internal component counters reset; recipes can explicitly override this.
        d.transfer_state=d.transfer_state or function() end
        F.entries[d.id]=d;F.order[#F.order+1]=d.id
    end
    function F.components(d)
        local a,b
        for _,card in ipairs(G.jokers.cards) do
            if not card.removed and not card.getting_sliced then
                if not a and card.config.center.key==d.components[1] then a=card
                elseif not b and card.config.center.key==d.components[2] then b=card end
            end
        end
        return a,b
    end
    function F.can(d,a,b,source)
        if not d or F.entries[d.id]~=d or not G.jokers or not F.enabled() or not F.config().recipes[d.id] or
            not G.P_CENTERS['j_fuse_'..d.id] or
            not a or not b or a==b or
            a.ability.exp48_lease or b.ability.exp48_lease or
            a.ability.x48_last_performance or b.ability.x48_last_performance or
            a.removed or b.removed or a.getting_sliced or b.getting_sliced or
            a.config.center.key~=d.components[1] or b.config.center.key~=d.components[2] or
            G.GAME.banned_keys['j_fuse_'..d.id] or not d.can_fuse(a,b) then return false end
        if source then
            local external=source.card
            local owned=external==a and b or external==b and a
            if not owned or owned.area~=G.jokers or not F.contains(G.jokers,owned) or
                not F.source_valid(source) then return false end
        elseif not P.normal_shop() or a.area~=G.jokers or b.area~=G.jokers then return false end
        local info=d.inherit(a,b)
        local limit=G.jokers.config.card_limit
        local count=#G.jokers.cards+1+(G.GAME.joker_buffer or 0)
        for _,component in ipairs({a,b}) do
            if component.area==G.jokers then
                count=count-1
                limit=limit-(component.edition and component.edition.negative and 1 or 0)
            end
        end
        limit=limit+(info.edition and info.edition.negative and 1 or 0)
        return count<=limit
    end
    function F.available()
        local out={}
        if not G.jokers or not F.enabled() then return out end
        for _,id in ipairs(F.order) do
            local d=F.entries[id];local a,b=F.components(d)
            if F.can(d,a,b) then out[#out+1]=id end
        end
        return out
    end
    function F.fuse(selection)
        if not selection or F.busy then return false end
        local d,a,b=F.entries[selection.id],selection.a,selection.b
        local source=selection.source
        if not d or not F.can(d,a,b,source) or (source and not F.source_afford(source)) then return false end
        F.busy=true
        local info=d.inherit(a,b)
        -- Prepare the result before consuming anything. This transaction is synchronous.
        local card=SMODS.create_card{set='Joker',key='j_fuse_'..d.id,area=G.jokers,no_edition=true,
            skip_materialize=true,key_append='fusion'}
        card:set_edition(info.edition,true,true)
        card.ability.eternal=nil;card.ability.perishable=nil
        card:set_eternal(info.eternal or false)
        if info.perishable then card:set_perishable(true) end
        card:set_rental(info.rental or false)
        if info.perishable then card.ability.perish_tally=info.perish_tally end
        d.transfer_state(card,a,b)
        if source then F.source_pay(source) end
        for _,component in ipairs({a,b}) do
            component:juice_up(0.2,0.1)
            component:remove_from_deck()
            if component.area then component.area:remove_card(component) end
            -- Keep the external object alive for native acquisition callbacks.
            if not source or component~=source.card then component:remove() end
        end
        card:add_to_deck();G.jokers:emplace(card)
        if G.jokers.handle_card_limit then G.jokers:handle_card_limit() end
        if source then F.source_finish(source,card);source.card:remove() end
        local profile=G.PROFILES[G.SETTINGS.profile]
        profile.joker_fusion_recipes=profile.joker_fusion_recipes or {};profile.joker_fusion_recipes[d.id]=true
        PortraitQOL.history('fusion',{name=localize{type='name_text',set='Joker',key=card.config.center.key},
            from=localize{type='name_text',set='Joker',key=d.components[1]}..' + '..localize{type='name_text',set='Joker',key=d.components[2]},
            to=localize{type='name_text',set='Joker',key=card.config.center.key}})
        PortraitQOL.haptic('fusion')
        discover_card(card.config.center);F.sync_discovery();G:save_progress()
        if PortraitRunRules then PortraitRunRules.fusion_completed(card) end
        F.busy=false;G.FILE_HANDLER.force=true;save_run()
        F.animate(card);return true
    end
end
