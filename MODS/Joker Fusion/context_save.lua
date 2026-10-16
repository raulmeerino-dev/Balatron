-- Persist an already-open pack after a contextual Fusion, without replaying its purchase/RNG.
return function(F,P)
    function F.track_pack(booster)
        G.GAME.fuse_pack=G.GAME.fuse_pack or {booster=booster:save()}
    end
    local save=save_run
    function save_run(...)
        if F.busy then return end -- no partial purchase, claim or component consumption on disk
        local tracked=G.GAME and G.GAME.fuse_pack
        if tracked and G.STATE~=G.STATES.SMODS_BOOSTER_OPENED and not G.TAROT_INTERRUPT then
            G.GAME.fuse_pack=nil;tracked=nil
        end
        if tracked and G.CONTROLLER.locks.use then return end
        -- Steamodded deliberately skips ordinary pack saves. Our tracked pack has
        -- a matching restore path, so capture through the native serializer once.
        local state=G.STATE
        if tracked then G.STATE=G.GAME.PACK_INTERRUPT or G.STATES.SHOP end
        local result=save(...)
        G.STATE=state
        if tracked and G.ARGS.save_run then
            G.ARGS.save_run.STATE=state
            G.ARGS.save_run.ACTION=nil -- never replay the original paid booster opening
        end
        return result
    end
    local start=Game.start_run
    function Game:start_run(args,...)
        F.busy=false
        local result=start(self,args,...)
        local saved=args and args.savetext
        local tracked=saved and G.GAME.fuse_pack
        if tracked then
            local booster=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.p_buffoon_normal_1)
            booster:load(copy_table(tracked.booster))
            local center=booster.config.center
            SMODS.OPENED_BOOSTER=booster;booster_obj=center
            -- Native opened boosters are detached too; the object remains the pack descriptor.
            booster:remove()
            if G.pack_cards then G.pack_cards:remove();G.pack_cards=nil end
            G.booster_pack=UIBox{definition=center:create_UIBox(),
                config={align='tmi',offset={x=0,y=-2.2},major=G.hand,bond='Weak'}}
            G.pack_cards:load(copy_table(saved.cardAreas.pack_cards))
            G.load_pack_cards=nil
            G.STATE=G.STATES.SMODS_BOOSTER_OPENED;G.STATE_COMPLETE=true
            if G.buttons then G.buttons:remove();G.buttons=nil end
            center:ease_background_colour()
            if G.F_PORTRAIT then portrait_anchor_run_panel(G.booster_pack,true) end
            if (G.GAME.pack_choices or 0)<=0 then G.FUNCS.end_consumeable(nil,0.2) end
        end
        return result
    end
    local use=G.FUNCS.use_card
    G.FUNCS.use_card=function(e,...)
        local tracking=G.GAME.fuse_pack;local game=G.GAME
        local result=use(e,...)
        if tracking then
            G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
                if G.GAME~=game then return true end
                if G.CONTROLLER.locks.use or G.TAROT_INTERRUPT then return false end
                save_run();G.FILE_HANDLER.force=true;return true
            end})
        end
        return result
    end
end
