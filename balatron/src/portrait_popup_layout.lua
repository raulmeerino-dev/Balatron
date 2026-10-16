-- One measured layout for native/SMODS popups and informational overlays.
-- Presentation only: never change localization, card state, pools or RNG.
local L={}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function L.viewport(config,container)
    local room=G.ROOM.T;local unit=G.TILESCALE*G.TILESIZE
    local origin=(container and container.T) or room
    local mx=math.max((config and config.screen_padding) or PORTRAIT_CONFIG.tooltip_screen_padding or .12,
        (PORTRAIT_CONFIG.tooltip_safe_margin_points or 8)/unit)
    local my=mx
    local sx,sy,sw,sh=0,0,love.graphics.getWidth(),love.graphics.getHeight()
    if love.window.getSafeArea then
        local ok,x,y,w,h=pcall(love.window.getSafeArea)
        if ok and type(w)=='number' and type(h)=='number' and w>0 and h>0 then
            sx,sy,sw,sh=x,y,w,h
        end
    end
    local left=sx/unit-room.x+mx
    local top=sy/unit-room.y+my
    local right=(sx+sw)/unit-room.x-mx
    local bottom=(sy+sh)/unit-room.y-my
    local dx,dy=room.x-origin.x,room.y-origin.y
    return {x=left+dx,y=top+dy,w=math.max(.5,right-left),h=math.max(.5,bottom-top),margin=mx}
end
-- Keep definitions, callbacks and embedded objects exactly as the creator made
-- them. Balatro owns node construction, measurement and alignment.
function L.prepare(args)
    if not G.F_PORTRAIT or not args.definition or not args.config then return end
    local c=args.config
    local content=args.definition.config and args.definition.config.portrait_run_content
    if content then
        c.portrait_layout=true;c.portrait_content=content
    end
    local panel=c.portrait_panel or (args.definition.config or {}).portrait_panel
    if not (c.portrait_layout or c.instance_type=='POPUP' or c.fit_to_room or panel) then return end
    c.portrait_layout=true;c.portrait_panel=panel
    c.r_bond='Weak';c.scale_bond='Weak'
    if panel then
        c.xy_bond='Weak'
        c.portrait_backdrop=args.definition.config.colour
    end
    L.install_input()
end
local function offset_tree(node,dx,dy)
    if node.REMOVED or node.pointer_removing then return end
    node.FRAME.MAJOR=nil
    node.role.offset.x=node.role.offset.x+dx
    node.role.offset.y=node.role.offset.y+dy
    for _,child in ipairs(node.children or {}) do
        if child.UIBox==node.UIBox then offset_tree(child,dx,dy) end
    end
end
function L.begin_measure(box)
    if not (G.F_PORTRAIT and box.config.portrait_layout) then return end
    box.portrait_calculating=true
end
local function view_size(box,v)
    if box.config.portrait_content then
        v={w=box.config.portrait_content.width,h=box.config.portrait_content.height}
    end
    box.portrait_view_w=v.w;box.portrait_view_h=v.h
    box.T.w=math.min(box.portrait_full_width,v.w)
    box.T.h=math.min(box.portrait_full_height,v.h)
    box.portrait_scroll_limit=math.max(0,box.portrait_full_height-box.T.h)
    box.portrait_scroll_limit_x=math.max(0,box.portrait_full_width-box.T.w)
    box.portrait_scroll=clamp(box.portrait_scroll or 0,0,box.portrait_scroll_limit)
    box.portrait_scroll_x=clamp(box.portrait_scroll_x or 0,0,box.portrait_scroll_limit_x)
