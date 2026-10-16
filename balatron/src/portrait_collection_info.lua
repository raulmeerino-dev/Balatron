-- A small modal over the existing Collection; its UI and page stay alive.
local I={}
local function strings()
    local lang=(G.SETTINGS.language or ''):sub(1,2)=='es' and 'es_ES' or 'en-us'
    if I.language~=lang or I.localization~=G.localization then
        G.localization.misc.dictionary.pc_category_help=assert(love.filesystem.load(
            'assets/localization/collection_info/'..lang..'.lua'))()
        I.language=lang;I.localization=G.localization
    end
    return localize('pc_category_help')
end
function I.button(kind)
    return {n=G.UIT.C,config={align='cm',padding=0.03},nodes={
        {n=G.UIT.C,config={align='cm',minw=portrait_touch_height(0.75),minh=portrait_touch_height(0.8),
            colour=G.C.GREY,r=0.12,hover=true,button='pc_category_info',ref_table=kind},nodes={
            {n=G.UIT.T,config={text='i',scale=0.38,colour=G.C.WHITE,shadow=true}}}}}}
end
local function lock_frame()
    G.CONTROLLER:cancel_pointer_interaction()
    G.CONTROLLER.locks.frame_set=true;G.CONTROLLER.locks.frame=true
end
function I.close()
    local modal=G.OVERLAY_MENU
    if not (modal and modal.pc_collection_underlay) then return end
    local original=modal.pc_collection_underlay
    original.parent=modal.pc_original_parent
    modal.pc_collection_underlay=nil
    G.OVERLAY_MENU=original
    modal:remove()
    lock_frame()
end
function I.open(kind)
    local data=strings()[kind]
    if not data then return end
    local width=math.min(8.5,G.ROOM.T.w-0.8)
    local nodes={{n=G.UIT.R,config={align='cm',padding=0.1,maxw=width-0.4},nodes={
        {n=G.UIT.T,config={text=data.title,scale=0.46,colour=G.C.GOLD,shadow=true}}}}}
    for _,line in ipairs(data.text) do
        if line=='' then
            nodes[#nodes+1]={n=G.UIT.R,config={minh=0.16},nodes={}}
        else
            for _,wrapped in ipairs(PortraitRunGallery.wrap({line},40)) do
                nodes[#nodes+1]={n=G.UIT.R,config={align='cm',padding=0.025,maxw=width-0.4},nodes={
                    {n=G.UIT.T,config={text=wrapped,scale=0.36,colour=G.C.WHITE,shadow=true}}}}
            end
        end
    end
    nodes[#nodes+1]=UIBox_button{label={data.close},button='pc_category_info_close',minw=3,
        minh=portrait_touch_height(0.85),scale=0.4,colour=G.C.RED}
    return I.show(nodes,width)
end
-- Shared Collection shell: detail views preserve the exact underlying page.
function I.show(nodes,width)
    local original=G.OVERLAY_MENU
    if not original or original.pc_collection_underlay then return end
    PortraitRunGallery.dismiss()
    width=width or math.min(8.5,G.ROOM.T.w-0.8)
    local modal=UIBox{definition={n=G.UIT.ROOT,config={align='cm',minw=G.ROOM.T.w,minh=G.ROOM.T.h,
        colour={0,0,0,0.4},button='pc_category_info_close'},nodes={
        {n=G.UIT.C,config={align='cm',padding=0.2,minw=width,maxw=width,r=0.16,
            colour=G.C.L_BLACK,outline=1,outline_colour=G.C.GREY,emboss=0.08,
            button='pc_category_info_body'},nodes=nodes}}},
        config={portrait_panel=true,align='cm',major=G.ROOM_ATTACH,offset={x=0,y=0}}}
    modal.pc_collection_underlay=original;modal.pc_original_parent=original.parent
    original.parent=modal -- Do not also draw it as a loose, top-level UIBox.
    local draw,remove=modal.draw,modal.remove
    function modal:draw()
        if self.pc_collection_underlay then
            self.pc_collection_underlay:draw()
            -- Collection's red discovery badges normally draw above overlays.
            -- Draw them with their own page first; the native frame guard then
            -- keeps them behind this modal without altering discovery state.
            for _,alert in ipairs(G.I.ALERT) do
                local major=alert.role and alert.role.major
                if major and major.UIBox==self.pc_collection_underlay then alert:draw() end
            end
        end
        draw(self)
    end
    function modal:remove()
        -- Changing scene while open must not leave the suspended UI behind.
        if self.pc_collection_underlay then self.pc_collection_underlay:remove();self.pc_collection_underlay=nil end
        remove(self)
    end
    G.OVERLAY_MENU=modal
    lock_frame()
end
function I.install()
    if I.installed then return end;I.installed=true
    G.FUNCS.pc_category_info=function(e) I.open(e.config.ref_table) end
    G.FUNCS.pc_category_info_close=I.close
    G.FUNCS.pc_category_info_body=function() end
    local exit=G.FUNCS.exit_overlay_menu
    G.FUNCS.exit_overlay_menu=function(...)
        if G.OVERLAY_MENU and G.OVERLAY_MENU.pc_collection_underlay then return I.close() end
        return exit(...)
    end
end
return I
