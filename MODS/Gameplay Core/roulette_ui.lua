-- Native Card previews, native buttons and a rotating pixel-art disk. Geometry
-- and winning angle use exactly the same eight equal sectors as the RNG.
return function(R,P)
    local tau,step=math.pi*2,math.pi/4
    local function detach(node,object)
        if node.config and node.config.object==object then node.config.object=nil end
        for _,child in pairs(node.children or {}) do detach(child,object) end
    end
    function R.clear()
        if G.booster_pack and G.booster_pack.pg_roulette then
            detach(G.booster_pack.UIRoot,G.pg_roulette_area)
            G.booster_pack:remove();G.booster_pack=nil
        end
        if G.pg_roulette_area then G.pg_roulette_area:remove();G.pg_roulette_area=nil end
        R.cards={};R.feature=nil
    end
    local function preview(saved,scale)
        local c=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.j_joker)
        c:load(copy_table(saved));c.T.w=G.CARD_W*scale;c.T.h=G.CARD_H*scale
        c.pg_roulette_preview=true;c.states.drag.can=false;c.states.collide.can=true
        c.portrait_dimensions=nil;return c
    end
    function R.restore_cards()
        R.clear()
        local size=7.8
        if G.F_PORTRAIT then
            local layout=portrait_run_layout()
            local top=PORTRAIT_CONFIG.layout.top_margin+layout.inventory_h+PORTRAIT_CONFIG.pack.top_gap
            size=math.min(size,math.max(5.8,layout.hud_y-top-4.3))
        end
        local area=CardArea(0,0,size,size+0.25,{type='title_2',card_limit=9,highlighted_limit=0})
        G.pg_roulette_area=area
        area.align_cards=function(self)
            for i,c in ipairs(R.cards) do
                local angle=(i-1)*step-math.pi/2+(R.angle or 0)
                c.T.x=self.T.x+self.T.w/2+math.cos(angle)*size*0.3244-c.T.w/2
                c.T.y=self.T.y+size/2+0.22+math.sin(angle)*size*0.3244-c.T.h/2
                c.T.r=0;c:hard_set_T()
                c.states.hover.can=not R.animation
            end
            if R.feature then
                local c=R.feature
                c.T.x=self.T.x+self.T.w/2-c.T.w/2;c.T.y=self.T.y+size/2+0.22-c.T.h/2
                c:hard_set_T()
            end
        end
        local draw=area.draw
        area.draw=function(self)
            local s=R.state();if not s then return end
            love.graphics.push('all')
            love.graphics.scale(G.TILESCALE*G.TILESIZE)
            local x,y=self.VT.x+self.T.w/2,self.VT.y+size/2+0.22
            local atlas=G.ASSET_ATLAS.pg_roulette_wheel
            local w,h=atlas.image:getDimensions()
            love.graphics.setColor(0,0,0,0.3)
            love.graphics.circle('fill',x,y+0.12,size/2-0.1,64)
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(atlas.image,x,y,(R.angle or 0)-math.pi/8,(size-0.08)/w,(size-0.08)/h,w/2,h/2)
            if s.phase=='result' and not R.animation then
                love.graphics.setColor(1,0.87,0.44,0.24)
                love.graphics.arc('fill','pie',x,y,size*0.433,-math.pi/2-step/2,-math.pi/2+step/2,12)
            end
            -- The pointer is fixed: the physical winning sector ends here.
            love.graphics.setColor(0.05,0.07,0.12,1)
            love.graphics.polygon('fill',x-0.26,self.VT.y+0.05,x+0.26,self.VT.y+0.05,x,self.VT.y+0.64)
            love.graphics.setColor(G.C.GOLD)
            love.graphics.polygon('fill',x-0.19,self.VT.y+0.1,x+0.19,self.VT.y+0.1,x,self.VT.y+0.53)
            if R.reveal_time and not G.SETTINGS.reduced_motion then
                local t=(G.TIMERS.REAL-R.reveal_time)/0.65
                if t>=0 and t<1 then
                    for i=1,12 do
                        local a=i*tau/12;local r=0.45+1.25*t
                        love.graphics.setColor(i%2==0 and G.C.GOLD or G.C.WHITE)
                        local z=0.085*(1-t)
                        love.graphics.rectangle('fill',x+math.cos(a)*r-z,y+math.sin(a)*r-z,z*2,z*2)
                    end
                end
            end
            love.graphics.pop()
            draw(self)
        end
        for i,saved in ipairs(R.state().prizes) do
            local c=preview(saved,0.64*size/8.2);R.cards[i]=c;area:emplace(c)
        end
        area:align_cards()
    end
    local function button(label,callback,condition,colour,width,height,scale)
        return UIBox_button{label={label},button=callback,func=condition,colour=colour or G.C.RED,
            minw=width or 2.75,minh=height or portrait_touch_height(0.7),scale=scale or 0.32,one_press=false}
    end
    function R.show()
        if G.booster_pack and G.booster_pack.pg_roulette then
            detach(G.booster_pack.UIRoot,G.pg_roulette_area)
            G.booster_pack:remove();G.booster_pack=nil
        end
        local s=R.state();local result=s.phase=='result' and not R.animation
        if R.feature then G.pg_roulette_area:remove_card(R.feature);R.feature:remove();R.feature=nil end
        if result then
            R.feature=preview(s.prizes[s.winner],0.96);G.pg_roulette_area:emplace(R.feature)
            if R.reveal_time then R.feature:juice_up(0.35,0.2) end
        end
        local nodes={P.text(R.tr('RULETA PREMIUM','PREMIUM ROULETTE'),0.43),
            P.text(R.tr('8 premios · 12,5% cada uno','8 prizes · 12.5% each'),0.27),
            {n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.O,config={object=G.pg_roulette_area}}}}}
        local footer={}
        if result then
            local c=R.cards[s.winner]
            footer[#footer+1]=P.text(localize{type='name_text',set=c.ability.set,key=c.config.center.key},0.34)
            footer[#footer+1]={n=G.UIT.R,config={align='cm',padding=0.04},nodes={
                {n=G.UIT.C,config={align='cm'},nodes={button(R.tr('Aceptar','Accept'),'pg_roulette_accept','pg_roulette_can_accept',G.C.GREEN)}},
                {n=G.UIT.C,config={align='cm'},nodes={button('Reroll $10','pg_roulette_reroll','pg_roulette_can_reroll')}}}}
            footer[#footer+1]=P.text(R.tr('Sin espacio: vende arriba o renuncia.','No room: sell above or give up.'),0.23)
            footer[#footer+1]=button(R.tr('Renunciar al premio','Give up prize'),'pg_roulette_discard',nil,G.C.UI.BACKGROUND_INACTIVE,3.3,0.5,0.25)
        else
            footer[#footer+1]=button(R.animation and R.tr('Girando...','Spinning...') or R.tr('Girar','Spin'),
                'pg_roulette_spin','pg_roulette_can_spin',G.C.GOLD,5.5)
            footer[#footer+1]=P.text(R.tr('Toca las cartas para ver sus efectos.','Touch the cards to inspect their effects.'),0.25)
        end
        nodes[#nodes+1]={n=G.UIT.R,config={align='tm',minh=2.5},nodes={
            {n=G.UIT.C,config={align='cm'},nodes=footer}}}
        G.booster_pack=UIBox{definition=P.panel(nodes),config={align='tmi',major=G.hand,bond='Weak',offset={x=0,y=-2.2}}}
        G.booster_pack.pg_roulette=true
        if G.F_PORTRAIT then portrait_anchor_run_panel(G.booster_pack,true) end
    end
end
