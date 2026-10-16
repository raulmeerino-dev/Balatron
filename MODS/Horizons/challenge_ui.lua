return function(H)
 local C,X,P=H.challenges,H.X,H.P
 local function lines(text,nodes)
  local line=''
  for word in text:gmatch('%S+') do
   if #line+#word>44 then nodes[#nodes+1]=P.text(line,0.3);line='' end
   line=line=='' and word or line..' '..word
  end
  if line~='' then nodes[#nodes+1]=P.text(line,0.3) end
 end
 function C.offer_pending()
  if not C.active('CH04') then return false end
  local s=C.state();return s and s.oath_ante~=G.GAME.round_resets.ante
 end
 function C.oath_offer()
  if not C.offer_pending() then return end
  local s=C.state();local contracts=P.modules.contracts;local cfg=contracts.config()
  local ante=G.GAME.round_resets.ante
  if s.oath_offer_ante~=ante then
   s.oath_offer_ante=ante;s.oath_choices={}
   local owned={};for _,a in ipairs(contracts.active()) do owned[a.id]=true end
   local function eligible(id)
    local d=contracts.entries[id]
    return d and not owned[id] and (not cfg.contracts or cfg.contracts[id]~=false) and (not d.eligible or d.eligible())
   end
   local safe=eligible('no_safety_net') and 'no_safety_net' or eligible('clean_hands') and (cfg.clean_hands_blinds or 2)<=3 and 'clean_hands'
   if safe then s.oath_choices[1]=safe end
   local candidates={}
   for _,id in ipairs({'clean_hands','one_shot','monochrome','execution'}) do
    if id~=safe and eligible(id) and (id~='clean_hands' or (cfg.clean_hands_blinds or 2)<=3) then candidates[#candidates+1]=id end
   end
   while #s.oath_choices<3 and #candidates>0 do
    local picked,index=pseudorandom_element(candidates,pseudoseed('hz_oath_'..ante..'_'..#s.oath_choices))
    s.oath_choices[#s.oath_choices+1]=picked;table.remove(candidates,index)
   end
   -- A carried safe Contract is already a deliberate undertaking for this Ante.
   if #s.oath_choices==0 then s.oath_ante=ante;return end
   save_run()
  end
  local nodes={P.text(H.text('Juramento: escoge un Contract','Oath: choose a Contract'),0.4)}
  for _,id in ipairs(s.oath_choices) do nodes[#nodes+1]=P.button(localize('k_ct_'..id),'hz_oath_review',id) end
  P.open(nodes)
 end
 H.installers[#H.installers+1]=function()
  G.FUNCS.hz_oath_review=function(e)
   local id=e.config.ref_table;local contracts=P.modules.contracts
   local info=contracts.info(contracts.offer_terms(id));info.width=math.min(5,G.ROOM.T.w-1)
   P.open({require('portrait_tooltips').embedded(PortraitRunGallery.tooltip(info)),P.button(localize('b_ct_accept'),'hz_oath_accept',id),P.button(localize('b_back'),'hz_oath_back')})
  end
  G.FUNCS.hz_oath_back=function() C.oath_offer() end
  G.FUNCS.hz_oath_accept=function(e)
   local contracts=P.modules.contracts;local s=C.state();local id=e.config.ref_table;local valid=false
   for _,v in ipairs(s.oath_choices or {}) do if v==id then valid=true end end
   if not valid or not C.offer_pending() then return end
   local old=contracts.state().offer;contracts.state().offer=id
   local accepted=contracts.accept()
   contracts.state().offer=old
   if accepted then s.oath_ante=G.GAME.round_resets.ante;s.oath_choices=nil;G.FUNCS.exit_overlay_menu();save_run() end
  end
  local select=G.FUNCS.select_blind
  G.FUNCS.select_blind=function(...) if C.offer_pending() then C.oath_offer();return end;return select(...) end
  local update=Game.update_blind_select
  function Game:update_blind_select(...)
   local r=update(self,...)
   if C.offer_pending() and not G.OVERLAY_MENU and G.STATE_COMPLETE then C.oath_offer() end
   return r
  end
  G.FUNCS.hz_challenge_locked=function(e)
   local d=H.meta[e.config.ref_table];if not d then return end
   local nodes={P.text(H.text(d.name,d.name_en),0.42)}
   lines(H.text(d.unlock,d.unlock_en),nodes)
   if not C.available(d.id) then lines(H.text('Activa también los módulos necesarios para este reto.','Enable the modules required by this Challenge.'),nodes) end
   P.open(nodes)
  end
  local list=G.UIDEF.challenge_list_page
  G.UIDEF.challenge_list_page=function(page,...)
   local t=list(page,...)
   for _,row in ipairs(t.nodes or {}) do
    local wrapper=row.nodes and row.nodes[2]
    local button=wrapper and wrapper.nodes and wrapper.nodes[1]
    local index=button and button.config.id
    local challenge=index and G.CHALLENGES[index]
    if challenge then for n=1,8 do
     local id=string.format('CH%02d',n)
     if challenge.id==H.key(id) then
      local atlas=G.ASSET_ATLAS['hz_'..challenge.id..'_icon']
      if atlas then row.nodes[1]={n=G.UIT.C,config={align='cm',minw=0.8},nodes={{n=G.UIT.O,config={object=Sprite(0,0,0.5,0.5,atlas,{x=0,y=0})}}}} end
      if not challenge:unlocked() then button.config.button='hz_challenge_locked';button.config.ref_table=id;button.config.hover=true end
     end
    end end
   end
   return t
  end
  local description=G.UIDEF.challenge_description
  G.UIDEF.challenge_description=function(index,...)
   local t=description(index,...);local ch=G.CHALLENGES[index]
   if ch then for n=1,8 do local id=string.format('CH%02d',n)
    if ch.id==H.key(id) and t.nodes and t.nodes[1] and t.nodes[1].nodes then
     table.insert(t.nodes[1].nodes,1,{n=G.UIT.C,config={align='cm',padding=0.05},nodes={{n=G.UIT.O,config={object=Sprite(0,0,0.85,0.85*95/71,G.ASSET_ATLAS['hz_'..ch.id..'_art'],{x=0,y=0})}}}})
    end
   end end
   return t
  end
  local start=G.FUNCS.start_challenge_run
  G.FUNCS.start_challenge_run=function(e,...)
   local ch=e and e.config and G.CHALLENGES[e.config.id]
   if ch and ch.id:sub(1,5)=='c_hz_' and not ch:unlocked() then return end
   return start(e,...)
  end
 end
 local function offer_labels(card)
  local family=card.ability.set;local rarity=''
  if family=='Joker' then
   local names={[1]='k_common',[2]='k_uncommon',[3]='k_rare',[4]='k_legendary'}
   rarity=localize(names[card.config.center.rarity] or ('k_'..tostring(card.config.center.rarity)))
   if rarity=='ERROR' then rarity=tostring(card.config.center.rarity):gsub('^.-_',''):upper() end
  elseif family=='Booster' then family=card.config.center.kind or family end
  local localized=localize('k_'..family:lower())
  return localized~='ERROR' and localized or family,rarity
 end
 local draw=Card.draw
 function Card:draw(...)
  if not C.hidden(self) then
   if self.children.hz_offer_label then self.children.hz_offer_label:remove();self.children.hz_offer_label=nil end
   return draw(self,...)
  end
  if not self.children.hz_offer_label then
   local family,rarity=offer_labels(self)
   local nodes={{n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.T,config={text=family,scale=0.25,colour=G.C.WHITE}}}}}
   if rarity~='' then nodes[#nodes+1]={n=G.UIT.R,config={align='cm'},nodes={{n=G.UIT.T,config={text=rarity,scale=0.22,colour=G.C.FILTER}}}} end
   self.children.hz_offer_label=UIBox{definition={n=G.UIT.ROOT,config={align='cm',padding=0.06,r=0.08,colour=G.C.BLACK},nodes=nodes},config={align='cm',parent=self,major=self,can_collide=false}}
  end
  local face,sprite,edition=self.facing,self.sprite_facing,self.edition
  self.facing='back';self.sprite_facing='back';self.edition=nil
  local r=draw(self,...)
  self.facing=face;self.sprite_facing=sprite;self.edition=edition;return r
 end
 local tooltip=Card.generate_UIBox_ability_table
 function Card:generate_UIBox_ability_table(...)
  if not C.hidden(self) then return tooltip(self,...) end
  local family,rarity=offer_labels(self)
  return generate_card_ui({key='hz_hidden_offer',set='Other'},nil,{family,rarity})
 end
end
