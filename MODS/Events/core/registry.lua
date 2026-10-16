return function(mod)
    local R={mod=mod,entries={},order={}}
    function R.register(key,label)
        R.entries[key]={label=label}; R.order[#R.order+1]=key
        if mod.config.events[key]==nil then mod.config.events[key]=true end
    end
    function R.begin_run(loading)
        if not loading or not G.GAME.portrait_events then
            local config=copy_table(mod.config)
            if loading then for key in pairs(config.events) do config.events[key]=false end end
            local mods={}
            for id,m in pairs(SMODS.Mods) do mods[id]=m.can_load and not m.disabled and m.should_enable~=false end
            G.GAME.portrait_events={config=config,mods=mods}
        end
    end
    function R.enabled(key)
        local s=G.GAME and G.GAME.portrait_events
        return s and s.config.events[key]==true
    end
    function R.config() return G.GAME.portrait_events.config end
    function R.mod_enabled(center)
        local m=center.mod
        return not m or (G.GAME.portrait_events.mods[m.id]==true and m.can_load and not m.disabled)
    end
    function R.install_menu()
        for _,id in ipairs(R.order) do
            local key=id
            G.FUNCS['evt_toggle_'..key]=function(args)
                mod.config.events[key]=args.to_key==1; SMODS.save_mod_config(mod)
            end
        end
        mod.config_tab=function()
            local nodes={}
            for _,id in ipairs(R.order) do
                nodes[#nodes+1]=create_option_cycle{label=localize(R.entries[id].label),w=4,scale=0.8,
                    options={'ON','OFF'},current_option=mod.config.events[id] and 1 or 2,opt_callback='evt_toggle_'..id}
            end
            nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.1},nodes={
                {n=G.UIT.T,config={text=localize('k_evt_next_run'),scale=0.3,colour=G.C.UI.TEXT_LIGHT}}}}
            return {n=G.UIT.ROOT,config={align='cm',padding=0.15,colour=G.C.CLEAR},nodes=nodes}
        end
        -- Keep saved event definitions available when disabling generation.
        local toggle=create_toggle
        function create_toggle(args)
            if args and args.ref_table==mod and args.ref_value=='should_enable' then
                args.ref_table=mod.config.events; args.ref_value='black_market'
                args.callback=function() SMODS.save_mod_config(mod) end
            end
            return toggle(args)
        end
    end
    return R
end