end
function L.end_measure(box)
    box.portrait_calculating=nil
    if not (G.F_PORTRAIT and box.config.portrait_layout) or box.config.portrait_embedded then return end
    local root=box.UIRoot
    if box.config.portrait_content and root.config.id=='pg_gallery' then
        local host=box:get_UIE_by_ID('pg_run_scroll')
        local view=host and host.config.object
        if view and view.content then
            -- Extensions append rows below the gallery. Reserve their measured
            -- height before sizing its scroll view, avoiding two nested scrolls.
            local height=math.max(.5,box.config.portrait_content.height-(root.T.h-view.T.h))
            if math.abs(view.T.h-height)>.001 then
                view.T.h=height;view.VT.h=height
                view.limit=math.max(0,view.content.T.h-height)
                view.offset=math.min(view.offset,view.limit)
                view.content.alignment.offset.y=-view.offset
                box:calculate_xywh(root,box.T,true)
                root:set_wh();root:set_alignments()
            end
        end
    end
    local x,y,w,h=0,0,root.T.w,root.T.h
    -- Generic overlays have a room-sized backdrop (minw/minh = room * 5).
    -- Measure their already aligned contents, excluding only that backdrop.
    if box.config.portrait_panel and #root.children>0 then
        local left,top,right,bottom
        for _,child in ipairs(root.children) do
            if child.UIBox==box and not child.REMOVED and child.T.w>0 and child.T.h>0 then
                local ox,oy=child.role.offset.x,child.role.offset.y
                left=math.min(left or ox,ox);top=math.min(top or oy,oy)
                right=math.max(right or 0,ox+child.T.w);bottom=math.max(bottom or 0,oy+child.T.h)
            end
        end
        if left then
            local pad=root.config.padding or 0
            x,y=left-pad,top-pad;w,h=right-left+2*pad,bottom-top+2*pad
        end
    end
    box.portrait_full_width=w;box.portrait_full_height=h
    box.portrait_scroll_applied=0;box.portrait_scroll_applied_x=0
    -- Every native measure has rebuilt absolute offsets from scratch.
    offset_tree(root,-x,-y)
    view_size(box,L.viewport(box.config,box.container))
    L.apply_scroll(box)
end
function L.apply_scroll(box)
    local dx=(box.portrait_scroll_applied_x or 0)-(box.portrait_scroll_x or 0)
    local dy=(box.portrait_scroll_applied or 0)-(box.portrait_scroll or 0)
    if dx~=0 or dy~=0 then
        offset_tree(box.UIRoot,dx,dy)
        box.portrait_scroll_applied_x=box.portrait_scroll_x
        box.portrait_scroll_applied=box.portrait_scroll
    end
end
local function origin(o) return o and o.container and o.container.T or G.ROOM.T end
function L.place(box)
    if box.REMOVED or box.pointer_removing or box.portrait_calculating then return true end
    -- Tab contents follow the native parent alignment, not the room centre.
    if box.config.portrait_content then return false end
    if not (box.config.portrait_layout and not box.config.portrait_embedded and box.portrait_full_width) then return false end
    local v=L.viewport(box.config,box.container)
    if box.portrait_view_w~=v.w or box.portrait_view_h~=v.h then
        view_size(box,v)
        L.apply_scroll(box)
    end
    local w,h=box.T.w,box.T.h;local x,y=box.T.x,box.T.y
    if box.config.portrait_panel then x=v.x+(v.w-w)/2;y=v.y+(v.h-h)/2
    elseif box.portrait_pinned then
        local o=origin(box);x=box.portrait_pinned.x-o.x;y=box.portrait_pinned.y-o.y
    else
        local anchor=box.config.parent or (box.role and box.role.major)
        if anchor and anchor.T then
            local a=anchor.T;local ac,bc=origin(anchor),origin(box)
            local ax,ay=a.x+ac.x-bc.x,a.y+ac.y-bc.y
            local gap=box.config.portrait_gap or .16
            local candidates={
                tm={x=ax+(a.w-w)/2,y=ay-h-gap},bm={x=ax+(a.w-w)/2,y=ay+a.h+gap},
                cl={x=ax-w-gap,y=ay+(a.h-h)/2},cr={x=ax+a.w+gap,y=ay+(a.h-h)/2}}
            local preferred=box.alignment.type or 'tm'
            local order={preferred,preferred=='tm' and 'bm' or preferred=='bm' and 'tm' or preferred=='cl' and 'cr' or 'cl','tm','bm','cl','cr'}
            local best,score
            for _,key in ipairs(order) do
                local p=candidates[key]
                if p then
                    local overflow=math.max(v.x-p.x,0)+math.max(p.x+w-v.x-v.w,0)+math.max(v.y-p.y,0)+math.max(p.y+h-v.y-v.h,0)
                    if not score or overflow<score then best=p;score=overflow;box.portrait_side=key end
                    if overflow==0 then break end
                end
            end
            if best then x,y=best.x,best.y end
        end
    end
    x=clamp(x,v.x,v.x+v.w-w);y=clamp(y,v.y,v.y+v.h-h)
    -- Preserve the native opening offset until overlay_menu releases it.
    if box.config.portrait_panel then y=y+(box.alignment.offset.y or 0) end
    if box.role.xy_bond=='Strong' then
        box.VT.x=box.VT.x+x-box.T.x;box.VT.y=box.VT.y+y-box.T.y
    end
    box.T.x=x;box.T.y=y
    return true
