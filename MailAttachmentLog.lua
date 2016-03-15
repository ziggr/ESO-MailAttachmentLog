local MailAttachmentLog = {}
MailAttachmentLog.name            = "MailAttachmentLog"
MailAttachmentLog.version         = "2.3.5.1"
MailAttachmentLog.savedVarVersion = 1
MailAttachmentLog.default = {
      history = {}
}

-- MailRecord ----------------------------------------------------------------

local MailRecord = {}

function MailRecord:FromMailId(mail_id)
    from_user,_, subject,_,_,_,_,_, attach_ct, attach_gold,
         _,_, since_secs = GetMailItemInfo(mail_id)

    o = { mail_id   = mail_id
        , from      = from_user
        , subject   = subject
        , gold      = attach_gold
        , attach_ct = attach_ct
        , ts        = GetTimeStamp() - since_secs
        }
    setmetatable(o, self)
    self.__index = self
    o:LoadAttachments()
    return o
end
--
function MailRecord:LoadAttachments()
    for i = 1, self.attach_ct do
          icon
        , stack
        , creatorName
        , sellPrice
        , meetsUsageRequirement
        , equipType
        , itemStyle
        , quality
           = GetAttachedItemInfo(self.mail_id, i)
        -- d("mail_id:"                 ..tostring(self.mail_id)
        -- .." i:"                      ..i
        -- .." icon: "                  ..tostring(icon)
        -- .." stack: "                 ..tostring(stack)
        -- .." creatorName: "           ..tostring(creatorName)
        -- .." sellPrice: "             ..tostring(sellPrice)
        -- .." meetsUsageRequirement: " ..tostring(meetsUsageRequirement)
        -- .." equipType: "             ..tostring(equipType)
        -- .." itemStyle: "             ..tostring(itemStyle)
        -- .." quality: "               ..tostring(quality)
        -- )
        ct = stack
        if 0 == ct then
            self:WarnMissing()
            return
        end
        link = GetAttachedItemLink(self.mail_id, i, LINK_STYLE_DEFAULT)
        name = zo_strformat("<<t:1>>", GetItemLinkName(link))
        if not self.attach then
            self.attach = {}
        end
        self.attach[i] = { ct   = ct
                         , link = link
                         , name = name
                         }
        mm = self:MMPrice(link)
        if mm then
            self.attach[i].mm = mm
        end
    end
end

function MailRecord:ToString()
    return "from:"     ..tostring(self.from)
        .." subject:"  ..tostring(self.subject)
        .." attach_ct:"..tostring(self.attach_ct)
end

function MailRecord:WarnMissing()
    d("Please load attachment data by viewing mail: "..self.subject)
end

-- Master Merchant Integration -----------------------------------------------


function MailRecord:MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    d("MM for link: "..tostring(link).." "..tostring(mm.avgPrice))
    return mm.avgPrice
end

-- Init ----------------------------------------------------------------------

function MailAttachmentLog.OnAddOnLoaded()
    if addonName ~= MailAttachmentLog.name then return end
    MailAttachmentLog:Initialize()
end

function MailAttachmentLog:Initialize()
    --
end

-- Do It ---------------------------------------------------------------------

function MailAttachmentLog:DoIt()
    -- d(":DoIt")
    history = {}
    mail_id = GetNextMailId(nil)
    while mail_id do
        mr = MailRecord:FromMailId(mail_id)
        d(mr:ToString())
        table.insert(history, mr)
        mail_id = GetNextMailId(mail_id)
    end
    self:Save(history)
end

function MailAttachmentLog_DoIt()
    -- d("_DoIt")
    MailAttachmentLog:DoIt()
end

function MailAttachmentLog:Save(history)
    -- d("saving " ..tostring(#history).. " mail record(s)..." )
    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "MailAttachmentLogVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    self.savedVariables.history = history
    h = self.savedVariables.history
    d(self.name .. ": saved " ..tostring(#h).. " mail record(s)." )
end



-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( MailAttachmentLog.name
                              , EVENT_ADD_ON_LOADED
                              , MailAttachmentLog.OnAddOnLoaded
                              )

ZO_CreateStringId("SI_BINDING_NAME_MailAttachmentLog_DoIt", "Record Mail Attachments")

--[[
1. Get a hot key hooked up
2. Iterate through mail
3. Pick an export data format
4. Define an "Mail" struct
5. Integrate with M.M.


hvy Mace   etc
lgt chest  htc
med hands  etc
med chest  etc
wood resto etc

]]
