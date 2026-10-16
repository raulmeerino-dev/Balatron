local P=PortraitGameplay
local C=P.register(SMODS.current_mod)
C.mod.config.execution_cards=2;C.mod.config.execution_reward=15
assert(SMODS.load_file('core.lua'))()(C,P)
for _,d in ipairs(assert(SMODS.load_file('contracts.lua'))()) do C.register(d) end
assert(SMODS.load_file('expansion_text.lua'))()(C)
assert(SMODS.load_file('expansion.lua'))()(C,P)
assert(SMODS.load_file('ui.lua'))()(C)
C.mod.calculate=function(_,context) C.track(context) end
function C.offer(force)
    local s=C.state();if not s.offer or C.shown_offer==s and not force then return end
    -- An unresolved offer reopens after restart, preserving its RNG result.
    C.shown_offer=s
    C.present_offer(s.offer,true);save_run();return true
end
G.FUNCS.ct_accept=function() C.accept();G.FUNCS.exit_overlay_menu();save_run();P.schedule_offers() end
G.FUNCS.ct_decline=function() C.state().offer=nil;G.FUNCS.exit_overlay_menu();save_run();P.schedule_offers() end
G.FUNCS.ct_claim=function()
    local s=C.state()
    if (s.pending_spectral or 0)>0 and P.reward_card('Spectral',nil,'contract_claim') then
        s.pending_spectral=s.pending_spectral-1;save_run()
    end
    if PortraitRunGallery then PortraitRunGallery.open() else C.run_info() end
end
function C.run_info()
    local s=C.state()
    if s.offer then return C.offer(true) end
    if PortraitRunGallery then return PortraitRunGallery.open('contract') end
    local nodes={P.text(localize('k_contracts'),0.42)}
    for _,a in ipairs(C.active()) do
        nodes[#nodes+1]=C.heading(a.id);P.append(nodes,C.detail_nodes(a))
    end
    if #C.active()==0 then nodes[#nodes+1]=P.text(localize('k_pg_none')) end
    if (s.pending_spectral or 0)>0 then nodes[#nodes+1]=P.button(localize('b_ct_claim'),'ct_claim') end
    P.open(nodes)
end
assert(SMODS.load_file('expansion_rewards.lua'))()(C,P)
assert(SMODS.load_file('expansion_ui.lua'))()(C,P)
