-- Only rewards that cannot fit but can fuse are deferred; ordinary rewards retain their flow.
return function(F,P)
    local function pending() return G.GAME.fuse_rewards or {} end
    F.register_source('reward',{
        resolve=function(c)
            if c.fuse_reward_id then return {id=c.fuse_reward_id,area=c.area} end
        end,
        valid=function(s)
            for _,entry in ipairs(pending()) do
                if entry.id==s.id then return s.card.area==s.area and F.contains(s.area,s.card) end
            end
            return false
        end,
        finish=function(s)
            for i,entry in ipairs(pending()) do if entry.id==s.id then table.remove(G.GAME.fuse_rewards,i);break end end
            discover_card(s.card.config.center)
            G.FUNCS.exit_overlay_menu()
        end,
    })
    function P.defer_fusion_reward(card)
        if not F.enabled() then return false end
        G.GAME.fuse_reward_serial=(G.GAME.fuse_reward_serial or 0)+1
        local id=G.GAME.fuse_reward_serial
        G.GAME.fuse_rewards=G.GAME.fuse_rewards or {}
        local entry={id=id,card=card:save()}
        table.insert(G.GAME.fuse_rewards,entry)
        -- A temporary source used for validation only, never emplaced in the Joker inventory.
        local area={cards={card}};local old_area=card.area
        card.fuse_reward_id=id;card.area=area
        local valid=#F.context_options(card)>0
        card.area=old_area;card.fuse_reward_id=nil
        if not valid then table.remove(G.GAME.fuse_rewards);return false end
        return true
    end
    local function remove_entry(card)
        for i,entry in ipairs(pending()) do
            if entry.id==card.fuse_reward_id then table.remove(G.GAME.fuse_rewards,i);return true end
        end
    end
    function F.reward_offer()
        if not P.normal_shop() or G.OVERLAY_MENU or not pending()[1] then return false end
        local entry=pending()[1]
        local area=CardArea(0,0,G.CARD_W*2.5,G.CARD_H*1.1,{type='title_2',card_limit=1})
        local card=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.j_joker)
        card:load(copy_table(entry.card));card.fuse_reward_id=entry.id;card.fuse_reward_preview=true
        card.states.drag.can=false;area:emplace(card);card:highlight(true)
        local take=P.button(localize('b_select'),'fuse_reward_take',card)
        local function gate(node)
            if node.config and node.config.button=='fuse_reward_take' then node.config.func='can_fuse_reward_take' end
            for _,child in ipairs(node.nodes or {}) do gate(child) end
        end
        gate(take)
        P.open({P.text(localize('k_fuse_reward'),0.38),
            {n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.O,config={object=area}}}},take,
            P.button(localize('b_skip'),'fuse_reward_skip',card)})
        return true
    end
    G.FUNCS.can_fuse_reward_take=function(e)
        local c=e.config.ref_table
        local room=#G.jokers.cards+(G.GAME.joker_buffer or 0)<G.jokers.config.card_limit+
            (c.edition and c.edition.negative and 1 or 0)
        e.config.button=room and 'fuse_reward_take' or nil
        e.config.colour=room and G.C.GREEN or G.C.UI.BACKGROUND_INACTIVE
    end
    G.FUNCS.fuse_reward_take=function(e)
        G.FUNCS.can_fuse_reward_take(e)
        if not e.config.button or F.busy then return end
        local c=e.config.ref_table
        if not remove_entry(c) then return end
        c.area:remove_card(c);c.fuse_reward_preview=nil;c.fuse_reward_id=nil;c:highlight(false)
        c:add_to_deck();G.jokers:emplace(c);discover_card(c.config.center);c:start_materialize()
        G.FUNCS.exit_overlay_menu();save_run();G.FILE_HANDLER.force=true
    end
    G.FUNCS.fuse_reward_skip=function(e)
        if F.busy then return end
        if remove_entry(e.config.ref_table) then G.FUNCS.exit_overlay_menu();save_run();G.FILE_HANDLER.force=true end
    end
end
