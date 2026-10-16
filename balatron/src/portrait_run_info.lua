-- Run Info geometry only. All tab creators, objects and callbacks stay native.
local R={}
function R.metrics(count)
    local v=require('portrait_popup_layout').viewport()
    -- Generic options: backdrop .1, outline .07, body .2, contents .08.
    local chrome=2*(.1+.07+.2+.08)
    local width=v.w-chrome
    local rows=math.ceil((count or 4)/4)
    local tab_h=math.max(portrait_touch_height(.8),1.05)
    return {width=width,tab_h=tab_h,content=width-.12,
        height=math.max(1,v.h-(2*(.1+.07+.2)+.24+rows*(tab_h+.08)+portrait_touch_height(.8)+.4))}
end
function R.lines(text,width,scale)
    local font=G.LANG.font
    local function size(s) return font.FONT:getWidth(s)*font.squish*scale*font.FONTSCALE/G.TILESIZE end
    local lines,line={},''
    for word in tostring(text):gmatch('%S+') do
        if line~='' and size(line..' '..word)>width then lines[#lines+1]=line;line='' end
        line=line=='' and word or line..' '..word
    end
    if line~='' then lines[#lines+1]=line end
    return lines
end
local function wrap_label(node,width)
    local text=node.nodes and node.nodes[1]
    if not text or text.n~=G.UIT.T then return end
    node.config.minw=width;node.config.maxw=width;node.config.padding=0
    node.nodes={}
    for _,line in ipairs(R.lines(text.config.text,width,text.config.scale)) do
        local c={};for k,v in pairs(text.config) do c[k]=v end;c.text=line
        node.nodes[#node.nodes+1]={n=G.UIT.R,config={align='cm',padding=0,maxw=width},
            nodes={{n=G.UIT.T,config=c}}}
    end
end
local function hands(node,width)
    local c=node.config or {}
    local tip=c.on_demand_tooltip
    if tip and tip.filler and tip.filler.func==create_UIBox_hand_tip and #node.nodes>=4 then
        local heading,score,hash,uses=unpack(node.nodes)
        c.minw=width;c.padding=.04
        heading.n=G.UIT.R;heading.config.minw=0
        -- Reflow instead of shrinking the whole hand (including its hit area).
        wrap_label(heading.nodes[2],width-1.7)
        score.nodes[1].config.maxw=1.25
        score.nodes[3].config.maxw=1.25
        node.nodes={heading,{n=G.UIT.R,config={align='cm',padding=.04},nodes={score,hash,uses}}}
        return
    end
    for _,child in ipairs(node.nodes or {}) do hands(child,width) end
end
function R.prepare(args)
    if not G.F_PORTRAIT then return end
    local parent=args.config and args.config.parent
    local paged=parent and parent.config and parent.config.id=='hand_list'
        and G.OVERLAY_MENU and G.OVERLAY_MENU.definition.config.portrait_run_info
    if R.active_kind==1 or paged then hands(args.definition,(R.active or R.metrics()).content-.3) end
end
local function vouchers(node,width)
    for _,child in ipairs(node.nodes or {}) do vouchers(child,width) end
    local children=node.nodes or {}
    local first=children[1]
    if not (first and first.n==G.UIT.C and first.nodes and first.nodes[1]
        and first.nodes[1].config.object and getmetatable(first.nodes[1].config.object)==CardArea) then return end
    local rows,cells,used={},{},0
    for _,cell in ipairs(children) do
        local area=cell.nodes[1].config.object
        local w=area.T.w
        for _,card in ipairs(area.cards) do area.T.h=math.max(area.T.h,card.T.h+.15) end
        if #cells>0 and used+w>width then
            rows[#rows+1]={n=G.UIT.R,config={align='cm',padding=0},nodes=cells};cells={};used=0
        end
        cells[#cells+1]=cell;used=used+w
    end
    if #cells>0 then rows[#rows+1]={n=G.UIT.R,config={align='cm',padding=0},nodes=cells} end
    node.nodes=rows
end
function R.content(def,kind,m)
    if kind==1 then hands(def,m.content-.3)
    elseif kind==2 then
        -- Three desktop columns become full-width rows; vertical scrolling is
        -- owned by tab_contents, leaving tabs and Back permanently visible.
        for _,node in ipairs(def.nodes or {}) do node.n=G.UIT.R end
    elseif kind==3 then vouchers(def,m.content-.5) end
    def.config.portrait_run_content={width=m.content,height=m.height}
    def.config.minw=m.content
    return def
end
function R.tabs(args)
    local m=R.metrics(#args.tabs)
    args.no_shoulders=true;args.padding=.06;args.tab_w=m.width
    args.tab_h=m.height+.12;args.button_padding=.04
    args.button_width=(m.width-(math.min(4,#args.tabs)+1+(#args.tabs>4 and 2 or 0))*args.button_padding)/math.min(4,#args.tabs)
    args.button_height=m.tab_h
    for i,tab in ipairs(args.tabs) do
        local creator=tab.tab_definition_function
        tab.tab_definition_function=function(...)
            R.active=m;R.active_kind=i
            local def=creator(...)
            R.active=nil;R.active_kind=nil
            return R.content(def,i,m)
        end
    end
end
return R
