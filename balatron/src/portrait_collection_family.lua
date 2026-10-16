-- Read-only family previews use registered forms and profile discovery receipts.
local F={}
local function es() return (G.SETTINGS.language or ''):sub(1,2)=='es' end
function F.mutation_levels(id)
    local M=PortraitGameplay.modules.deck_mutations
    for _,def in ipairs(M.definitions) do
        if def.id==id then return def.levels and M.config().max_level or 1 end
    end
    return 0
end
function F.upg_info(id,index)
    local R=UPGJokers.registry;local def=R.entries[id];local stage=def.stages[index]
    local config=R.mod.config
    local state=copy_table(def.initial_state or {progress=0});state.stage=index
    local vars=def.loc_vars and def.loc_vars(state,stage,config) or
        {config[stage.mult_key or stage.xmult_key],0,stage.rounds_key and config[stage.rounds_key] or 0}
    return {title=localize{type='name_text',set='Joker',key=stage.loc_key},
        text=localize{type='raw_descriptions',set='Joker',key=stage.loc_key,vars=vars}}
end
local function line(value,scale,width,colour)
    return {n=G.UIT.R,config={align='cl',padding=0.025,maxw=width},nodes={
        {n=G.UIT.T,config={text=value,scale=scale,colour=colour or G.C.WHITE,shadow=true}}}}
end
function F.open(kind,id)
    local overlay=G.OVERLAY_MENU
    if not overlay or overlay.pc_collection_underlay then return end
    local C=PortraitCollection;local M=PortraitGameplay.modules.deck_mutations
    local def=kind=='upg' and UPGJokers.registry.entries[id]
    local count=def and #def.stages or kind=='mutations' and F.mutation_levels(id) or 0
    if count<1 then return end
    local width=math.min(8.5,G.ROOM.T.w-0.8)
    local text_width=width-2.65
    local title=def and def.name or localize('k_dm_'..id)
    local stages,sequence={},{}
    for i=1,count do
        sequence[i]=tostring(i)
        local data,art,known
        if def then
            data=F.upg_info(id,i)
            art=PortraitRunGallery.sprite('upg_'..def.atlas,def.stages[i].sprite,2*71/95,2)
            local center=G.P_CENTERS['j_upg_'..id]
            known=C.known('upg_forms',id..':'..i) or i==1 and center and center.discovered
        else
            data=M.visual_info(id,i);art=M.icon(id,1.7)
            known=(C.known('mutations',id) or 0)>=i
        end
        local label=def and (i==1 and (es() and 'Inicial' or 'Initial') or
            (es() and 'Evolución ' or 'Evolution ')..(i-1)) or (es() and 'Nivel ' or 'Level ')..i
        local details={line(label,0.30,text_width,G.C.GOLD)}
        for _,part in ipairs(PortraitRunGallery.wrap({data.title},26)) do
            details[#details+1]=line(part,0.40,text_width)
        end
        for _,part in ipairs(PortraitRunGallery.wrap(data.text,30)) do
            details[#details+1]=line(part,0.36,text_width)
        end
        details[#details+1]=line(known and (es() and 'Descubierto' or 'Discovered') or
            (es() and 'Por descubrir' or 'Undiscovered'),0.30,text_width,known and G.C.GREEN or G.C.UI.TEXT_INACTIVE)
        if def then
            local extra=copy_table(def.initial_state or {progress=0});extra.stage=i
            details={require('portrait_tooltips').preview(G.P_CENTERS['j_upg_'..id],extra,true),
                line(known and (es() and 'Descubierto' or 'Discovered') or (es() and 'Por descubrir' or 'Undiscovered'),0.28,text_width)}
        else
            data.width=text_width-0.35
            data.secondary[#data.secondary+1]=label
            data.secondary[#data.secondary+1]=known and (es() and 'Descubierto' or 'Discovered') or
                (es() and 'Por descubrir' or 'Undiscovered')
            details={require('portrait_tooltips').embedded(PortraitRunGallery.tooltip(data))}
        end
        if i>1 then stages[#stages+1]={n=G.UIT.R,config={align='cm',padding=0.05},nodes={
            {n=G.UIT.T,config={text='v',scale=0.28,colour=G.C.GOLD}}}} end
        stages[#stages+1]={n=G.UIT.R,config={align='cm',padding=0.10,r=0.1,colour=G.C.BLACK},nodes={
            {n=G.UIT.C,config={align='cm',minw=1.85,padding=0.05},nodes={art}},
            {n=G.UIT.C,config={align='cl',minw=text_width,maxw=text_width},nodes=details}}}
    end
    local Scroll=require('portrait_run_scroll')
    local view=Scroll(stages,width-0.3,math.min(11.5,G.ROOM.T.h*0.56))
    -- Short families fit their content; long families retain the shared scroll.
    view.T.h=math.min(view.T.h,view.content.T.h);view.VT.h=view.T.h
    local nodes={line(title,0.45,width-0.4,G.C.GOLD),
        line(table.concat(sequence,' > '),0.32,width-0.4),
        {n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.O,config={id='pc_family_view',object=view}}}},
        UIBox_button{label={es() and 'Cerrar' or 'Close'},button='pc_category_info_close',minw=3,
            minh=portrait_touch_height(0.85),scale=0.4,colour=G.C.RED}}
    require('portrait_collection_info').show(nodes,width)
end
return F
