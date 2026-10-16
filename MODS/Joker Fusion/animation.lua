return function(F,P)
    -- Presentation only. Consumption, inheritance and saving already completed.
    function F.animate(card)
        local game=G.GAME;local started=G.TIMERS.REAL
        G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
            if G.GAME~=game or card.removed or card.getting_sliced or card.area~=G.jokers or G.TIMERS.REAL-started>4 then return true end
            -- Reveal on the table, after the confirmation overlay has closed.
            if G.OVERLAY_MENU or G.SETTINGS.paused then return false end
            local fx=require('portrait_reward_fx')
            local level=fx.admit('fusion',tostring(card.sort_id)..':'..tostring(#(game.fusion_history or {})),2,75)
            if level>0 and not G.SETTINGS.reduced_motion then
                -- Native dissolve lasts 0.6 * timefac: 0.9s, shortened by Fast Animations.
                card:start_materialize({G.C.GOLD,G.C.RED,G.C.GOLD},true,1.5)
                card:juice_up(0.16,0.05)
            end
            if level>=2 then
                play_sound('tarot1',1.05,0.4)
                P.feedback('k_fuse_complete',G.C.GOLD)
                fx.milestone(card,nil,{admitted=level})
            end
            return true
        end})
    end
end
