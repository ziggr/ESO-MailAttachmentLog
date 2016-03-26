local MailAttachmentLog = {}
MailAttachmentLog.name            = "MailAttachmentLog"
MailAttachmentLog.version         = "2.3.5.1"
MailAttachmentLog.savedVarVersion = 1
MailAttachmentLog.history         = {}  -- mail_id ==> MailRecord
MailAttachmentLog.default = {
      history = {}
}

-- MailRecord ----------------------------------------------------------------

local MailRecord = {}

function MailRecord:FromMailId(mail_id)
    o = { mail_id   = mail_id
        , mail_id_s = tostring(mail_id)
        }
    setmetatable(o, self)
    self.__index = self
    return o
end

function MailRecord:GetHeader()
    from_user,_, subject,_,_,_,_,_, attach_ct, attach_gold,
         _,_, since_secs = GetMailItemInfo(mail_id)
    self.from      = from_user
    self.subject   = subject
    self.gold      = attach_gold
    self.attach_ct = attach_ct
    self.ts        = GetTimeStamp() - since_secs
end

function MailRecord:GetBody()
    self.body = ReadMail(self.mail_id)
end

function MailRecord:GetAttachments()
    --d("att "..tostring(self.mail_id).. " ct="..tostring(self.attach_ct))
    if 0 == self.attach_ct then return end
    for i = 1, self.attach_ct do
        _, stack = GetAttachedItemInfo(self.mail_id, i)
        ct = stack
        if 0 == ct then
            d("att missing "..tostring(self.mail_id))
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
    --d("att loaded "..tostring(self.mail_id).. " ct="..tostring(#self.attach))
end

function MailRecord:Load()
    self:GetHeader()
    self:GetBody()
    self:GetAttachments()
end

-- Master Merchant Integration -----------------------------------------------

function MailRecord:MMPrice(link)
    if not MasterMerchant then return nil end
    if not link then return nil end
    mm = MasterMerchant:itemStats(link, false)
    if not mm then return nil end
    --d("MM for link: "..tostring(link).." "..tostring(mm.avgPrice))
    return mm.avgPrice
end

-- Init ----------------------------------------------------------------------

function MailAttachmentLog.OnAddOnLoaded()
    if addonName ~= MailAttachmentLog.name then return end
    MailAttachmentLog:Initialize()
end

function MailAttachmentLog:Initialize()
    -- so far nothing to init
end

-- Do It ---------------------------------------------------------------------

function MailAttachmentLog:DoIt()
    -- d(":DoIt")

    self.history = {}

                        -- Rather than register/unregister over and over as we
                        -- iterate through mail, just register once at the
                        -- start and unregister once at the end.
    self:Register()

    self:FetchStart()

end

function MailAttachmentLog_DoIt()
    -- d("_DoIt")
    MailAttachmentLog:DoIt()
end

-- Start fetching all mail messages and their attachments.
-- It's an async fetch/callback/next cycle not a for-loop.
function MailAttachmentLog:FetchStart()
    self:FetchNext(nil)
end

function MailAttachmentLog:FetchNext(prev_mail_id)
                        -- Increment iteration.
    mail_id = GetNextMailId(prev_mail_id)
    if not mail_id then
        --d("fn done")
        self:FetchDone()
        return
    end

    if not self.history[mail_id] then
                        -- Haven't yet fetched this one.
        self.history[mail_id] = "requesting..."
        RequestReadMail(mail_id)
        --d("fn waiting " ..tostring(mail_id))
        return
    end
                        -- Already requested this one.
                        -- Move on to the next mail (if any).
    --d("fn skip repeat " ..tostring(mail_id))
    self:FetchNext(mail_id)
end

-- Resume from FetchNext()'s async server request for attachment data.
function MailAttachmentLog.OnMailReadable(event_id, mail_id)
    self = MailAttachmentLog
    --d("omr " .. tostring(mail_id))
    mr = MailRecord:FromMailId(mail_id)
    mr:Load()
    self.history[mail_id] = mr
    self:FetchNext(mail_id)
end

-- Done fetching all mail messages and their attachments.
function MailAttachmentLog:FetchDone()
    self:Unregister()
    self:Save()
end

function MailAttachmentLog:Save()
    -- d("saving " ..tostring(#history).. " mail record(s)..." )
    self.savedVariables = ZO_SavedVars:NewAccountWide(
                              "MailAttachmentLogVars"
                            , self.savedVarVersion
                            , nil
                            , self.default
                            )
    h = {}
    for mail_id_s,mr in pairs(self.history) do
        table.insert(h, mr)
    end
    self.savedVariables.history = h
    d(self.name .. ": saved " ..tostring(#h).. " mail record(s)." )
end

function MailAttachmentLog:Register()
    --d("reg")
    EVENT_MANAGER:RegisterForEvent( self.name
                                  , EVENT_MAIL_READABLE
                                  , MailAttachmentLog.OnMailReadable )
end

function MailAttachmentLog:Unregister()
    --d("unreg")
    EVENT_MANAGER:UnregisterForEvent( self.name
                                    , EVENT_MAIL_READABLE )
end

-- util ----------------------------------------------------------------------

function table_size(t)
    local i = 0
    for k in pairs(t) do
        i = i + 1
    end
    return i
end

-- Postamble -----------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent( MailAttachmentLog.name
                              , EVENT_ADD_ON_LOADED
                              , MailAttachmentLog.OnAddOnLoaded
                              )

ZO_CreateStringId("SI_BINDING_NAME_MailAttachmentLog_DoIt", "Record Mail Attachments")



--[[

Need either:
-- check if mailbox UI is open, if not, barf an error and refuse to start.
-- request to open the mailbox ui, wait for it to open, then start.
]]
