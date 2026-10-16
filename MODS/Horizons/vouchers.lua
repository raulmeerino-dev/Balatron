return function(H)
 local U=H.rewardUI or assert(SMODS.load_file('reward_ui.lua'))()(H)
 local P,X=H.P,H.X
 local V={};H.vouchers=V
 local native_kinds={Arcana=true,Celestial=true,Standard=true,Spectral=true,Buffoon=true}
 local function contract() return P.modules.contracts end
 local function own(id) return U.owned(id) end
 local function eligible_contracts(except)
  local C=contract();local out,owned={},{}
  if not C or not C.enabled() then return out end
  for _,a in ipairs(C.active()) do owned[a.id]=true end
  for _,id in ipairs(C.order) do local d=C.entries[id]
   if id~=except and not owned[id] and (not C.config().contracts or C.config().contracts[id]~=false)
    and (not d.eligible or d.eligible()) then out[#out+1]=id end
  end;return out
 end
 for i=1,8 do
  local id=string.format('VX%02d',i);local meta=H.meta[id];local key=meta.key:gsub('^v_hz_','')
  H.atlas(key,'vouchers/'..key..'.png',71,95)
  local def={key=key,atlas=key,pos={x=0,y=0},cost=10,loc_txt=U.loc(id),
   requires=meta.requires or {},in_pool=function()
    return (i<7 or (contract() and contract().enabled()))
   end,redeem=function() U.save() end}
  SMODS.Voucher(H.decorate(def,id))
 end
 local function pack()
  local b=SMODS.OPENED_BOOSTER
  return b and b.ability and native_kinds[b.config.center.kind] and b
 end
 -- Native saves replay the purchase ACTION; they cannot reconstruct an open
 -- Booster. Reuse the existing atomic checkpoint through its final selection.
 local open=Card.open
 function Card:open(...)
  if self.ability.set=='Booster' and native_kinds[self.config.center.kind] and own('VX01') and X.mutations then
   X.mutations.frozen_pack_active=true
  end
  return open(self,...)
 end
 -- Tag packs have no purchase ACTION. Their checkpoint retains the unconsumed
 -- native Tag, whose ordinary callback reopens the same pack after a reload.
 local pack_tags={tag_standard=true,tag_charm=true,tag_meteor=true,tag_buffoon=true,tag_ethereal=true}
 local apply_tag=Tag.apply_to_run
 function Tag:apply_to_run(context,...)
  local A=X.mutations
  if context.type=='new_blind_choice' and pack_tags[self.key] and not self.triggered and own('VX01') and A and not A.frozen_pack_active then
   U.save();A.frozen_pack_active=true
   local result=apply_tag(self,context,...)
   if not result then A.frozen_pack_active=nil end
   return result
  end
  return apply_tag(self,context,...)
 end
 local emplace=CardArea.emplace
 function CardArea:emplace(card,...)
  local b=pack()
  if self==G.pack_cards and b and not card.ability.hz_pack_index then
   b.ability.hz_created=(b.ability.hz_created or 0)+1;card.ability.hz_pack_index=b.ability.hz_created
  end
  return emplace(self,card,...)
 end
 function V.replace_pack(all,id)
  local b=pack();if not b or not own('VX01') or b.ability.hz_replaced or (all and not own('VX02')) then return end
  local price=all and 5 or 3;if not U.afford(price) or not G.pack_cards then return end
  local targets={}
  for i,c in ipairs(G.pack_cards.cards) do
   if not id or X.id(c)==id then targets[#targets+1]={card=c,index=c.ability.hz_pack_index or i} end
  end
  if #targets==0 then return end
  -- Generate replacements as native pack cards before committing this action.
  local replacements={}
  for _,target in ipairs(targets) do
   local args=b.config.center:create_card(b,target.index)
   local c=type((args or {}).is)=='function' and args:is(Card) and args or SMODS.create_card(args)
   c.ability.hz_pack_index=target.index;replacements[#replacements+1]=c
  end
  b.ability.hz_replaced=true;ease_dollars(-price,true)
  for _,target in ipairs(targets) do G.pack_cards:remove_card(target.card);target.card:remove() end
  for _,c in ipairs(replacements) do G.pack_cards:emplace(c);c:start_materialize() end
  local m=U.metrics();m.pack_replacements=m.pack_replacements or {};m.pack_replacements[b.config.center.kind]=true
  U.save()
 end
 function V.pack_menu()
  local b=pack();if not b or b.ability.hz_replaced then return end
  local nodes={P.text(U.text('Abrecartas','Letter Opener'),0.42)}
  if U.afford(3) then nodes[#nodes+1]=P.button(U.text('Sustituir una · $3','Replace one · $3'),'hz_pack_one') end
  if own('VX02') and U.afford(5) then nodes[#nodes+1]=P.button(U.text('Sustituir todas · $5','Replace all · $5'),'hz_pack_all') end
  P.open(nodes)
 end
 G.FUNCS.hz_pack_service=V.pack_menu
 G.FUNCS.hz_pack_one=function()
  if not pack() or not G.pack_cards then return end
  U.choose(U.text('Sustituir una opción · $3','Replace one option · $3'),U.card_entries(G.pack_cards.cards),function(id) V.replace_pack(false,id) end)
 end
 G.FUNCS.hz_pack_all=function() U.close();V.replace_pack(true) end
 H.installers[#H.installers+1]=function()
  local original=SMODS.Booster.create_UIBox
  local function ui(self,...)
   local result=original(self,...)
   if own('VX01') and native_kinds[self.kind] then result.nodes[#result.nodes+1]=P.button(U.text('Abrecartas','Letter Opener'),'hz_pack_service') end
   return result
  end
  SMODS.Booster.create_UIBox=ui
  for _,b in pairs(SMODS.Booster.obj_table) do if native_kinds[b.kind] and b.create_UIBox==original then b.create_UIBox=ui end end
 end
 local function consumables(except,first)
  local out={}
  for _,c in ipairs(G.consumeables.cards) do
   local set=c.ability.set
   if not c.removed and not c.getting_sliced and X.id(c)~=except and (set=='Tarot' or set=='Planet')
    and (not first or own('VX04') or set==first.ability.set) then out[#out+1]=c end
  end;return out
 end
 function V.claim_alembic(key)
  local s=U.state();local pending=s.alembic_pending;if not pending then return end
  local valid=false;for _,k in ipairs(pending.keys) do if k==key then valid=true end end
  if not valid then return end
  pending.selected=key
  local C=contract()
  if C and C.queue_reward then
   s.alembic_pending=nil;C.queue_reward({kind='cards',keys={key}},{source='hz_alembic'})
  else
   if #G.consumeables.cards+(G.GAME.consumeable_buffer or 0)>=G.consumeables.config.card_limit then U.save();return end
   s.alembic_pending=nil
   local c=SMODS.create_card{set=G.P_CENTERS[key].set,key=key,area=G.consumeables,skip_materialize=true}
   c:add_to_deck();G.consumeables:emplace(c);c:start_materialize()
  end
  U.save()
 end
 function V.alembic_pending()
  local p=U.state().alembic_pending;if not p then return end
  if p.selected then return V.claim_alembic(p.selected) end
  local entries={};for _,key in ipairs(p.keys) do entries[#entries+1]=U.key_entry(key) end
  U.choose(U.text('Destilación: elige una carta','Distillation: choose one card'),entries,V.claim_alembic)
 end
 function V.transmute(first_id,second_id)
  local s=U.state();local a,b=U.find(first_id),U.find(second_id)
  if not P.normal_shop() or not own('VX03') or s.alembic_used or not U.afford(2) or not a or not b or a==b
   or a.area~=G.consumeables or b.area~=G.consumeables then return end
  local aa,bb=a.ability.set,b.ability.set
  if (aa~='Tarot' and aa~='Planet') or (bb~='Tarot' and bb~='Planet') or (aa~=bb and not own('VX04')) then return end
  local excluded={[a.config.center.key]=true,[b.config.center.key]=true};local sets=own('VX04') and {aa,bb,'Spectral'} or {aa,aa,aa}
  local keys={}
  for _,set in ipairs(sets) do
   local key=U.pick(U.pool(set,excluded),'hz_alembic_'..s.visit)
   if key then keys[#keys+1]=key;excluded[key]=true end
  end
  if #keys==0 then return end
  s.alembic_used=true;s.alembic_pending={keys=keys};ease_dollars(-2,true)
  for _,c in ipairs({a,b}) do c:remove_from_deck();G.consumeables:remove_card(c);c:remove() end
  local m=U.metrics();m.transmutations=(m.transmutations or 0)+1
  U.save();V.alembic_pending()
 end
 function V.alembic()
  local s=U.state();if s.alembic_pending then return V.alembic_pending() end
  if not P.normal_shop() or not own('VX03') or s.alembic_used or not U.afford(2) then return end
  U.choose(U.text('Primer ingrediente · $2 al confirmar','First ingredient · $2 on confirmation'),U.card_entries(consumables()),function(id)
   local a=U.find(id);if not a then return end
   U.choose(U.text('Segundo ingrediente','Second ingredient'),U.card_entries(consumables(id,a)),function(second) V.transmute(id,second) end)
  end)
 end
 G.FUNCS.hz_alembic=V.alembic
 local function movable(c)
  return c and not c.removed and not c.getting_sliced and not c.ability.x48_last_performance
   and not c.ability.exp48_lease and c.sort_id~=G.GAME.incj_options_anchor and not c.ability.hz_anchor
 end
 local function edition(c)
  if not c.edition or c.edition.negative then return end
  if c.edition.foil then return 'e_foil' elseif c.edition.holo then return 'e_holo' elseif c.edition.polychrome then return 'e_polychrome' end
 end
 local function sewing_cards(source)
  local all,out={},{}
  for _,c in ipairs(G.jokers.cards) do all[#all+1]=c end
  if own('VX06') then for _,c in ipairs(G.playing_cards) do all[#all+1]=c end end
  for _,c in ipairs(all) do
   if movable(c) and (source and not c.edition and c~=source or not source and edition(c)) then
    local lineage=source and source.ability.exp48_lineage
    if not lineage or lineage~=c.ability.exp48_lineage then out[#out+1]=c end
   end
  end;return out
 end
 function V.transfer(from,to)
  local s=U.state();local a,b=U.find(from),U.find(to)
  if not P.normal_shop() or not own('VX05') or s.sewing_used or not U.afford(6) or not movable(a) or not movable(b) or b.edition or a==b then return end
  local ed=edition(a);if not ed then return end
  local valid=false;for _,c in ipairs(sewing_cards(a)) do if c==b then valid=true end end;if not valid then return end
  s.sewing_used=true;ease_dollars(-6,true);a:set_edition(nil,true,true);b:set_edition(ed,true,true)
  local m=U.metrics();m.editions_moved=m.editions_moved or {};m.editions_moved[ed]=true
  U.save()
 end
 function V.sewing()
  if not P.normal_shop() or not own('VX05') or U.state().sewing_used or not U.afford(6) then return end
  U.choose(U.text('Donante de Edition · $6','Edition donor · $6'),U.card_entries(sewing_cards()),function(id)
   local c=U.find(id);if not c then return end
   U.choose(U.text('Receptor sin Edition','Uneditioned recipient'),U.card_entries(sewing_cards(c)),function(to) V.transfer(id,to) end)
  end)
 end
 G.FUNCS.hz_sewing=V.sewing
 function V.choose_contract()
  local s=U.state();local pending=s.contract_pending;local C=contract();if not pending or not C then return end
  local entries={}
  for _,id in ipairs(pending.ids) do entries[#entries+1]={id=id,label=localize('k_ct_'..id)} end
  U.choose(U.text('Comparar Contracts','Compare Contracts'),entries,function(id)
   local nodes=C.detail_nodes(C.offer_terms(id))
   nodes[#nodes+1]=P.button(U.text('Elegir esta oferta','Choose this offer'),'hz_contract_choose',id)
   P.open(nodes,'hz_contract_back')
  end)
 end
 G.FUNCS.hz_contract_back=V.choose_contract
 G.FUNCS.hz_contract_choose=function(e)
  local s=U.state();local id=e.config.ref_table;local C=contract();if not s.contract_pending or not C then return end
  for _,key in ipairs(s.contract_pending.ids) do if key==id then
   C.state().offer=id;s.contract_pending=nil;s.replacement_offer=id;U.close();U.save();C.offer(true);return
  end end
 end
 function V.negotiate()
  local s=U.state();if s.contract_pending then return V.choose_contract() end
  local C=contract();local cs=C and C.state()
  if not own('VX07') or not U.shop() or not cs or not cs.offer or s.contract_used or not U.afford(3) then return end
  local pool=eligible_contracts(cs.offer);if #pool==0 then return end
  local ids={};for i=1,math.min(own('VX08') and 2 or 1,#pool) do ids[#ids+1]=U.pick(pool,'hz_contract_'..s.visit) end
  s.contract_used=true;ease_dollars(-3,true);s.contract_pending={ids=ids};cs.offer=nil;U.save();V.choose_contract()
 end
 G.FUNCS.hz_negotiate=V.negotiate
 -- Owned Voucher actions belong in the existing Run Info > Vouchers tab.
 -- Reopening this tab also resumes a paid Alembic choice after cancellation/load.
 local used_vouchers=G.UIDEF.used_vouchers
 function G.UIDEF.used_vouchers(...)
  local ui=used_vouchers(...);local s=U.state()
  if s and P.normal_shop() then
   if s.alembic_pending then
    ui.nodes[#ui.nodes+1]=P.button(U.text('Recoger destilación','Claim distillation'),'hz_alembic')
   elseif own('VX03') and not s.alembic_used then
    ui.nodes[#ui.nodes+1]=P.button(U.text('Alambique · $2','Alembic · $2'),'hz_alembic')
   end
   if own('VX05') and not s.sewing_used then ui.nodes[#ui.nodes+1]=P.button(U.text('Costurero · $6','Sewing Kit · $6'),'hz_sewing') end
  end
  return ui
 end
 H.installers[#H.installers+1]=function()
  local C=contract();if not C then return end
  -- Pending replacement choices rejoin the normal Contract offer flow on load.
  local offer=C.offer
  function C.offer(...)
   local s=U.state()
   if s and s.contract_pending and U.shop() then V.choose_contract();return true end
   return offer(...)
  end
  local accept=C.accept
  function C.accept(...)
   local offered=C.state().offer;local result=accept(...)
   if result and U.state().replacement_offer==offered then local list=C.active();list[#list].hz_replacement=true;U.state().replacement_offer=nil end
   return result
  end
  local present=C.present_offer
  function C.present_offer(...)
   present(...)
   if own('VX07') and not U.state().contract_used and #eligible_contracts(C.state().offer)>0 and G.OVERLAY_MENU then
    -- Keep Second Opinion with the Contract's own accept/decline actions.
    G.OVERLAY_MENU:add_child(P.button(U.text('Segunda opinión · $3','Second Opinion · $3'),'hz_negotiate'),G.OVERLAY_MENU.UIRoot)
   end
  end
 end
 local function count(t) return X.count(t) end
 H.on(function(c)
  local s=U.state();if not s then return end;local m=U.metrics()
  if c.open_booster then s.open_pack_kind=c.card and c.card.config.center.kind;s.open_pack_taken=false end
  if c.buying_card and c.card and c.card.area==G.pack_cards then s.open_pack_taken=true end
  if c.using_consumeable and c.consumeable then
   if c.area==G.pack_cards then s.open_pack_taken=true end
   if U.shop() or G.TAROT_INTERRUPT==G.STATES.SHOP and not G.GAME.PACK_INTERRUPT and G.shop and not H.state().extra_shop then
    m.shop_uses=m.shop_uses or {};m.shop_uses[s.visit]=m.shop_uses[s.visit] or {}
    local card=c.consumeable;if card.ability.set=='Tarot' or card.ability.set=='Planet' then m.shop_uses[s.visit][card.config.center.key]=true end
    if count(m.shop_uses[s.visit])>=6 then m.alembic_ready=true end
   end
  end
  if c.ending_booster and s.open_pack_taken then
   m.packs_taken=(m.packs_taken or 0)+1;m.pack_families=m.pack_families or {};if s.open_pack_kind then m.pack_families[s.open_pack_kind]=true end
  end
  if c.exp48_selling and c.card.ability.set=='Joker' then
   local ed=edition(c.card);if ed then m.editions_sold=m.editions_sold or {};m.editions_sold[ed]=true end
  end
  if c.exp48_contract_result then
   if not c.success then m.contract_failed=true else
    m.contracts=m.contracts or {};m.contracts[c.contract.id]=true
    if c.contract.hz_replacement then m.replacement_wins=(m.replacement_wins or 0)+1 end
   end
  end
  if c.exp48_blind_paid then
   local ante=G.GAME.round_resets.ante;local boss=G.GAME.blind.boss
   if ante>=6 and m.alembic_ready then H.unlock('VX03') end
   if boss and ante>=6 then
    if (m.packs_taken or 0)>=5 and count(m.pack_families)>=3 then H.unlock('VX01') end
    if count(m.editions_sold)>=3 then H.unlock('VX05') end
    if s.history_complete and count(m.contracts)>=4 and not m.contract_failed then H.unlock('VX07') end
   end
   if boss and ante>=8 then
    if own('VX03') and (m.transmutations or 0)>=3 then H.unlock('VX04') end
    if own('VX05') and count(m.editions_moved)>=2 then H.unlock('VX06') end
   end
  end
 end)
 local win=win_game
 function win_game(...)
  local s=U.state();local m=s and s.metrics
  if m then
   if own('VX01') and count(m.pack_replacements)>=3 then H.unlock('VX02') end
   if own('VX07') and (m.replacement_wins or 0)>=3 then H.unlock('VX08') end
  end
  return win(...)
 end
end
