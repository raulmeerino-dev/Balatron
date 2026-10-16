return function(F,P)
    local function text(value,scale)
        return {n=G.UIT.R,config={align='cm',padding=0.05},nodes={
            {n=G.UIT.T,config={text=value,scale=scale or 0.35,colour=G.C.WHITE,shadow=true}},
        }}
    end
    local function button(label,callback,selection)
        return {n=G.UIT.R,config={align='cm',minw=3.2,minh=portrait_touch_height(0.85),padding=0.08,
            r=0.1,colour=G.C.RED,button=callback,ref_table=selection,pg_run_action=true,hover=true,one_press=true},
            nodes={{n=G.UIT.T,config={text=label,scale=0.38,colour=G.C.WHITE,shadow=true}}}}
    end
    local function result_tile(V,id)
        if not F.discovered(id) then
            return V.tile({n=G.UIT.R,config={align='cm',minw=1.6,minh=2.15,r=0.1,colour=G.C.BLACK},nodes={text('?')}},
                function() return V.tooltip{title='???',text={'???'}} end,nil,'???')
        end
        local center=G.P_CENTERS['j_fuse_'..id]
        return V.tile(V.sprite(center.atlas,center.pos,2.15*71/95,2.15),function()
            -- A read-only preview of the result's initial effect, never a generated Joker.
            local preview={ability={extra={xmult=F.config().last_meal_initial}}}
            local loc=center:loc_vars({},preview)
            local lines=localize{type='raw_descriptions',set='Joker',key=loc.key or center.key,vars=loc.vars}
            lines[#lines+1]=localize('k_fuse_fusion')
            return V.tooltip{title=localize{type='name_text',set='Joker',key=center.key},text=lines}
        end,nil,localize{type='name_text',set='Joker',key=center.key})
    end
    function F.run_rows(V,owned)
        local rows={}
        local available=F.available()
        if #available>0 then rows[#rows+1]=text(localize('k_fuse_available_heading'),0.3) end
        for _,id in ipairs(available) do
            local d=F.entries[id];local a,b=F.components(d)
            local selection={id=id,a=a,b=b}
            local picked=P.fusion_selection
            local nodes={{n=G.UIT.R,config={align='cm',padding=0.04},nodes={
                V.joker_tile(a),{n=G.UIT.C,config={align='cm'},nodes={text('+')}},
                V.joker_tile(b),{n=G.UIT.C,config={align='cm'},nodes={text('>')}},result_tile(V,id),
            }}}
            if picked and picked.id==id and picked.a==a and picked.b==b then
                nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.1,colour=G.C.BLACK,r=0.1},nodes={
                    {n=G.UIT.C,config={align='cm',padding=0.06},nodes={
                        text(localize('k_fuse_confirm')),
                        {n=G.UIT.R,config={align='cm',padding=0.1},nodes={
                            {n=G.UIT.C,config={align='cm',padding=0.08},nodes={button(localize('b_fuse_yes'),'fuse_yes')}},
                            {n=G.UIT.C,config={align='cm',padding=0.08},nodes={button(localize('b_fuse_no'),'fuse_no')}},
                        }},
                    }},
                }}
            else nodes[#nodes+1]=button(localize('b_fuse_action'),'fuse_confirm',selection) end
            rows[#rows+1]={n=G.UIT.C,config={align='cm',padding=0.12},nodes=nodes}
        end
        if #owned>0 then
            rows[#rows+1]=text(localize('k_fuse_owned_heading'),0.3)
            for i=1,#owned,V.columns do
                local cells={};for j=i,math.min(i+V.columns-1,#owned) do cells[#cells+1]=owned[j] end
                rows[#rows+1]={n=G.UIT.R,config={align='cm'},nodes=cells}
            end
        end
        return rows
    end
    -- Only completed, discovered fusions disclose a recipe in Collection.
    local popup=G.UIDEF.card_h_popup
    function G.UIDEF.card_h_popup(card,...)
        local definition=popup(card,...)
        local center=card.config and card.config.center
        local id=center and center.key and center.key:match('^j_fuse_(.+)$')
        local d=id and F.entries[id]
        if not (d and F.discovered(id) and card.area and card.area.config.collection) then return definition end
        local recipe=localize{type='name_text',set='Joker',key=d.components[1]}..' + '..
            localize{type='name_text',set='Joker',key=d.components[2]}
        local lines={}
        for _,line in ipairs(PortraitRunGallery.wrap({recipe},30)) do lines[#lines+1]=text(line,0.32) end
        return {n=G.UIT.ROOT,config={align='cm',padding=0.04,colour=G.C.CLEAR},nodes={
            {n=G.UIT.R,config={align='cm'},nodes={definition}},
            {n=G.UIT.R,config={align='cm',padding=0.08,r=0.1,colour=G.C.BLACK},nodes={
                {n=G.UIT.C,config={align='cm'},nodes=lines}}},
        }}
    end
end
