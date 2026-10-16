return function(R)
    local mod=R.mod
    local function save() SMODS.save_mod_config(mod) end
    G.FUNCS.risk_toggle_family=function(args) mod.config.enabled=args.to_key==1; save() end
    for _,id in ipairs(R.order) do
        local key=id
        G.FUNCS['risk_toggle_'..key]=function(args) mod.config.jokers[key]=args.to_key==1; save() end
    end
    mod.config_tab=function()
        local nodes={create_option_cycle{label='Risk Jokers',w=4,scale=0.8,
            options={'ON','OFF'},current_option=mod.config.enabled and 1 or 2,opt_callback='risk_toggle_family'}}
        for _,id in ipairs(R.order) do
            local label=localize{type='name_text',set='Joker',key='j_risk_'..id}
            if not R.entries[id].art_available then label=label..' ('..localize('k_risk_missing_art')..')' end
            nodes[#nodes+1]=create_option_cycle{label=label,w=4,scale=0.8,
                options={'ON','OFF'},current_option=mod.config.jokers[id] and 1 or 2,opt_callback='risk_toggle_'..id}
        end
        nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.12},nodes={
            {n=G.UIT.T,config={text=localize('k_risk_next_run'),scale=0.3,colour=G.C.UI.TEXT_LIGHT}}}}
        return {n=G.UIT.ROOT,config={align='cm',padding=0.15,colour=G.C.CLEAR},nodes=nodes}
    end
    -- The native Mods-list checkbox must control generation, NOT write
    -- .lovelyignore and unload definitions needed by saved runs.
    local toggle=create_toggle
    function create_toggle(args)
        if args and args.ref_table==mod and args.ref_value=='should_enable' then
            args.ref_table=mod.config
            args.ref_value='enabled'
            args.callback=save
        end
        return toggle(args)
    end
end
