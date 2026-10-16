-- Shared presentation only. Native localization, card UI, badges and info queues
-- remain responsible for card semantics; these helpers only arrange their nodes.
local T={}
local function es() return (G.SETTINGS.language or ''):sub(1,2)=='es' end
-- Only presentation nodes belong in nodes arrays. AUT.badges is deliberately
-- untouched: native/SMODS own its string keys and turn them into create_badge nodes.
function T.valid_node(node)
    if type(node)~='table' or type(node.config)~='table' then return false,'node/config must be tables' end
    local known=false
    for _,kind in pairs(G.UIT) do if node.n==kind then known=true;break end end
    if not known then return false,'unknown node type '..tostring(node.n) end
    if node.n==G.UIT.O and not (node.config.object and node.config.object.T) then return false,'object has no transform' end
    if node.nodes~=nil then
        if type(node.nodes)~='table' then return false,'children must be a table' end
        local last=0
        for key in pairs(node.nodes) do
            if type(key)=='number' then
                if key<1 or key%1~=0 then return false,'invalid child index' end
                last=math.max(last,key)
            end
        end
        for i=1,last do
            local valid,reason=T.valid_node(node.nodes[i])
            if not valid then return false,'child '..i..': '..reason end
        end
    end
    return true
end
function T.append_node(nodes,node)
    if node==nil then return false end -- Optional secondary text/footer.
    if not T.valid_node(node) then
        sendWarnMessage('Rejected malformed custom tooltip node','Portrait Tooltips')
        return false
    end
    nodes[#nodes+1]=node
    return true
end
function T.embedded(definition)
    -- A ROOT resets its coordinates to (0,0) during UIBox layout. Embedded
    -- popups must flow as rows, while standalone hover UIBoxes keep their ROOT.
    if definition.n==G.UIT.ROOT then definition.n=G.UIT.R end
    for _,child in ipairs(definition.nodes or {}) do T.embedded(child) end
    return definition
end
function T.width(width) return math.min(width or 5.6,G.ROOM.T.w-0.8) end
function T.wrap(lines,width,scale)
    local font=G.LANG.font
    local out={}
    for _,text in ipairs(lines or {}) do
        for paragraph in (tostring(text)..'\n'):gmatch('(.-)\n') do
            local line=''
            for word in paragraph:gmatch('%S+') do
                local candidate=line=='' and word or line..' '..word
                if line~='' and font.FONT:getWidth(candidate)*(font.squish or 1)*scale*font.FONTSCALE/G.TILESIZE>width then
                    out[#out+1]=line;line=word
                else line=candidate end
            end
            if line~='' then out[#out+1]=line end
        end
    end
    return out
end
function T.rows(info,width,scale,ink)
    local rows={};scale=scale or 0.34
    if info.loc then
        local args=copy_table(info.loc)
        args.type='descriptions';args.nodes=rows
        localize(args) -- Keep native colour spans, symbols and X Mult capsules.
        local wrapped={}
        local font=G.LANG.font
        local function measure(node)
            local c=node.config
            if node.n==G.UIT.T then
                return font.FONT:getWidth(c.text)*(font.squish or 1)*c.scale*font.FONTSCALE/G.TILESIZE
            end
            if node.n==G.UIT.O then return c.object.T.w end
            local w=2*(c.padding or 0)
            for _,child in ipairs(node.nodes or {}) do w=w+measure(child) end
            return w
        end
        for _,row in ipairs(rows) do
            local line,used={},0
            local function add(node)
                local w=measure(node)
                if #line>0 and used+w>width then wrapped[#wrapped+1]=line;line={};used=0 end
                line[#line+1]=node;used=used+w
            end
            for _,node in ipairs(row) do
                if node.n==G.UIT.T then
                    for word in node.config.text:gmatch('%s*%S+%s*') do
                        local config={}
                        for k,v in pairs(node.config) do config[k]=v end
                        config.text=word
                        if config.colour==G.C.UI.TEXT_DARK and word:find('%d') then
                            config.colour=word:find('%$') and G.C.MONEY or G.C.ORANGE
                        end
                        add({n=G.UIT.T,config=config})
                    end
                else add(node) end
            end
            if #line>0 then wrapped[#wrapped+1]=line end
        end
        return wrapped
    end
    for _,line in ipairs(T.wrap(info.text,width,scale)) do
        local nodes={}
        for word,space in line:gmatch('(%S+)(%s*)') do
            local colour=ink or G.C.UI.TEXT_DARK
            if word:find('%d') then
                colour=word:find('%$') and G.C.MONEY or G.C.ORANGE
                if line:find('Mult') then colour=G.C.MULT
                elseif line:find('Chips') or line:find('fichas') then colour=G.C.CHIPS end
            end
            nodes[#nodes+1]={n=G.UIT.T,config={text=word..space,scale=scale,colour=colour}}
        end
        rows[#rows+1]=nodes
    end
    return rows
end
function T.body(rows,width)
    local body=desc_from_rows(rows,false,T.width(width)-0.18)
    body.config.padding=0.08
    for _,line in ipairs(body.nodes[1].nodes) do line.config.padding=0.02 end
    return body
end
function T.secondary(lines,width)
    local nodes={}
    for _,row in ipairs(T.rows({text=lines},T.width(width)-0.1,0.28,G.C.UI.TEXT_LIGHT)) do
        nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.02,maxw=T.width(width)-0.1},nodes=row}
    end
    if #nodes>0 then return {n=G.UIT.R,config={align='cm',padding=0.06},nodes=nodes} end
end
function T.sections(sections,width)
    local rows={}
    for i,section in ipairs(sections) do
        if i>1 then rows[#rows+1]={{n=G.UIT.B,config={w=0,h=0.08}}} end
        rows[#rows+1]={{n=G.UIT.T,config={text=section.title,scale=0.30,colour=section.colour or G.C.UI.TEXT_DARK}}}
        for _,row in ipairs(T.rows(section,T.width(width)-0.3)) do rows[#rows+1]=row end
    end
    return rows
end
function T.class_style(class)
    if class=='Mutation' then return es() and 'MUTACIÓN' or 'MUTATION',darken(HEX('A5BDB9'),0.45) end
    if class=='Contraband' then return localize('k_evt_contraband'),HEX('65233d') end
    if class=='Contract' then
        local c=PortraitGameplay and PortraitGameplay.modules.contracts
        return es() and 'CONTRATO' or 'CONTRACT',c and c.mod.badge_colour or G.C.GREY
    end
    if class=='UPG' then return 'UPGRADED',HEX(PortraitQOL.rarity_colours.UPG) end
    if class=='Double' then return es() and 'DOBLE' or 'DOUBLE',HEX('8198C0') end
    return class,G.C.SET[class] or G.C.GREY
end
function T.badge(info)
    local label,colour=T.class_style(info.class)
    local nodes={}
    if T.append_node(nodes,create_badge(info.class_label or label,info.class_colour or colour,G.C.WHITE,1)) then
        return {n=G.UIT.R,config={align='cm',padding=0.03},nodes=nodes}
    end
end
function T.item(info)
    local width=T.width(info.width);local title={}
    for _,line in ipairs(T.wrap({info.title or ''},width,0.43)) do
        title[#title+1]={n=G.UIT.R,config={align='cm',maxw=width},nodes={
            {n=G.UIT.T,config={text=line,scale=0.43,colour=G.C.WHITE,shadow=true}}}}
    end
    local contents={}
    if #title>0 then contents[#contents+1]=name_from_rows(title) end
    contents[#contents+1]=T.body(info.sections and T.sections(info.sections,width) or T.rows(info,width-0.18),width)
    T.append_node(contents,T.secondary(info.secondary,width))
    T.append_node(contents,T.badge(info))
    return {n=G.UIT.ROOT,config={id='pg_item_tooltip',align='cm',colour=G.C.CLEAR},nodes={
        {n=G.UIT.R,config={align='cm',padding=0.05,r=0.12,colour=lighten(G.C.JOKER_GREY,0.5),emboss=0.07},nodes={
            {n=G.UIT.R,config={align='cm',padding=0.07,r=0.1,colour=adjust_alpha(darken(G.C.BLACK,0.1),0.8)},nodes=contents}}}}}
end
function T.modes(card,sections)
    if card.debuff then return end
    local owned=G.STAGE==G.STAGES.RUN and G.jokers and card.area==G.jokers
    for i,section in ipairs(sections) do
        if owned and (card.ability.extra.selected or 'A')==(i==1 and 'A' or 'B') then
            section.title=section.title..'  ·  '..(es() and 'ACTIVO' or 'ACTIVE')
        end
    end
    local rows={}
    for _,row in ipairs(T.sections(sections)) do
        rows[#rows+1]={n=G.UIT.R,config={align='cm',padding=0.02,maxw=T.width()-0.3},nodes=row}
    end
    return {{n=G.UIT.C,config={align='cm'},nodes=rows}}
end
function T.native_class(card)
    local center=card.config.center
    if not center then return end
    if card.ability_UIBox_table.card_type=='Locked' or card.ability_UIBox_table.card_type=='Undiscovered' then return end
    return center.upg_id and 'UPG' or center.portrait_family=='doubles' and 'Double' or center.set=='Contraband' and 'Contraband'
end
function T.native_body(card)
    local class=T.native_class(card)
    if not class then return desc_from_rows(card.ability_UIBox_table.main) end
    local body=T.body(card.ability_UIBox_table.main)
    if class=='Double' then
        -- Keep custom furniture inside our body. Adding a sibling after the
        -- native badges row breaks SMODS' multi-box return-value patch anchor.
        local nodes={body};T.append_node(nodes,T.native_footer(card))
        return {n=G.UIT.R,config={align='cm',main_box_flag=body.config.main_box_flag},nodes=nodes}
    end
    if class~='UPG' or card.debuff then return body end
    local def=UPGJokers.registry.entries[card.config.center.upg_id]
    local stage=card.ability.extra.stage or 1
    local following=def.stages[stage+1]
    local secondary={(es() and 'Evolución: ' or 'Evolution: ')..stage..' / '..#def.stages,
        following and ((es() and 'Siguiente: ' or 'Next: ')..localize{type='name_text',set='Joker',key=following.loc_key}) or
        (es() and 'Forma final' or 'Final form')}
    if card.area and card.area.config.collection then
        secondary[#secondary+1]=es() and 'Toca para ver las evoluciones.' or 'Tap to view evolutions.'
    end
    return {n=G.UIT.R,config={align='cm',main_box_flag=body.config.main_box_flag},nodes={body,T.secondary(secondary)}}
end
function T.native_footer(card)
    -- UPG and Contraband already have their native rarity/set badge. Keeping it
    -- preserves SMODS' rarity and edition ordering without duplicating labels.
    if T.native_class(card)=='Double' then return T.badge{class='Double'} end
end
function T.preview_card(center,extra,stage_preview,anchor)
    -- create_fake_card supplies localization data, NOT a drawable Card. The
    -- SMODS multi_box_descriptions popup also requires card.T.x to place info
    -- columns. Give every embedded preview its own presentation geometry before
    -- calling the native popup; do not spawn a Card, sprites, RNG or discovery.
    local factory=center.create_fake_card or
        (center.consumeable and SMODS.Consumable.create_fake_card) or SMODS.Center.create_fake_card
    local card=factory(center)
    card.config={center=center};card.ability.name=center.name;card.ability.set=center.set
    card.base={};card.bypass_discovery_center=true
    local position=anchor and anchor.T or {x=G.ROOM.T.x+G.ROOM.T.w/2-G.CARD_W/2,
        y=G.ROOM.T.y+G.ROOM.T.h/2-G.CARD_H/2,w=G.CARD_W,h=G.CARD_H,r=0,scale=1}
    card.T=copy_table(position);card.VT=copy_table(position)
    if extra then card.ability.extra=copy_table(extra) end
    if stage_preview then card.fake_card=false end
    return card
end
function T.preview(center,extra,stage_preview,anchor)
    local card=T.preview_card(center,extra,stage_preview,anchor)
    card.ability_UIBox_table=generate_card_ui(center,nil,nil,center.set,{card_type=true},nil,nil,nil,card)
    return T.embedded(G.UIDEF.card_h_popup(card))
end
return T
