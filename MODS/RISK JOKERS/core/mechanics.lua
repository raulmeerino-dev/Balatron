return function(R)
    local M={}
    function M.blind_token()
        local g=G.GAME
        return tostring(g.round)..':'..tostring(g.round_resets.ante)..':'..g.blind.config.blind.key
    end
    function M.real(card,context)
        return card.area==G.jokers and not card.debuff and not card.removed and
            not card.getting_sliced and not card.ability.extra.risk_pending_destroy and not context.blueprint and not context.repetition and
            not context.retrigger_joker and not context.individual
    end
    function M.won(card,context)
        if not (context.end_of_round and context.main_eval) or context.game_over or not M.real(card,context) then return false end
        local g=G.GAME
        if not g.facing_blind or not g.blind or g.blind.chips<=0 or g.chips<g.blind.chips then return false end
        local s,token=card.ability.extra,M.blind_token()
        if s.last_won_blind==token then return false end
        s.last_won_blind=token
        return true
    end
    function M.scoring_hand(card,context)
        if not context.initial_scoring_step or not M.real(card,context) then return false end
        local s=card.ability.extra
        local token=M.blind_token()..':'..tostring(G.GAME.hands_played)
        if s.last_scoring_hand==token then return false end
        s.last_scoring_hand=token
        return true
    end
    function M.destroy(card)
        if not card.removed and not card.getting_sliced and card.area==G.jokers then
            SMODS.destroy_cards(card) -- Native Eternal/protection checks and dissolve.
            -- Native animation flags are not serialized. Keep the accepted
            -- destruction in the ability until the card is actually removed.
            if card.getting_sliced then card.ability.extra.risk_pending_destroy=true end
        end
    end
    function M.first_hand(card,context)
        if not context.portrait_hand_result or not M.real(card,context) or G.GAME.current_round.hands_played~=0 then return end
        local game,s,token=G.GAME,card.ability.extra,M.blind_token()
        if not game.facing_blind or type(context.record_score)~='number' or game.blind.chips<=0 then return end
        if s.checked_blind==token then return end
        s.checked_blind=token
        -- Settle against final score synchronously, like All or Nothing. A save
        -- must not retain the receipt while losing a queued destruction check.
        if context.record_score<game.blind.chips-game.chips then M.destroy(card) end
    end
    function M.register(def)
        R.register(def)
        -- Unprovided artwork must not crash the loader or fall back to vanilla art.
        -- Generation switches never use this gate; registered definitions stay loaded.
        def.art_available=NFS.getInfo(R.mod.path..'assets/1x/'..def.key..'.png')~=nil and
            NFS.getInfo(R.mod.path..'assets/2x/'..def.key..'.png')~=nil
        if not def.art_available then return end
        SMODS.Atlas{key=def.key,path=def.key..'.png',px=71,py=95}
        SMODS.Joker{
            key=def.key,risk_id=def.key,atlas=def.key,pos={x=0,y=0},
            rarity='risk_risk',cost=R.mod.config[def.cost_key],
            unlocked=true,discovered=false,blueprint_compat=true,eternal_compat=true,perishable_compat=true,
            config={extra=def.initial_state and def.initial_state(R.mod.config) or {}},
            set_ability=function(_,card,initial,delay_sprites)
                if def.initial_state then card.ability.extra=def.initial_state(R.config()) end
            end,
            in_pool=function() return R.enabled(def.key) end,
            loc_vars=function(_,queue,card) return {vars=def.vars(card.ability.extra,R.config())} end,
            update=function(_,card)
                if card.ability.extra.risk_pending_destroy then M.destroy(card) end
            end,
            calculate=function(_,card,context)
                if card.debuff or card.ability.extra.risk_pending_destroy then return end
                if context.joker_main then
                    local value=def.mult(card.ability.extra,R.config(),card,context)
                    if value then return {x_mult=value} end
                    return
                end
                return def.secondary(card,context,R.config(),M)
            end,
        }
    end
    return M
end
