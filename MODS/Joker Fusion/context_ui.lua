return function(F,P)
    local function clear(card)
        if card.children.fuse_button then card.children.fuse_button:remove();card.children.fuse_button=nil end
    end
    local function button(card)
        local align='cl'
        local normal=card.children.use_button or card.children.buy_button
        if normal and normal.config and normal.config.align=='cl' then align='cr' end
        if G.ROOM and card.T.x-G.ROOM.T.x<1.3 then align='cr' end
        return UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.08,r=0.08,
            minw=1.15,minh=0.65,colour=G.C.GOLD,shadow=true,hover=true,one_press=true,
            ref_table=card,button='fuse_context',func='can_fuse_context'},nodes={
                {n=G.UIT.T,config={text=localize('k_fuse_fusion'),scale=0.3,colour=G.C.UI.TEXT_DARK,shadow=true}},
            }},config={align=align,offset={x=align=='cl' and 0.08 or -0.08,y=0},parent=card}}
    end
    G.FUNCS.can_fuse_context=function(e)
        local c=e.config.ref_table;local choices=F.context_options(c)
        local valid=c.highlighted and #choices>0 and F.context_ready() and F.source_afford(choices[1].source)
        e.config.button=valid and 'fuse_context' or nil
        e.config.colour=valid and G.C.GOLD or G.C.UI.BACKGROUND_INACTIVE
    end
    G.FUNCS.fuse_context=function(e)
        if not F.context_ready() then return end
        local choices=F.context_options(e.config.ref_table)
        if #choices==0 or not F.source_afford(choices[1].source) then return end
        if #choices==1 then F.fuse(choices[1]);return end
        local nodes={P.text(localize('k_fuse_choose'),0.38)}
        local function name(key) return localize{type='name_text',set='Joker',key=key} end
        for _,selection in ipairs(choices) do
            local d=F.entries[selection.id]
            nodes[#nodes+1]=P.text(name(d.components[1])..' + '..name(d.components[2]),0.25)
            nodes[#nodes+1]=P.button(name('j_fuse_'..d.id),'fuse_context_pick',selection)
        end
        P.open(nodes)
    end
    G.FUNCS.fuse_context_pick=function(e)
        local selection=e.config.ref_table
        if F.context_ready() and F.fuse(selection) then G.FUNCS.exit_overlay_menu()
        else G.FUNCS.exit_overlay_menu() end -- stale choice cancels without paying or consuming
    end
    local update=Card.update
    function Card:update(dt,...)
        local result=update(self,dt,...)
        if self.highlighted and not self.removed and not self.getting_sliced and #F.context_options(self)>0 then
            if not self.children.fuse_button then self.children.fuse_button=button(self) end
        else clear(self) end
        return result
    end
    local highlight=Card.highlight
    function Card:highlight(on,...)
        -- A roulette/reward preview has no Sell/Use action, but retains native hover information.
        if self.pg_roulette_preview or self.fuse_reward_preview then self.highlighted=on
        else highlight(self,on,...) end
        if not on then clear(self) end
    end
    local click=Card.click
    function Card:click(...)
        if (P.roulette and self==P.roulette.feature) or self.fuse_reward_preview then
            self:highlight(not self.highlighted);return
        end
        return click(self,...)
    end
end
