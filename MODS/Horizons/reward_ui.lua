-- Shared native CardArea selectors. UI references never own committed state.
return function(H)
 local U={};H.rewardUI=U
 local P,X=H.P,H.X
 function U.save() X.checkpoint();if G.FILE_HANDLER then G.FILE_HANDLER.force=true end end
 function U.state() local s=H.state();if not s then return end;s.rewards=s.rewards or {metrics={},visit=0};return s.rewards end
 function U.metrics() return U.state().metrics end
 local begin=P.begin_run
 function P.begin_run(loading,...)
  local result=begin(loading,...);local s=U.state()
  if s and not loading then s.history_complete=true end
  return result
 end
 function U.text(es,en) return H.text(es,en) end
 function U.wrap(str)
  local out,line={},''
  for w in (str or ''):gmatch('%S+') do
   if #line+#w>37 then out[#out+1]=line;line=w else line=line=='' and w or line..' '..w end
  end
  if line~='' then out[#out+1]=line end;return out
 end
 function U.loc(id)
  local d=H.meta[id]
  local en,es={name=d.name_en,text=U.wrap(d.effect_en)},{name=d.name,text=U.wrap(d.effect)}
  return {['en-us']=en,es_ES=es,es_419=es}
 end
 function U.afford(n) return G.GAME.dollars-G.GAME.bankrupt_at>=n end
 function U.shop() return P.normal_shop() and not (H.state() and H.state().extra_shop) end
 function U.owned(id)
  return G.GAME and G.GAME.used_vouchers and G.GAME.used_vouchers[H.key(id)]==true
 end
 function U.find(id)
  for _,area in pairs({G.jokers,G.consumeables,G.hand,G.deck,G.discard,G.shop_jokers,G.pack_cards,G.shop_booster,G.shop_vouchers}) do
   for _,c in ipairs(area and area.cards or {}) do if c.ability.exp48_id==id and not c.removed then return c end end
  end
  return X.find(id)
 end
 function U.name(c) return localize{type='name_text',set=c.config.center.set,key=c.config.center.key} end
 function U.pool(set,excluded)
  local out={};for _,key in ipairs(P.pool(set)) do
   local center=G.P_CENTERS[key]
   if center and center.set==set and not (excluded or {})[key] and key~='c_soul' and key~='c_black_hole'
    and (set~='Planet' or not center.config.hand_type or SMODS.is_poker_hand_visible(center.config.hand_type)) then out[#out+1]=key end
  end;return out
 end
 function U.pick(pool,seed)
  if #pool==0 then return end
  return table.remove(pool,math.min(#pool,math.floor(P.roll(seed)*#pool)+1))
 end
 function U.close() U.view=nil;G.FUNCS.exit_overlay_menu() end
 function U.preview(saved)
  local key=saved.save_fields.center;local was=G.GAME.used_jokers[key]
  local c=Card(0,0,G.CARD_W,G.CARD_H,G.P_CARDS.empty,G.P_CENTERS[key],{bypass_discovery_center=true})
  saved=copy_table(saved);saved.added_to_deck=false;c:load(saved);c.added_to_deck=false;c.hz_preview=true
  G.GAME.used_jokers[key]=was;return c
 end
 function U.card_entries(cards)
  local out={};for _,c in ipairs(cards) do out[#out+1]={id=X.id(c),saved=c:save()} end;return out
 end
 local function restore_used(saved)
  if not saved or not G.GAME or not G.GAME.used_jokers then return end
  for key in pairs(G.GAME.used_jokers) do G.GAME.used_jokers[key]=nil end
  for key,value in pairs(saved) do G.GAME.used_jokers[key]=value end
 end
 function U.key_entry(key)
  local used=copy_table(G.GAME.used_jokers)
  local c=SMODS.create_card{key=key,set=G.P_CENTERS[key].set,skip_materialize=true,no_edition=true,key_append='hz_preview'}
  c.hz_preview=true;local saved=c:save();c:remove();restore_used(used)
  return {id=key,saved=saved}
 end
 -- Native Card.remove releases its center from the used pool even when the
 -- card was only a selector image. Preserve the complete map around disposal.
 local remove=Card.remove
 function Card:remove(...)
  if not self.hz_preview then return remove(self,...) end
  local used=G.GAME and G.GAME.used_jokers and copy_table(G.GAME.used_jokers)
  local result=remove(self,...);restore_used(used);return result
 end
 function U.choose(title,entries,callback,back,page)
  U.view={title=title,entries=entries,callback=callback,back=back,page=page or 1}
  U.render()
 end
 function U.render()
  local v=U.view;if not v then return end
  local nodes,cells={P.text(v.title,0.4)},{}
  for i=(v.page-1)*3+1,math.min(#v.entries,v.page*3) do
   local item=v.entries[i]
   if item.saved then
    local area=CardArea(0,0,1.45,2.0,{card_limit=1,type='title',highlight_limit=0})
    local c=U.preview(item.saved);c.hz_action=i;area:emplace(c)
    local children={{n=G.UIT.O,config={object=area}}}
    if item.label then children[#children+1]=P.text(item.label,0.24) end
    cells[#cells+1]={n=G.UIT.C,config={align='cm',padding=0.06},nodes=children}
   else
    nodes[#nodes+1]=P.button(item.label or tostring(item.id),'hz_reward_choose',i)
   end
  end
  if #cells>0 then nodes[#nodes+1]={n=G.UIT.R,config={align='cm'},nodes=cells} end
  if v.page>1 then nodes[#nodes+1]=P.button(U.text('Anterior','Previous'),'hz_reward_page',v.page-1) end
  if v.page*3<#v.entries then nodes[#nodes+1]=P.button(U.text('Siguiente','Next'),'hz_reward_page',v.page+1) end
  P.open(nodes,'hz_reward_back')
 end
 G.FUNCS.hz_reward_choose=function(e)
  local v=U.view;local item=v and v.entries[e.config.ref_table]
  if item then local fn=v.callback;U.view=nil;G.FUNCS.exit_overlay_menu();fn(item.id,item) end
 end
 G.FUNCS.hz_reward_page=function(e) if U.view then U.view.page=e.config.ref_table;U.render() end end
 G.FUNCS.hz_reward_back=function()
  local back=U.view and U.view.back;U.close();if back then back() end
 end
 local click=Card.click
 function Card:click(...)
  if self.hz_preview then
   if self.hz_action and U.view then return G.FUNCS.hz_reward_choose{config={ref_table=self.hz_action}} end
   return
  end
  return click(self,...)
 end
 local use=G.FUNCS.use_card
 G.FUNCS.use_card=function(e,...)
  local c=e and e.config and e.config.ref_table;local area=c and c.area
  local result=use(e,...)
  if U.state() and c and area and area==G.pack_cards and c.area~=area then
   U.state().open_pack_taken=true;U.state().tag_pack_taken=true
  end
  if U.state() and c and area and (area==G.shop_booster or area==G.shop_vouchers) and c.area~=area then
   U.metrics().shop_spent=true
  end
  return result
 end
 -- Keep visit bookkeeping independent of the native shop layout.
 local shop=G.UIDEF.shop
 function G.UIDEF.shop(...)
  local s=U.state()
  if s and not G.load_shop_jokers and not G.load_shop_vouchers and not G.load_shop_booster then
   s.visit=s.visit+1;s.alembic_used=nil;s.sewing_used=nil;s.contract_used=nil
  end
  return shop(...)
 end
 return U
end
