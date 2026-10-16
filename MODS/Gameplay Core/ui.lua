return function(P)
    function P.text(str,scale)
        return {n=G.UIT.R,config={align='cm',padding=0.035,maxw=4.8},nodes={
            {n=G.UIT.T,config={text=str,scale=scale or 0.32,colour=G.C.UI.TEXT_LIGHT,shadow=true}}}}
    end
    function P.button(label,callback,ref)
        local node=UIBox_button{label={label},button=callback,minw=4.3,minh=portrait_touch_height(0.8),scale=0.34,colour=G.C.RED}
        -- UIBox_button puts the actionable config on its inner row.
        local function visit(n)
            if n.config and n.config.button==callback then n.config.ref_table=ref end
            for _,child in ipairs(n.nodes or {}) do visit(child) end
        end
        visit(node);return node
    end
    function P.panel(nodes)
        return {n=G.UIT.ROOT,config={align='cm',padding=0.12,colour=G.C.CLEAR},nodes=nodes}
    end
    function P.open(nodes,back)
        G.SETTINGS.paused=true
        G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{
            back_func=back or 'exit_overlay_menu',contents={P.panel(nodes)}}}
    end
    function P.details(set,key,vars)
        local lines=localize{type='raw_descriptions',set=set,key=key,vars=vars or {}}
        local out={}
        for _,line in ipairs(lines or {}) do out[#out+1]=P.text(line,0.29) end
        return out
    end
    function P.append(to,from) for _,v in ipairs(from) do to[#to+1]=v end end
    function P.run_panel()
        if PortraitRunGallery then return PortraitRunGallery.panel() end
        return P.panel({P.text(localize('k_pg_none'))})
    end
    G.FUNCS.pg_info=function(e) P.modules[e.config.ref_table].run_info() end
    local tabs=create_tabs
    function create_tabs(args)
        if P.in_run_info then
            if P.open_run_tab then for _,tab in ipairs(args.tabs) do tab.chosen=false end end
            args.tabs[#args.tabs+1]={label=localize('k_pg_run'),chosen=P.open_run_tab,tab_definition_function=P.run_panel}
        end
        return tabs(args)
    end
    local run_info=G.UIDEF.run_info
    function G.UIDEF.run_info(...)
        P.in_run_info=true
        local result=run_info(...)
        P.in_run_info=false
        return result
    end
    function P.normal_shop()
        return G.STATE==G.STATES.SHOP and not (PortraitEvents and PortraitEvents.black_market.active)
    end
    function P.schedule_offers()
        if P.offer_queued then return end
        local game=G.GAME;P.offer_queued=true
        G.E_MANAGER:add_event(Event{blocking=false,blockable=false,func=function()
            if G.GAME~=game or not P.normal_shop() then P.offer_queued=false;return true end
            if not G.shop or G.OVERLAY_MENU then return false end
            local contracts=P.modules.contracts
            local results=contracts and contracts.state() and contracts.state().results
            if results and results[1] then return false end
            P.offer_queued=false
            for _,id in ipairs(P.order) do
                local m=P.modules[id]
                if m.offer and m.offer() then return true end
            end
            return true
        end})
    end
    -- Called after the native shop has populated/restored every area, including load.
    function P.shop_ready()
        if P.normal_shop() then
            for _,id in ipairs(P.order) do local m=P.modules[id];if m.shop then m.shop() end end
            save_run()
            P.schedule_offers()
        end
    end
    local leave=G.FUNCS.toggle_shop
    G.FUNCS.toggle_shop=function(e)
        if P.normal_shop() then
            for _,id in ipairs(P.order) do
                local m=P.modules[id]
                if m.required_offer and m.required_offer() then m.offer();return end
            end
        end
        return leave(e)
    end
end
