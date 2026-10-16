-- Each selection spends one complete composition/trade/attempt/plan. Intermediate
-- screens never award objects. Native pack checkpoints make the whole opening atomic.
return function(H)
 local K={};H.packs=K
 local X,P=H.X,H.P
 local ids={PX01='montage',PX02='pledge',PX03='escalation',PX04='roadmap'}
 local rarities={'Common','Uncommon','Rare'}
 local function state()
  local s=H.state();if not s then return end
  s.packs=s.packs or {plans={},metrics={standard={},destroyed={},rarities={},skips={}}};return s.packs
 end
 local function restore(saved)
  local key=saved.save_fields.center;local used=G.GAME.used_jokers[key]
  local c=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.c_base,{bypass_discovery_center=true})
  c:load(copy_table(saved));c.added_to_deck=false;G.GAME.used_jokers[key]=used;return c
 end
 local function discard_preview(c,used)
  used=used or copy_table(G.GAME.used_jokers)
  c:remove()
  -- Detached options are not sales/destructions of owned or shop inventory.
  for key in pairs(G.GAME.used_jokers) do G.GAME.used_jokers[key]=nil end
  for key,value in pairs(used) do G.GAME.used_jokers[key]=value end
 end
 local function snapshot(c,used) local s=copy_table(c:save());discard_preview(c,used);return s end
 local function choose(t,key)
  if #t==0 then return end
  return pseudorandom_element(t,pseudoseed('hz_pack_'..key))
 end
 local function shuffle(t,key)
  t=copy_table(t);pseudoshuffle(t,pseudoseed('hz_pack_'..key));return t
 end
 local function tag_pool()
  local pool=get_current_pool('Tag',nil,nil,'hz_roadmap');local out={};local seen={}
  for _,key in ipairs(pool) do
   local d=G.P_TAGS[key]
   if d and not seen[key] and d.unlocked~=false and not G.GAME.banned_keys[key] and SMODS.add_to_pool(d,{source='hz_roadmap'}) then
    seen[key]=true;out[#out+1]=key
   end
  end
  return out
 end
 local function pledges()
  local t={}
  for _,c in ipairs(G.playing_cards or {}) do
   if not c.removed and not c.getting_sliced and not SMODS.is_eternal(c,{destroy_cards=true}) and not c.ability.x48_reserved then t[#t+1]=X.id(c) end
  end
  return t
 end
 local function standard(booster,i)
  local c=G.P_CENTERS.p_standard_normal_1:create_card(booster,i)
  return type(c.is)=='function' and c:is(Card) and c or SMODS.create_card(c)
 end
 function K.prepare(booster)
  if booster.ability.hz_payload then return booster.ability.hz_payload end
  local id=booster.config.center.horizons
  local count=math.max(1,(booster.ability.extra or 3)+(G.GAME.modifiers.booster_size_mod or 0))
  local base=math.max(1,(booster.ability.choose or 1)+(G.GAME.modifiers.booster_choice_mod or 0))
  local payload={id=id,count=count,base=base,units={},serial=X.id(booster)}
  local used=copy_table(G.GAME.used_jokers)
  -- Reserve enough full units for the maximum two Rain Check credits, even when
  -- Takeaway is purchased before those credits are earned.
  for unit=1,base+2 do
   local u={};payload.units[unit]=u;local seed=payload.serial..':'..unit
   if id=='PX01' then
    u.bodies={};u.finishes={};local fronts={};for key in pairs(G.P_CARDS) do if G.P_CARDS[key].suit then fronts[#fronts+1]=key end end;table.sort(fronts)
    fronts=shuffle(fronts,seed..'body')
    for i=1,math.min(count,#fronts) do
     local body=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS[fronts[i]],G.P_CENTERS.c_base)
     u.bodies[i]=snapshot(body,used);u.finishes[i]={}
     for j=1,count do
      local finish=standard(booster,j);finish:set_base(G.P_CARDS[fronts[i]])
      u.finishes[i][j]=snapshot(finish,used)
     end
    end
   elseif id=='PX02' then
    u.pairs={};local cards=shuffle(pledges(),seed..'pledges');local pool={}
    for _,key in ipairs(P.pool('Spectral')) do if key~='c_soul' and key~='c_black_hole' then pool[#pool+1]=key end end
    pool=shuffle(pool,seed..'spectral')
    for i=1,math.min(count,#cards,#pool) do
     u.pairs[i]={id=cards[i],card=snapshot(SMODS.create_card{set='Spectral',key=pool[i],key_append=seed},used)}
    end
   elseif id=='PX03' then
    u.levels={};u.success={P.roll('hz_escalation_'..seed..'_1')<0.75,P.roll('hz_escalation_'..seed..'_2')<0.5}
    for rarity=1,3 do
     u.levels[rarity]={};local pool=P.pool('Joker',rarities[rarity])
     for i=1,math.max(1,count-2) do
      local key=choose(pool,seed..':'..rarity..':'..i)
      if key then u.levels[rarity][i]=snapshot(SMODS.create_card{set='Joker',key=key,key_append=seed},used) end
     end
    end
   else
    u.tags={};local pool=shuffle(tag_pool(),seed..'tags');local hands={}
    for _,name in ipairs(G.handlist) do if SMODS.is_poker_hand_visible(name) then hands[#hands+1]=name end end
    for i=1,math.min(count,#pool) do u.tags[i]={key=pool[i],orbital_hand=pool[i]=='tag_orbital' and choose(hands,seed..'orbital') or nil} end
   end
  end
  booster.ability.hz_payload=payload;return payload
 end
 function K.freeze(card)
  local payload=copy_table(K.prepare(card))
  return {hz=true,payload=payload,card=copy_table(card:save()),contents={},size=payload.count,choices=payload.base}
 end
 local function active() return K.current and SMODS.OPENED_BOOSTER==K.current and G.GAME.PACK_INTERRUPT and K.current.ability.hz_payload end
 local function unit() local p=active();return p and p.units[K.unit or 1],p end
 local function clear()
  if G.pack_cards and G.pack_cards.cards then for i=#G.pack_cards.cards,1,-1 do local c=G.pack_cards.cards[i];G.pack_cards:remove_card(c);discard_preview(c) end end
 end
 local function rows(str)
  local t={};for _,line in ipairs(require('portrait_tooltips').wrap({str},6.2,0.32)) do t[#t+1]=P.text(line,0.32) end;return t
 end
 function K.title()
  local p=active();if not p then return '' end
  local d=H.meta[p.id];local suffix=''
  if p.id=='PX01' then suffix=K.body and H.text(' · Acabado',' · Finish') or H.text(' · Rango y palo',' · Rank and suit') end
  if p.id=='PX02' then suffix=H.text(' · Spectral / Prenda',' · Spectral / Pledge') end
  if p.id=='PX04' then suffix=K.small and H.text(' · Big Blind',' · Big Blind') or H.text(' · Small Blind',' · Small Blind') end
  return H.text(d.name,d.name_en)..suffix
 end
 local function push(saved,index,kind)
  local c=restore(saved);c.ability.hz_pack_choice={index=index,kind=kind};c.bypass_discovery_ui=true;c.bypass_lock=true
  G.pack_cards:emplace(c);return c
 end
 local function roadmap_ui()
  local u=unit();local nodes={};local cells={}
  for i,t in ipairs(u.tags) do if i~=K.small then
   local tag=Tag(t.key,true);if t.orbital_hand then tag.ability.orbital_hand=t.orbital_hand end
   local tab,sprite=tag:generate_UI(1.6)
   local item={index=i,tag=tag};sprite.click=function() K.select(i,'tag') end
   cells[#cells+1]={n=G.UIT.C,config={align='cm',minw=2,minh=2,padding=0.1,button='hz_pack_tag',ref_table=item,hover=true},nodes={tab}}
   if #cells==3 then nodes[#nodes+1]={n=G.UIT.R,config={align='cm'},nodes=cells};cells={} end
  end end
  if #cells>0 then nodes[#nodes+1]={n=G.UIT.R,config={align='cm'},nodes=cells} end
  nodes[#nodes+1]=P.text(K.title(),0.4);nodes[#nodes+1]=P.text(H.text('Planes restantes: ','Plans remaining: ')..G.GAME.pack_choices,0.32)
  nodes[#nodes+1]=UIBox_button{label={localize('b_skip')},button='skip_booster',minw=2,minh=0.8}
  return {n=G.UIT.ROOT,config={align='cm',padding=0.1,colour=G.C.CLEAR},nodes=nodes}
 end
 function K.refresh()
  local u,p=unit();if not u or not G.pack_cards then return end
  clear();K.built=true;K.uititle=K.title()
  if p.id=='PX04' then
   local previous=G.pack_cards
   if G.booster_pack then G.booster_pack:remove() end
   if previous and not previous.REMOVED then previous:remove() end
   G.pack_cards=CardArea(0,0,1,1,{type='consumeable',card_limit=0,highlight_limit=1})
   G.booster_pack=UIBox{definition=roadmap_ui(),config={align='tmi',major=G.hand,offset={x=0,y=-2.2},bond='Weak'}}
   if G.F_PORTRAIT then portrait_anchor_run_panel(G.booster_pack,true) end
   return
  end
  if p.id=='PX01' then for i,c in ipairs(K.body and u.finishes[K.body] or u.bodies) do push(c,i,K.body and 'finish' or 'body') end
  elseif p.id=='PX02' then
   for i,pair in ipairs(u.pairs) do
    push(pair.card,i,'pledge')
    local c=X.find(pair.id);if c then push(copy_table(c:save()),i,'pledge') end
   end
  else
   for i,c in ipairs(u.levels[K.level or 1] or {}) do push(c,i,'joker') end
   if (K.level or 1)<3 and #(u.levels[(K.level or 1)+1] or {})>0 then
    local c=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.c_base)
    c.ability.hz_pack_choice={kind='risk'}
    c.children.center.atlas=c.children.back.atlas;c.children.center:set_sprite_pos(c.children.back.sprite_pos)
    c.children.hz_risk=UIBox{definition={n=G.UIT.ROOT,config={align='cm',colour=G.C.BLACK,r=0.1,padding=0.08},nodes={
     P.text(H.text('ARRIESGAR','RISK'),0.32),P.text((K.level or 1)==1 and '75%' or '50%',0.45)}},
     config={align='cm',major=c,bond='Strong'}}
    G.pack_cards:emplace(c)
   end
  end
  G.pack_cards.config.card_limit=math.max(1,#G.pack_cards.cards)
 end
 function K.complete()
  local rain=X.mutations and X.mutations.state().rain_pack
  if rain then rain.choices=rain.choices+1 end
  G.GAME.pack_choices=math.max(0,G.GAME.pack_choices-1)
  K.unit=(K.unit or 1)+1;K.body=nil;K.small=nil;K.level=1
  if G.GAME.pack_choices<=0 then G.FUNCS.end_consumeable(nil,0.2) else K.refresh() end
 end
 local function deliver(saved,set)
  local c=restore(saved);c.ability.hz_pack_choice=nil;c.playing_card=nil;c.added_to_deck=false
  local area=set=='Joker' and G.jokers or set=='Spectral' and G.consumeables or G.deck
  if (set=='Joker' or set=='Spectral') and not G.FUNCS.check_for_buy_space(c) then discard_preview(c);return false end
  if set=='Default' then
   G.playing_card=(G.playing_card or 0)+1;c.playing_card=G.playing_card
   c:add_to_deck();area:emplace(c);G.playing_cards[#G.playing_cards+1]=c;playing_card_joker_effects({c})
  else c:add_to_deck();area:emplace(c) end
  discover_card(c.config.center);c:start_materialize();return true
 end
 function K.select(index,kind)
  local u,p=unit();if not u or K.selecting then return end
  if kind=='body' then if u.bodies[index] then K.body=index;K.refresh() end;return end
  if kind=='finish' then if deliver(u.finishes[K.body][index],'Default') then K.complete() end;return end
  if kind=='tag' then
   if not u.tags[index] or index==K.small then return end
   if not K.small then K.small=index;K.refresh();return end
   local s=state();s.plans[#s.plans+1]={Small=copy_table(u.tags[K.small]),Big=copy_table(u.tags[index])};K.complete();return
  end
  if kind=='risk' then
   local level=K.level or 1
   if level>=3 or #(u.levels[level+1] or {})==0 then return end
   if u.success[level] then K.level=level+1;play_sound('tarot1');K.refresh()
   else play_sound('cancel');K.complete() end;return
  end
  if kind=='joker' then if deliver(u.levels[K.level or 1][index],'Joker') then K.complete() end;return end
  if kind=='pledge' then
   local pair=u.pairs[index];local collateral=pair and X.find(pair.id)
   if not collateral or collateral.removed or collateral.getting_sliced or collateral.ability.x48_reserved or
    SMODS.is_eternal(collateral,{destroy_cards=true}) then return end
   local c=restore(pair.card)
   if not G.FUNCS.check_for_buy_space(c) then discard_preview(c);return end
   K.selecting=true
   -- Capacity is validated before either side of this one-way exchange changes.
   c:add_to_deck();G.consumeables:emplace(c);discover_card(c.config.center)
   SMODS.destroy_cards({collateral});c:start_materialize();K.selecting=nil;K.complete()
  end
 end
 function K.preview(card)
  local payload=K.prepare(card);local entries={}
  local function add(saved,label) entries[#entries+1]={id=#entries+1,saved=saved,label=label} end
  for n,u in ipairs(payload.units) do
   local label=H.text('Elección ','Choice ')..n
   if u.bodies then
    for i,finishes in ipairs(u.finishes) do for _,saved in ipairs(finishes) do add(saved,label..' · '..i) end end
   elseif u.pairs then
    for _,pair in ipairs(u.pairs) do
     add(pair.card,label);local c=X.find(pair.id)
     if c then add(copy_table(c:save()),H.text('Prenda','Pledge')) end
    end
   elseif u.levels then
    for level,cards in ipairs(u.levels) do
     local result=level==1 and '' or (u.success[1] and (level==2 or u.success[2])) and H.text(' · Éxito',' · Success') or H.text(' · Fallo',' · Failure')
     for _,saved in ipairs(cards) do add(saved,label..result) end
    end
   else
    for _,t in ipairs(u.tags) do entries[#entries+1]={id=#entries+1,label=localize{type='name_text',set='Tag',key=t.key}..(t.orbital_hand and ' · '..localize(t.orbital_hand,'poker_hands') or '')} end
   end
  end
  H.rewardUI.choose(H.text('Radiografía','X-Ray'),entries,function() K.preview(card) end,H.tags.inspect_packs)
 end
 for id,key in pairs(ids) do
  local d=H.meta[id];H.atlas('pack_'..key,'packs/'..key..'.png',71,95)
  local loc={};for _,lang in ipairs({'en-us','es_ES','es_419'}) do local es=lang~='en-us';loc[lang]={name=es and d.name or d.name_en,text=H.lines(es and d.effect or d.effect_en),unlock=H.lines(es and d.unlock or d.unlock_en)} end
  SMODS.Booster(H.decorate({key=key,atlas='pack_'..key,pos={x=0,y=0},kind='Horizons',cost=d.cost,weight=d.weight,
   config={extra=id=='PX04' and 4 or 3,choose=1},draw_hand=false,loc_txt=loc,
   in_pool=function()
    if id=='PX02' then return #pledges()>0 and #P.pool('Spectral')>0 end
    if id=='PX03' then return #P.pool('Joker','Common')>0 end
    if id=='PX04' then return #tag_pool()>=2 end;return true
   end,
   create_card=function(self,booster,i)
    -- The ordinary opener fills its area before our stage renderer takes over.
    local p=K.prepare(booster);local c=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS.c_base)
    c.ability.hz_pack_placeholder=true;return c
   end,
   create_UIBox=function(self)
    local p=active();K.uititle=K.title()
    local definition=portrait_pack_ui(p.count*(p.id=='PX02' and 2 or 1),K.uititle)
    local title=definition.nodes[2].nodes[1].nodes[1].nodes[1]
    title.config.text=nil;title.config.ref_table=K;title.config.ref_value='uititle'
    return definition
   end,
   update_pack=function(self,dt)
    SMODS.Booster.update_pack(self,dt)
    if active() and not K.built and G.pack_cards and G.pack_cards.cards and not G.pack_cards.REMOVED and #G.pack_cards.cards>=active().count then K.refresh() end
   end},id))
 end
 H.installers[#H.installers+1]=function()
  local A=X.mutations
  local freeze=A.freeze_pack
  function A.freeze_pack(card) if ids[card.config.center.horizons] then return K.freeze(card) end;return freeze(card) end
  local open=Card.open
  function Card:open(...)
   if not ids[self.config.center.horizons] then return open(self,...) end
   K.prepare(self);K.current=self;K.unit=1;K.level=1;K.body=nil;K.small=nil;K.built=false
   A.frozen_pack_active=true
   local r=open(self,...);return r
  end
  local use=G.FUNCS.use_card
  G.FUNCS.use_card=function(e,...)
   local c=e.config.ref_table;local choice=c and c.ability.hz_pack_choice
   if active() and c and c.ability.hz_pack_placeholder then return end
   if active() and c and c.area==G.pack_cards and choice then return K.select(choice.index,choice.kind) end
   return use(e,...)
  end
  local can=G.FUNCS.can_select_card
  G.FUNCS.can_select_card=function(e,...)
   local c=e.config.ref_table
   if active() and c and c.ability.hz_pack_choice then e.config.button='use_card';e.config.colour=G.C.GREEN;return end
   return can(e,...)
  end
  local usable=Card.can_use_consumeable
  function Card:can_use_consumeable(...)
   if active() and self.area==G.pack_cards and self.ability.hz_pack_choice then return true end
   return usable(self,...)
  end
  local info=Card.generate_UIBox_ability_table
  function Card:generate_UIBox_ability_table(...)
   if self.ability.hz_pack_choice and self.ability.hz_pack_choice.kind=='risk' then
    local text=H.text('Renuncia a los Jokers visibles. Si falla el ascenso, pierdes este intento.','Give up the visible Jokers. If the advance fails, this attempt is lost.')
    return {name={{n=G.UIT.T,config={text=H.text('Arriesgar','Risk'),colour=G.C.WHITE,scale=0.4}}},
     main=require('portrait_tooltips').rows({text={text}},5),info={},type={}}
   end
   return info(self,...)
  end
  local skip=G.FUNCS.can_skip_booster
  G.FUNCS.can_skip_booster=function(e,...)
   if active() then e.config.button='skip_booster';e.config.colour=G.C.GREY;return end
   return skip(e,...)
  end
  local finish=G.FUNCS.end_consumeable
  G.FUNCS.end_consumeable=function(...)
   local p=active();if p then clear();K.current=nil;K.built=nil end
   return finish(...)
  end
  G.FUNCS.hz_pack_tag=function(e) K.select(e.config.ref_table.index,'tag') end
  local consume=Card.use_consumeable
  function Card:use_consumeable(...)
   local before=H.state() and X.set(G.playing_cards) or {};local game=G.GAME
   local r=consume(self,...)
   if next(before) then G.E_MANAGER:add_event(Event{trigger='after',delay=0,func=function()
    local s=state();if G.GAME==game and s then
     for id in pairs(before) do if not X.find(id) then s.metrics.destroyed[id]=true end end
    end;return true
   end}) end;return r
  end
  local check=check_for_unlock
  function check_for_unlock(args,...)
   local s=state();local m=s and s.metrics
   if m and args.type=='win' and m.complete_history then
    if m.rarities[1] and m.rarities[2] and m.rarities[3] and not m.legendary then H.unlock('PX03') end
    local n=0;for _,count in pairs(m.skips) do if count==1 then n=n+1 end end
    if n>=5 then H.unlock('PX04') end
   end
   return check(args,...)
  end
  local begin=Game.start_run
  function Game:start_run(args,...)
   local r=begin(self,args,...);local s=state()
   if s and not (args and args.savetext) then s.metrics.complete_history=true end
   K.current=nil;K.built=nil;return r
  end
  -- Defer plan assignment until the native Ante actually creates fresh tags.
  local reset=reset_blinds
  function reset_blinds(...)
   local before=G.GAME.round_resets.blind_choices.Boss
   local was_defeated=G.GAME.round_resets.blind_states.Boss=='Defeated'
   local r=reset(...);local s=state()
   local closed=was_defeated and G.GAME.round_resets.blind_states.Boss~='Defeated'
   if s and closed then
    G.E_MANAGER:add_event(Event{trigger='after',delay=0,func=function()
     if #s.plans>0 then
      local plan=table.remove(s.plans,1)
      for _,b in ipairs({'Small','Big'}) do
       G.GAME.round_resets.blind_tags[b]=plan[b].key
       if plan[b].orbital_hand then
        G.GAME.orbital_choices[G.GAME.round_resets.ante]=G.GAME.orbital_choices[G.GAME.round_resets.ante] or {}
        G.GAME.orbital_choices[G.GAME.round_resets.ante][b]=plan[b].orbital_hand
       end
      end
     end;return true
    end})
   end;return r
  end
 end
 H.on(function(c)
  local s=state();if not s or not P.real(c) then return end;local m=s.metrics
  if c.open_booster then
   local card=c.card;m.current_standard=card and card.config.center.kind=='Standard' and X.id(card) or nil
  end
  if c.ending_booster then m.current_standard=nil end
  if c.playing_card_added and m.current_standard then
   for _,card in ipairs(c.cards or c.playing_cards or (c.card and {c.card}) or {}) do
    m.standard[m.current_standard]=true;card.ability.hz_standard_origin=true
   end
  end
  if c.buying_card and c.card and c.card.ability.set=='Joker' then
   local rarity=c.card.config.center.rarity
   m.rarities[rarity]=true
  end
  if c.card_added and c.card and c.card.ability.set=='Joker' then
   local r=c.card.config.center.rarity;if r==4 or r=='Legendary' then m.legendary=true end
  end
  if c.skip_blind then local a=tostring(G.GAME.round_resets.ante);m.skips[a]=(m.skips[a] or 0)+1 end
  if c.before then
   m.standard_winner=false
   for _,card in ipairs(c.scoring_hand or {}) do if card.ability.hz_standard_origin then m.standard_winner=true end end
  end
  if P.won(c) and G.GAME.blind.boss and G.GAME.round_resets.ante>=6 then
   if X.count(m.standard)>=3 and m.standard_winner then H.unlock('PX01') end
   if X.count(m.destroyed)>=5 and #G.playing_cards<=40 then H.unlock('PX02') end
  end
 end)
end
