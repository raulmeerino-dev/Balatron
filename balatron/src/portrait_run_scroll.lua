-- A single clipped, vertically scrollable Run tab. No gameplay state is stored here.
local S=Moveable:extend()
local current,gesture,held_release
local function walk(node,fn)
    fn(node)
    for _,child in pairs(node.children or {}) do walk(child,fn) end
end
function S:init(nodes,width,height)
    Moveable.init(self,0,0,width,height)
    -- Callers construct the view before overlay_menu pauses the game. Its
    -- content must still follow the overlay and scroll while that pause lasts.
    self.created_on_pause=true
    self.states.drag.can=false
    self.offset=0
    self.content=UIBox{definition={n=G.UIT.ROOT,config={align='tm',padding=0.08,colour=G.C.CLEAR},nodes=nodes},
        config={parent=self,align='tmi',offset={x=0,y=0},portrait_layout=G.F_PORTRAIT,
            portrait_embedded=true,portrait_width=width-0.16}}
    self.content.created_on_pause=true
    walk(self.content.UIRoot,function(node)
        node.created_on_pause=true
        if node.config.object then node.config.object.created_on_pause=true end
        node.config.pg_run_view=self
        if node.config.pg_visual_tooltip then node.config.pg_hold_only=true end
    end)
    self.limit=math.max(0,self.content.T.h-height)
end
function S:scroll(delta)
    PortraitRunGallery.dismiss()
    self.offset=math.max(0,math.min(self.limit,self.offset+delta))
    self.content.alignment.offset.y=-self.offset
    self.content:align_to_major()
end
function S:contains(x,y)
    local unit=G.TILESCALE*G.TILESIZE
    return Node.collides_with_point(self,{x=x/unit,y=y/unit})
end
function S:draw()
    current=self;self.overlay=G.OVERLAY_MENU
    local sx,sy,sw,sh=love.graphics.getScissor()
    prep_draw(self,1)
    local x,y=love.graphics.transformPoint(0,0)
    local right,bottom=love.graphics.transformPoint(self.VT.w,self.VT.h)
    love.graphics.pop()
    love.graphics.intersectScissor(x,y,math.max(0,right-x),math.max(0,bottom-y))
    self.content:draw()
    if sx then love.graphics.setScissor(sx,sy,sw,sh) else love.graphics.setScissor() end
    if self.limit>0 then
        prep_draw(self,1)
        local h=self.T.h*self.T.h/(self.limit+self.T.h)
        love.graphics.setColor(G.C.UI.TEXT_INACTIVE)
        love.graphics.rectangle('fill',self.T.w-0.06,(self.T.h-h)*self.offset/self.limit,0.045,h)
        love.graphics.pop()
    end
end
function S:remove()
    if gesture and gesture.view==self then
        if gesture.tile then gesture.tile.config.pg_run_holding=nil end
        gesture=nil;held_release=true
    end
    if current==self then current=nil;PortraitRunGallery.dismiss() end
    self.content:remove()
    Moveable.remove(self)
end
local function active(x,y)
    if require('portrait_popup_layout').pinned then return end
    return current and not current.REMOVED and G.OVERLAY_MENU and current.overlay==G.OVERLAY_MENU
        and (not current.accept_input or current.accept_input())
        and current:contains(x,y) and current
end
function S.install()
    local pressed,moved,released,update,wheel=love.mousepressed,love.mousemoved,love.mousereleased,love.update,love.wheelmoved
    held_release=false
    local function dismiss()
        if gesture and gesture.tile then gesture.tile.config.pg_run_holding=nil end
        PortraitRunGallery.dismiss();gesture=nil
    end
    love.mousepressed=function(x,y,button,touch,...)
        if button==1 then held_release=false end
        local view=button==1 and active(x,y)
        if view then
            gesture={view=view,x=x,y=y,last=y,age=0}
            return
        end
        return pressed(x,y,button,touch,...)
    end
    love.mousemoved=function(x,y,dx,dy,touch,...)
        local g=gesture
        if g then
            if g.view.REMOVED or g.view.overlay~=G.OVERLAY_MENU then dismiss();held_release=true;return end
            if math.abs(y-g.y)>10 or math.abs(x-g.x)>10 then g.drag=true end
            if g.drag then
                if g.tile then g.tile.config.pg_run_holding=nil end
                g.view:scroll((g.last-y)/(G.TILESCALE*G.TILESIZE))
            end
            g.last=y;return
        end
        return moved(x,y,dx,dy,touch,...)
    end
    love.mousereleased=function(x,y,button,touch,...)
        if button==1 and held_release then held_release=false;return end
        if gesture and button==1 then
            local g=gesture
            if g.view.REMOVED or g.view.overlay~=G.OVERLAY_MENU then dismiss();return end
            if g.view.accept_input and (math.abs(y-g.y)>10 or math.abs(x-g.x)>10) then g.drag=true end
            local target
            -- Hold inspects sprites; a tap activates only explicit actions, never category navigation.
            if not g.drag and not g.tile and active(x,y)==g.view then
                local unit=G.TILESCALE*G.TILESIZE
                walk(g.view.content.UIRoot,function(node)
                    if (node.config.button=='ct_claim' or node.config.pg_run_action) and
                        node:collides_with_point({x=x/unit,y=y/unit}) and
                        node:collides_with_point({x=g.x/unit,y=g.y/unit}) then target=node end
                end)
            end
            if g.tile then require('portrait_popup_layout').pin(g.tile) end
            dismiss()
            if target then target:click() end
            return
        end
        return released(x,y,button,touch,...)
    end
    love.update=function(dt,...)
        update(dt,...)
        local g=gesture
        if not g then return end
        if g.view.REMOVED or g.view.overlay~=G.OVERLAY_MENU then dismiss();held_release=true;return end
        g.age=g.age+dt
        -- Optional Settings action: open a persistent modal on hold, then consume
        -- its release. Existing Run/Collection tooltip gestures stay unchanged.
        if g.view.accept_input and not g.drag and not g.tile and g.age>=0.45 then
            local unit=G.TILESCALE*G.TILESIZE;local target
            walk(g.view.content.UIRoot,function(node)
                if not target and node.config.pg_hold_action and node:collides_with_point({x=g.x/unit,y=g.y/unit}) then target=node end
            end)
            if target then
                dismiss();held_release=true
                G.FUNCS[target.config.pg_hold_action](target)
                return
            end
        end
        if not g.drag and not g.tile and g.age>=0.3 then
            local unit=G.TILESCALE*G.TILESIZE
            walk(g.view.content.UIRoot,function(node)
                if not g.tile and node.config.pg_visual_tooltip and node:collides_with_point({x=g.x/unit,y=g.y/unit}) then
                    g.tile=node;node.config.pg_run_holding=true
                    PortraitRunGallery.inspected=node;node:hover()
                end
            end)
        end
    end
    love.wheelmoved=function(x,y,...)
        local mx,my=love.mouse.getPosition()
        local view=active(mx,my)
        if view then dismiss();view:scroll(-y*0.8);return end
        if wheel then return wheel(x,y,...) end
    end
    local collide=UIElement.collides_with_point
    function UIElement:collides_with_point(point)
        local view=self.config.pg_run_view
        if view and not Node.collides_with_point(view,point) then return false end
        return collide(self,point)
    end
end
return S
