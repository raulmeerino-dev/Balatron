-- The Steamodded collection replaces the vanilla builder entirely. Adapt the
-- loaded registry here, after injection, using its atlas and popup functions.
local B={page=1}
local function text(s,scale)
    return {n=G.UIT.R,config={align='cm',padding=0.04},nodes={
        {n=G.UIT.O,config={object=DynaText{string={s},colours={G.C.WHITE},scale=scale or 0.34,maxw=7.5,silent=true}}}}}
end
function B.definition(exit)
    B.back=exit or (G.ACTIVE_MOD_UI and 'openModUI_'..G.ACTIVE_MOD_UI.id) or 'your_collection'
    local pool=SMODS.collection_pool(G.P_BLINDS)
    local pages=math.max(1,math.ceil(#pool/16));B.page=math.min(B.page,pages)
    local nodes={text(localize('b_blinds'),0.46)}
    for row=1,4 do
        local cells={}
        for col=1,4 do
            local v=pool[(B.page-1)*16+(row-1)*4+col]
            if v then
                local sprite=SMODS.create_sprite(0,0,1.4,1.4,v.discovered and (v.atlas or 'blind_chips') or 'blind_chips',v.discovered and v.pos or G.b_undiscovered.pos)
                sprite:define_draw_steps{{shader='dissolve',shadow_height=0.05},{shader='dissolve'}}
                sprite.states.drag.can=false;sprite.states.hover.can=false;sprite.states.collide.can=false
                local name=v.discovered and localize{type='name_text',set='Blind',key=v.key} or localize('k_unknown')
                cells[#cells+1]={n=G.UIT.C,config={align='cm',minw=1.9,maxw=1.9,minh=2.05,padding=0.05,
                    colour=G.C.BLACK,r=0.12,button='portrait_blind_inspect',ref_table=v,hover=true},nodes={
                    {n=G.UIT.R,config={align='cm',minh=1.5},nodes={{n=G.UIT.O,config={object=sprite}}}},
                    {n=G.UIT.R,config={align='cm',minh=0.4},nodes={{n=G.UIT.O,config={object=DynaText{
                        string={name},colours={G.C.WHITE},scale=0.3,maxw=1.75,silent=true}}}}},
                }}
            end
        end
        if #cells>0 then nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.07},nodes=cells} end
    end
    if pages>1 then
        local options={};for i=1,pages do options[i]=i..' / '..pages end
        nodes[#nodes+1]=create_option_cycle{options=options,current_option=B.page,opt_callback='portrait_blind_page',w=6,h=0.8}
    end
    nodes[#nodes+1]=UIBox_button{label={localize('k_ante_cap')..' / '..localize('k_base_cap')},button='portrait_blind_antes',minw=5,minh=0.8,scale=0.35}
    return create_UIBox_generic_options{back_func=B.back,contents={{n=G.UIT.C,config={align='cm',padding=0.12},nodes=nodes}}}
end
function B.install()
    local original=create_UIBox_your_collection_blinds
    function create_UIBox_your_collection_blinds(exit)
        if not G.F_PORTRAIT then return original(exit) end
        return B.definition(exit)
    end
    G.FUNCS.portrait_blind_page=function(args)
        B.page=args.to_key
        G.FUNCS.overlay_menu{definition=B.definition(B.back)}
    end
    G.FUNCS.portrait_blind_back=function() G.FUNCS.overlay_menu{definition=B.definition(B.back)} end
    G.FUNCS.portrait_blind_inspect=function(e)
        local v=e.config.ref_table
        if v.discovered then v.alerted=true;G:save_progress() end
        G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{back_func='portrait_blind_back',contents={
            create_UIBox_blind_popup(v,v.discovered)}}}
    end
    G.FUNCS.portrait_blind_antes=function()
        local nodes={text(localize('k_ante_cap')..' / '..localize('k_base_cap'),0.44)}
        for i=1,16 do nodes[#nodes+1]=text(i..'   '..number_format(get_blind_amount(i)),0.35) end
        G.FUNCS.overlay_menu{definition=create_UIBox_generic_options{back_func='portrait_blind_back',contents={
            {n=G.UIT.C,config={align='cm',padding=0.08},nodes=nodes}}}}
    end
end
return B
