return function(F,P)
    local function name(key) return localize{type='name_text',set='Joker',key=key} end
    -- Availability is derived from the actual owned instances and the existing legality check.
    local game,notified,signature=nil,{},''
    F.badge=''
    function F.refresh()
        if game~=G.GAME then game=G.GAME;notified={};signature='';P.fusion_selection=nil end
        if not F.state() or not G.jokers then F.badge='';return end
        local available=F.available()
        local live,new={},false
        for _,id in ipairs(available) do
            local a,b=F.components(F.entries[id])
            live[#live+1]=id..':'..tostring(a)..':'..tostring(b)
            local old=notified[id]
            if not old or old.a~=a or old.b~=b then new=true;notified[id]={a=a,b=b} end
        end
        for id,pair in pairs(notified) do
            if pair.a.area~=G.jokers or pair.b.area~=G.jokers or pair.a.removed or pair.b.removed then notified[id]=nil end
        end
        F.badge=#available>0 and '!' or ''
        local selected=P.fusion_selection
        if selected and not F.can(F.entries[selected.id],selected.a,selected.b) then P.fusion_selection=nil end
        local next_signature=table.concat(live,'|')..':'..tostring(#(G.GAME.fusion_history or {}))
        if signature~=next_signature then
            signature=next_signature
            if PortraitRunGallery then PortraitRunGallery.refresh() end
        end
        if new then P.feedback('k_fuse_available',G.C.GOLD) end
    end
    local update=Game.update
    function Game:update(dt) update(self,dt);F.refresh() end
    function F.offer() F.refresh();return F.reward_offer() end
    function F.run_info() if PortraitRunGallery then PortraitRunGallery.open() end end
    G.FUNCS.fuse_confirm=function(e)
        local selection=e.config.ref_table
        if type(selection)=='string' then
            local d=F.entries[selection];if not d then return end
            local a,b=F.components(d);selection={id=d.id,a=a,b=b}
        end
        if not selection or not F.entries[selection.id] or not F.can(F.entries[selection.id],selection.a,selection.b) then
            F.refresh();return
        end
        P.fusion_selection=selection
        PortraitRunGallery.refresh()
    end
    G.FUNCS.fuse_yes=function()
        local selection=P.fusion_selection;P.fusion_selection=nil
        if F.fuse(selection) then G.FUNCS.exit_overlay_menu()
        else PortraitRunGallery.refresh() end
        F.refresh()
    end
    G.FUNCS.fuse_no=function() P.fusion_selection=nil;PortraitRunGallery.refresh() end
    local hud=create_UIBox_HUD_vertical
    function create_UIBox_HUD_vertical(...)
        local definition=hud(...)
        local function visit(node)
            if node.config and node.config.id=='run_info_button' then
                local label_row=node.nodes[1]
                label_row.config.maxw=2.3
                label_row.nodes[#label_row.nodes+1]={n=G.UIT.C,config={align='cm',minw=0.3},nodes={
                    {n=G.UIT.T,config={text=F.badge,ref_table=F,ref_value='badge',no_recalc=true,
                        scale=0.45,colour=G.C.GOLD,shadow=true}},
                }}
                return
            end
            for _,child in ipairs(node.nodes or {}) do visit(child) end
        end
        visit(definition);return definition
    end
    assert(SMODS.load_file('run_ui.lua'))()(F,P)
    G.FUNCS.fuse_collection=function()
        F.sync_discovery()
        local pool={}
        for _,id in ipairs(F.order) do
            pool[#pool+1]=G.P_CENTERS['j_fuse_'..id]
        end
        G.SETTINGS.paused=true
        G.FUNCS.overlay_menu{definition=SMODS.card_collection_UIBox(pool,{2,2},{
            card_scale=1.15,w_mod=1.35,h_mod=1.2,no_materialize=true,
            hide_single_page=true,collapse_single_page=true,
            back_func=G.STAGE==G.STAGES.RUN and 'exit_overlay_menu' or 'your_collection',
        })}
    end
    -- Retain the callback for existing links, without exposing any recipes.
    G.FUNCS.fuse_recipe=function(e)
        G.FUNCS.fuse_collection()
    end
    local collection=create_UIBox_your_collection
    function create_UIBox_your_collection(...)
        local result=collection(...)
        local function visit(node)
            for i,child in ipairs(node.nodes or {}) do
                if child.config and child.config.id=='your_collection_jokers' then
                    table.insert(node.nodes,i+1,P.button(localize('k_fuse_collection'),'fuse_collection'));return true
                end
                if visit(child) then return true end
            end
        end
        visit(result);return result
    end
end