end
function L.scroll(box,delta,delta_x)
    if box.REMOVED or box.pointer_removing then return end
    box.portrait_scroll=clamp((box.portrait_scroll or 0)+delta,0,box.portrait_scroll_limit or 0)
    box.portrait_scroll_x=clamp((box.portrait_scroll_x or 0)+(delta_x or 0),0,box.portrait_scroll_limit_x or 0)
    L.apply_scroll(box)
end
function L.removing(box)
    if L.pinned==box then L.pinned=nil end
    if L.gesture and L.gesture.box==box then
        L.gesture={dismiss=true};G.CONTROLLER:cancel_pointer_interaction()
    end
    if box.parent and box.parent.children then
        for key,child in pairs(box.parent.children) do
            if child==box and type(key)~='number' then box.parent.children[key]=nil end
        end
    end
    if L.pinned and L.pinned.portrait_overlay==box then L.pinned:remove() end
end
function L.clip(box)
    if box.REMOVED or box.pointer_removing then return false end
    if not (box.config.portrait_layout and not box.config.portrait_embedded) then return end
    if box.portrait_owner and (box.portrait_owner.REMOVED or box.portrait_overlay~=G.OVERLAY_MENU or box.portrait_state~=G.STATE) then
        box:remove();if L.pinned==box then L.pinned=nil end;return false
    end
    if box.config.portrait_panel and box.config.portrait_backdrop then
        local r=origin(box);local unit=G.TILESCALE*G.TILESIZE
        love.graphics.setColor(box.config.portrait_backdrop)
        love.graphics.rectangle('fill',-r.x*unit,-r.y*unit,love.graphics.getWidth(),love.graphics.getHeight())
    end
    local old={love.graphics.getScissor()}
    local unit=G.TILESCALE*G.TILESIZE
    local v=L.viewport(box.config,box.container)
    local x,y=love.graphics.transformPoint(v.x*unit,v.y*unit)
    local rx,by=love.graphics.transformPoint((v.x+v.w)*unit,(v.y+v.h)*unit)
    -- Child informational boxes have their own safe viewport; do not crop them
    -- to the parent tooltip rectangle. Restore its scissor after drawing.
    if box.config.portrait_side_info then love.graphics.setScissor() end
    love.graphics.intersectScissor(x,y,math.max(0,rx-x),math.max(0,by-y))
    local bx,by0=love.graphics.transformPoint(box.VT.x*unit,box.VT.y*unit)
    local br,bb=love.graphics.transformPoint((box.VT.x+box.T.w)*unit,(box.VT.y+box.T.h)*unit)
    love.graphics.intersectScissor(bx-2,by0-2,math.max(0,br-bx+4),math.max(0,bb-by0+4))
    return old
end
function L.unclip(box,old)
    if not old then return end
    if (box.portrait_scroll_limit or 0)>0 then
        local unit=G.TILESCALE*G.TILESIZE;local h=box.T.h*box.T.h/box.portrait_full_height
        love.graphics.setColor(G.C.UI.TEXT_INACTIVE)
        love.graphics.rectangle('fill',(box.VT.x+box.T.w-.07)*unit,
            (box.VT.y+(box.T.h-h)*box.portrait_scroll/box.portrait_scroll_limit)*unit,.045*unit,h*unit)
    end
    if (box.portrait_scroll_limit_x or 0)>0 then
        local unit=G.TILESCALE*G.TILESIZE;local w=box.T.w*box.T.w/box.portrait_full_width
        love.graphics.setColor(G.C.UI.TEXT_INACTIVE)
        love.graphics.rectangle('fill',(box.VT.x+(box.T.w-w)*box.portrait_scroll_x/box.portrait_scroll_limit_x)*unit,
            (box.VT.y+box.T.h-.07)*unit,w*unit,.045*unit)
    end
    if old[1] then love.graphics.setScissor(unpack(old)) else love.graphics.setScissor() end
end
function L.hit(node,point)
    local box=node.UIBox
    local seen={};local unit=G.TILESCALE*G.TILESIZE
    while box and not seen[box] do
        seen[box]=true
        if box.config.portrait_layout and not box.config.portrait_embedded and
            not L.contains(box,point.x*unit,point.y*unit) then return false end
        local parent=box.parent
        while parent and not parent.UIBox and getmetatable(parent)~=UIBox do
            -- Existing Run/Collection scrolling views are Moveable owners.
            if parent.content==box and not Node.collides_with_point(parent,point) then return false end
            parent=parent.parent
        end
        box=parent and (parent.UIBox or parent)
    end
    return true
end
function L.contains(box,x,y)
    local r=origin(box);local unit=G.TILESCALE*G.TILESIZE
    x=x/unit-r.x;y=y/unit-r.y
    local v=L.viewport(box.config,box.container)
    return x>=math.max(v.x,box.VT.x) and x<=math.min(v.x+v.w,box.VT.x+box.T.w) and
        y>=math.max(v.y,box.VT.y) and y<=math.min(v.y+v.h,box.VT.y+box.T.h)
