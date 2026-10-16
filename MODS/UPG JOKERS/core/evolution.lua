return function(R)
    local E={triggers={}}
    function E.state(card)
        local s=card.ability.extra
        return s
    end
    function E.stage(def,card)
        return def.stages[E.state(card).stage or 1]
    end
    function E.visual_stage(def,card)
        local index=E.animation and E.animation.display_stage(card)
        return index and def.stages[index] or E.stage(def,card)
    end
    function E.refresh(def,card)
        local stage=E.visual_stage(def,card)
        local sprite=card.children and card.children.center
        -- Keep the ordinary undiscovered/locked collection artwork intact.
        if sprite and sprite.atlas.name=='upg_'..def.atlas then
            if sprite.sprite_pos.x~=stage.sprite.x or sprite.sprite_pos.y~=stage.sprite.y then
                sprite:set_sprite_pos(stage.sprite)
            end
        end
    end
    function E.effect(def,card)
        local stage=E.stage(def,card)
        local c=R.config()
        if def.effect then return def.effect(E.state(card),stage,c) end
        if stage.mult_key then return {mult=c[stage.mult_key]} end
        return {x_mult=c[stage.xmult_key]}
    end
    function E.upgrade(def,card)
        local old_stage=E.state(card).stage
        local new_stage=old_stage+1
        if not def.stages[new_stage] then return end
        -- Commit gameplay/save state once, synchronously. Further destructions
        -- in this same callback must use the new stage's growth immediately.
        E.state(card).stage=new_stage
        PortraitQOL.evolution(def,card,old_stage,new_stage)
        E.animation.play(card,old_stage,new_stage,def)
        E.refresh(def,card)
        return {calculated=true} -- The shared animation owns the single status message.
    end
    function E.triggers.rounds_won(def,card,context)
        if not (context.end_of_round and context.main_eval) or context.blueprint or
            context.repetition or context.retrigger_joker or context.individual or
            context.game_over or card.debuff or card.area~=G.jokers then return end
        local game=G.GAME
        local blind=game.blind
        if not game.facing_blind or not blind or blind.chips<=0 or game.chips<blind.chips then return end
        local s=E.state(card)
        local stage=E.stage(def,card)
        if stage.final then return end
        local token=tostring(game.round)..':'..tostring(game.round_resets.ante)..':'..blind.config.blind.key
        if s.last_won_round==token then return end
        s.last_won_round=token
        s.progress=s.progress+1
        if s.progress>=R.config()[stage.rounds_key] then
            s.progress=0
            return E.upgrade(def,card)
        end
        return {message=s.progress..'/'..R.config()[stage.rounds_key],colour=G.C.RARITY.upg_upgraded,card=card}
    end
    function E.triggers.playing_cards_destroyed(def,card,context)
        if not context.remove_playing_cards or context.blueprint or context.repetition or
            context.retrigger_joker or context.individual or card.debuff or card.getting_sliced or card.area~=G.jokers then return end
        local s,c=E.state(card),R.config()
        local owned={}
        for _,playing in ipairs(G.playing_cards or {}) do owned[playing]=true end
        local gained,upgrade=0,nil
        for _,playing in ipairs(context.removed or {}) do
            -- The native destruction context can arrive before or after removal.
            -- IDs in playing_card are renumbered, so use a saved destruction token.
            if playing.playing_card and playing.ability and
                (owned[playing] or playing.removed or playing.destroyed or playing.shattered) then
                local token=playing.ability.upg_destruction_token
                if not token then
                    G.GAME.upg_destruction_serial=(G.GAME.upg_destruction_serial or 0)+1
                    token=tostring(G.GAME.upg_destruction_serial)
                    playing.ability.upg_destruction_token=token
                end
                if not s.seen_destroyed[token] then
                    s.seen_destroyed[token]=true
                    local stage=E.stage(def,card)
                    local amount=c[stage.growth_key]
                    s.accumulated_mult=s.accumulated_mult+amount
                    gained=gained+amount
                    if not stage.final then
                        s.stage_progress=s.stage_progress+1
                        if s.stage_progress>=c[stage.required_key] then
                            s.stage_progress=0
                            upgrade=E.upgrade(def,card)
                        end
                    end
                end
            end
        end
        if upgrade then return upgrade end
        if gained>0 then return {message=localize{type='variable',key='a_mult',vars={gained}},colour=G.C.MULT,card=card} end
    end
    function E.advance(def,card,context)
        return E.triggers[def.trigger or 'rounds_won'](def,card,context)
    end
    function E.register(def)
        R.register(def)
        if def.mission or def.expansion48 then require('portrait_joker_missions').atlas(def.atlas)
        else SMODS.Atlas{key=def.atlas,path=def.atlas..'.png',px=71,py=95} end
        local center={
            key=def.key,upg_id=def.key,atlas=def.atlas,pos=def.stages[1].sprite,
            rarity='upg_upgraded',cost=R.mod.config[def.cost_key],
            unlocked=true,discovered=false,blueprint_compat=def.blueprint_compat~=false,
            eternal_compat=true,perishable_compat=true,
            config={extra=copy_table(def.initial_state or {stage=1,progress=0,last_won_round=''})},
            in_pool=function(self) return self.unlocked and R.enabled(def.key) end,
            set_sprites=function(_,card) if card.ability and type(card.ability.extra)=='table' then E.refresh(def,card) end end,
            update=function(_,card) E.refresh(def,card) end,
            loc_vars=function(_,queue,card)
                local stage=E.visual_stage(def,card)
                local c=R.config()
                local collection=card.fake_card
                for _,area in ipairs(G.your_collection or {}) do
                    if card.area==area then collection=true end
                end
                return {key=collection and 'j_upg_'..def.key or stage.loc_key,
                    vars=def.loc_vars and def.loc_vars(E.state(card),stage,c) or {c[stage.mult_key or stage.xmult_key],E.state(card).progress,
                          stage.rounds_key and c[stage.rounds_key] or 0}}
            end,
            calculate=function(_,card,context)
                if card.debuff then return end
                if def.calculate then return def.calculate(card,context,R,E) end
                if context.joker_main then return E.effect(def,card) end
                return E.advance(def,card,context)
            end,
        }
        if def.mission then require('portrait_joker_missions').decorate(center,def.mission) end
        if def.expansion48 then require('portrait_expansion48').decorate(center,def.expansion48) end
        SMODS.Joker(center)
    end
    -- Vanilla copy_card deep-copies ability tables. Refresh only the new UPG
    -- card's art after that copy, without resetting progress or sharing state.
    local copy=copy_card
    function copy_card(...)
        local card=copy(...)
        -- A physical copy is a different playing card, even if its source was
        -- already announced for destruction. Never copy the source's event ID.
        if card.ability then card.ability.upg_destruction_token=nil end
        local def=R.for_card(card)
        if def then E.refresh(def,card) end
        return card
    end
    return E
end
