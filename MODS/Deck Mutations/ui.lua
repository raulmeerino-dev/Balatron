return function(P,M,order,level,name,vars)
    M.definitions=order -- Collection reads registered entries, never the enabled pool.
    SMODS.Atlas{key='mutations',path='mutations.png',px=64,py=64}
    local separate={}
    for _,id in ipairs({'overload','resonance'}) do SMODS.Atlas{key=id,path=id..'.png',px=64,py=64,
        disable_mipmap=true,inject=function(self)
            SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest')
        end} end
    -- Chain Reaction shares the square Mutation format in every UI/score feedback.
    SMODS.Atlas{key='chain_reaction',path='chain_reaction.png',px=64,py=64,
        disable_mipmap=true,inject=function(self)
            SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest')
        end}
    local icons64={chain_reaction=true,overload=true,resonance=true}
    for _,d in ipairs(order) do if d.icon64 then
        icons64[d.id]=true;SMODS.Atlas{key=d.id,path='run_rules/'..d.id..'.png',px=64,py=64,
            disable_mipmap=d.expansion or nil,inject=d.expansion and function(self)
                SMODS.Atlas.inject(self);self.image:setFilter('nearest','nearest')
            end or nil}
    end end
    local positions={}
    for i,d in ipairs(order) do positions[d.id]={x=(i-1)%4,y=math.floor((i-1)/4)} end
    local function active()
        local ids={}
        if M.state() then for _,d in ipairs(order) do if level(d.id)>0 then ids[#ids+1]=d.id end end end
        return ids
    end
    local function icon(id,size)
        -- Preserve legacy card proportions only for entries still using that format.
        local sprite=Sprite(0,0,separate[id] and size*71/95 or size,size,G.ASSET_ATLAS[(separate[id] or icons64[id]) and ('dm_'..id) or 'dm_mutations'],
            (separate[id] or icons64[id]) and {x=0,y=0} or positions[id])
        sprite.created_on_pause=true
        sprite.states.collide.can=false;sprite.states.drag.can=false;sprite.states.hover.can=false
        return {n=G.UIT.O,config={object=sprite}}
    end
    function M.icon(id,size) return icon(id,size or 0.7) end
    function M.locked_icon(id,size)
        local art=icon(id,size or 1.85);local sprite=art.config.object
        sprite.draw=function(self)
            Sprite.draw(self,{0.4,0.4,0.4,0.7})
            prep_draw(self,1)
            local x,y=self.T.w/2,self.T.h/2
              love.graphics.setColor(G.C.WHITE)
              local width=love.graphics.getLineWidth()
              love.graphics.setLineWidth(0.06)
            love.graphics.rectangle('line',x-0.14,y-0.23,0.28,0.26,0.08)
            love.graphics.rectangle('fill',x-0.23,y-0.06,0.46,0.36,0.035)
              love.graphics.setColor(G.C.BLACK);love.graphics.rectangle('fill',x-0.03,y+0.03,0.06,0.14)
              love.graphics.setLineWidth(width)
            love.graphics.pop()
        end
        return art
    end
    function M.feedback(ids,message,colour,delay)
        return {message=message,colour=colour,portrait_scale=0.42,
            portrait_offset={x=0,y=0.03*G.CARD_H},delay=delay or 0.5,
            status_nodes=function(fade_colour)
                local nodes={}
                for _,id in ipairs(ids) do
                    local node=icon(id,0.62)
                    local sprite=node.config.object
                    sprite.created_on_pause=G.SETTINGS.paused
                    local tint={1,1,1,1}
                    sprite.draw=function(self)
                        tint[4]=fade_colour[4]
                        Sprite.draw(self,tint)
                    end
                    nodes[#nodes+1]=node
                end
                return nodes
            end}
    end
    -- The same art is used at every level; text remains sharp and localized.
    function M.visual_info(id,n)
        n=n or level(id)
        local tier
        for _,d in ipairs(order) do if d.id==id and d.levels then tier=({'I','II','III'})[n] or tostring(n) end end
        local info={title=name(id,n),class='Mutation',secondary={},text=localize{type='raw_descriptions',set='Other',key='dm_'..id,vars=vars(id,n)},tier=tier,max_tier=tier and (({'I','II','III'})[M.config().max_level] or tostring(M.config().max_level))}
        info.loc={set='Other',key='dm_'..id,vars=vars(id,n)}
        if id=='chaos' and M.state() and M.state().chaos_bonus then
            local key=({hands='k_hands',discards='k_discards',hand_size='k_hand_size'})[M.state().chaos_bonus]
            info.secondary[#info.secondary+1]='+1 '..localize(key)
        end
        return info
    end
    M.active_visuals=active
    function M.choice(id,n)
        local art=icon(id,2.55);local sprite=art.config.object
        sprite.draw=function(self)
            Sprite.draw(self,M.selecting and M.selecting~=id and {0.35,0.35,0.35,0.5} or nil)
        end
        return {n=G.UIT.C,config={align='cm',padding=0.12,minw=2.7,maxw=2.7,minh=3.4,
            colour=G.C.CLEAR,button='dm_choose',ref_table=id,dm_sprite=sprite,
            pg_run_action=true,hover=true,on_demand_tooltip={},
            pg_visual_tooltip=function() return PortraitRunGallery.tooltip(M.visual_info(id,n)) end},nodes={art}}
    end
    -- Obtained mutations are inspected in the shared Run tab, never on the board.
    function M.run_info()
        if M.required_offer() then return M.offer() end
        if PortraitRunGallery then return PortraitRunGallery.open() end
    end
end