end
-- Pointer-time lookup only: embedded scroll views and side info retain their
-- own trees, ownership and clipping, including when the outer tooltip is pinned.
function L.scroll_target(node,x,y)
    if not node or node.REMOVED or node.pointer_removing then return end
    for _,child in pairs(node.children or {}) do
        local target=L.scroll_target(child,x,y);if target then return target end
    end
    if node.config and node.config.object then
        local target=L.scroll_target(node.config.object,x,y);if target then return target end
    end
    if node.portrait_full_width and ((node.portrait_scroll_limit or 0)>0 or (node.portrait_scroll_limit_x or 0)>0)
        and (not x or L.contains(node,x,y)) then return node end
end
function L.pin(owner)
    local box=owner.children and owner.children.h_popup
    if not L.scroll_target(box) then return false end
    if L.pinned and L.pinned~=box then L.pinned:remove() end
    owner.children.h_popup=nil;box.parent=nil
    local o=origin(box)
    box.portrait_pinned={x=box.T.x+o.x,y=box.T.y+o.y};box.portrait_owner=owner
    box.portrait_overlay=G.OVERLAY_MENU;box.portrait_state=G.STATE;L.pinned=box
    return true
end
function L.install_input()
    if L.input_installed then return end;L.input_installed=true
    local press,move,release,wheel=love.mousepressed,love.mousemoved,love.mousereleased,love.wheelmoved
    local function active(x,y)
        local box=L.pinned or (type(G.OVERLAY_MENU)=='table' and G.OVERLAY_MENU)
        return L.scroll_target(box,x,y)
    end
    love.mousepressed=function(x,y,button,touch,...)
        if button==1 then
            if L.pinned and L.pinned.REMOVED then L.pinned=nil end
            if L.pinned and not L.contains(L.pinned,x,y) and not L.scroll_target(L.pinned,x,y) then L.pinned:remove();L.pinned=nil;L.gesture={dismiss=true};return end
            local box=active(x,y)
            if box then L.gesture={box=box,x=x,y=y,last=y,last_x=x,pinned=L.pinned~=nil} end
            if L.gesture and L.gesture.pinned then return end
        end
        return press(x,y,button,touch,...)
    end
    love.mousemoved=function(x,y,dx,dy,touch,...)
        local g=L.gesture
        if g and g.box and not g.box.REMOVED then
            if math.abs(y-g.y)>9 or math.abs(x-g.x)>9 then
                if not g.drag then G.CONTROLLER:cancel_pointer_interaction() end
                g.drag=true
            end
            if g.drag then L.scroll(g.box,(g.last-y)/(G.TILESCALE*G.TILESIZE),(g.last_x-x)/(G.TILESCALE*G.TILESIZE));g.last=y;g.last_x=x;return end
            g.last=y;g.last_x=x;if g.pinned then return end
        end
        return move(x,y,dx,dy,touch,...)
    end
    love.mousereleased=function(x,y,button,touch,...)
        if button==1 and L.gesture then
            local g=L.gesture;L.gesture=nil
            if g.drag or g.pinned or g.dismiss then return end
        end
        return release(x,y,button,touch,...)
    end
    love.wheelmoved=function(x,y,...)
        local mx,my=love.mouse.getPosition();local box=active(mx,my)
        if box then L.scroll(box,-y*.8,-x*.8);return end
        if wheel then return wheel(x,y,...) end
    end
end
function L.install_creators()
    if L.creator==G.UIDEF.card_h_popup then return end
    local original=G.UIDEF.card_h_popup
    G.UIDEF.card_h_popup=function(...)
        local first=G.ID or 0
        local result=original(...)
        local kept={}
        local function visit(node)
            if type(node)~='table' then return end
            if node.config then
                if node.config.object then kept[node.config.object]=true end
                if node.config.func=='show_infotip' then visit(node.config.ref_table) end
            end
            for _,child in ipairs(node.nodes or node) do visit(child) end
        end
        visit(result)
        -- A set_badges hook may replace native badge nodes. Dispose of the
        -- discarded labels instead of leaving their DynaText at screen (0,0).
        for i=#G.I.MOVEABLE,1,-1 do
            local object=G.I.MOVEABLE[i]
            if object.ID>=first and getmetatable(object)==DynaText and not object.parent and not kept[object] then object:remove() end
        end
        return result
    end
    L.creator=G.UIDEF.card_h_popup
end
return L
