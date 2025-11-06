-- 2-bigger_dogear.lua
-- Increases the bookmark (dog-ear) icon size in KOReader with customizable multiplier
-- Place this file in: /koreader/patches/
-- Restart KOReader after copying the file

local Device = require("device")
local logger = require("logger")
local _ = require("gettext")
local T = require("ffi/util").template

-- Bigger Dogear Module
local BiggerDogear = {
    setting_name = "dogear_size_multiplier",
    default_multiplier = 3.0,
}

function BiggerDogear:getMultiplier()
    return G_reader_settings:readSetting(self.setting_name, self.default_multiplier)
end

function BiggerDogear:setMultiplier(value)
    G_reader_settings:saveSetting(self.setting_name, value)
end

function BiggerDogear:applyPatch()
    local ReaderDogear = require("apps/reader/modules/readerdogear")
    
    -- Store original functions if not already stored
    if not ReaderDogear._original_onSetPageMargins then
        ReaderDogear._original_onSetPageMargins = ReaderDogear.onSetPageMargins
    end
    if not ReaderDogear._original_init then
        ReaderDogear._original_init = ReaderDogear.init
    end
    
    local multiplier = self:getMultiplier()
    
    -- Override onSetPageMargins for EPUB/ebook documents
    ReaderDogear.onSetPageMargins = function(dogear_self, margins)
        if not dogear_self.ui.rolling then
            return
        end
        
        local Screen = Device.screen
        local margin_top, margin_right = margins[2], margins[3]
        local margin = Screen:scaleBySize(math.max(margin_top, margin_right))
        
        -- Apply custom multiplier to the dogear size calculation
        local new_dogear_size = multiplier * math.min(dogear_self.dogear_max_size, math.max(dogear_self.dogear_min_size, margin))
        
        dogear_self:setupDogear(new_dogear_size)
        
        logger.dbg("BiggerDogear: Dog-ear size set to:", new_dogear_size, "with multiplier:", multiplier)
    end
    
    -- Override init for PDF documents
    ReaderDogear.init = function(dogear_self)
        ReaderDogear._original_init(dogear_self)
        
        -- For PDF documents (non-rolling), multiply the max size
        if not dogear_self.ui or not dogear_self.ui.rolling then
            dogear_self.dogear_max_size = dogear_self.dogear_max_size * multiplier
            dogear_self:setupDogear(dogear_self.dogear_max_size)
            logger.dbg("BiggerDogear: Dog-ear max size set to:", dogear_self.dogear_max_size, "for PDF")
        end
    end
    
    logger.info("BiggerDogear: Patch applied with multiplier:", multiplier)
end

function BiggerDogear:getMenu()
    return {
        text_func = function()
            return T(_("Dog-ear size: %1x"), string.format("%.1f", self:getMultiplier()))
        end,
        keep_menu_open = true,
        callback = function()
            local SpinWidget = require("ui/widget/spinwidget")
            local UIManager = require("ui/uimanager")
            
            local spin_widget = SpinWidget:new{
                value = self:getMultiplier(),
                value_min = 1.0,
                value_max = 10.0,
                value_step = 0.1,
                value_hold_step = 0.5,
                precision = "%.1f",
                title_text = _("Dog-ear size multiplier"),
                info_text = _("Multiply the bookmark icon size by this factor.\nDefault is 3.0x. Restart required after changing."),
                callback = function(spin)
                    self:setMultiplier(spin.value)
                    UIManager:askForRestart()
                end,
            }
            UIManager:show(spin_widget)
        end,
    }
end

-- Initialize the patch
BiggerDogear:applyPatch()

-- Add menu to FileManager and Reader
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local ReaderMenu = require("apps/reader/modules/readermenu")

local function addMenu(menu, order)
    if not menu.menu_items.dogear_size then
        table.insert(order.setting, "dogear_size")
        menu.menu_items.dogear_size = BiggerDogear:getMenu()
    end
end

local orig_FileManagerMenu_setUpdateItemTable = FileManagerMenu.setUpdateItemTable
function FileManagerMenu:setUpdateItemTable()
    addMenu(self, require("ui/elements/filemanager_menu_order"))
    orig_FileManagerMenu_setUpdateItemTable(self)
end

local orig_ReaderMenu_setUpdateItemTable = ReaderMenu.setUpdateItemTable
function ReaderMenu:setUpdateItemTable()
    addMenu(self, require("ui/elements/reader_menu_order"))
    orig_ReaderMenu_setUpdateItemTable(self)
end

logger.info("BiggerDogear patch loaded successfully with multiplier:", BiggerDogear:getMultiplier())
