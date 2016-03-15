local MailAttachmentLog = {}
MailAttachmentLog.name            = "MailAttachmentLog"
MailAttachmentLog.version         = "2.3.5.1"
MailAttachmentLog.savedVarVersion = 1
MailAttachmentLog.history         = {}
MailAttachmentLog.current_mr      = nil     -- MailRecord
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
    return o
end

-- Record attachment data if already available.
-- Return true if all attachments recorded (also if 0 attachments)
-- Return false if attachments not yet ready. Request sent.
function MailRecord:LoadAttachments()
    if 0 == self.attach_ct then return true end

    for i = 1, self.attach_ct do
        _, stack = GetAttachedItemInfo(self.mail_id, i)
        ct = stack
        if 0 == ct then
            d("la missing "..tostring(self.mail_id))
            self:RequestAttachments()
            return false
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
    d("la loaded "..tostring(self.mail_id).. " ct="..tostring(#self.attach))
    return true
end

function MailRecord:RequestAttachments()
    d("ra requesting " .. tostring(self.mail_id))
    RequestReadMail(self.mail_id)
end

function MailRecord:ToString()
    return "from:"     ..tostring(self.from)
        .." subject:"  ..tostring(self.subject)
        .." attach_ct:"..tostring(self.attach_ct)
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
    -- so far nothing to init
end

-- Do It ---------------------------------------------------------------------

function MailAttachmentLog:DoIt()
    -- d(":DoIt")

    self.history = {}

                        -- Rather than register/deregister over and over as we
                        -- iterate through mail, just register once at the
                        -- start and deregister once at the end.
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
        d("fn done")
        self:FetchDone()
    end
                        -- Do one cycle: load mail into a struct.
                        -- Attempt to load attachment data, too, but
                        -- that usually requires an async server request.
    mr = MailRecord:FromMailId(mail_id)
    self.current_mr = mr
    table.insert(self.history, mr)
    fetched = mr:LoadAttachments()

                        -- Usually we'll suspend here and resume in
                        -- OnMailReadable().
    if not fetched then
        d("fn waiting " ..tostring(mr.mail_id))
        return
    end

                        -- If mail already fetched from server, then
                        -- tail-recurse to the next message.
    d("fn leaving " ..tostring(mr.mail_id))
    self:FetchNext(mail_id)
end

-- Resume from FetchNext()'s async server request for attachment data.
function MailAttachmentLog.OnMailReadable(event_id, mail_id)
    self = MailAttachmentLog
    d("omr " .. tostring(mail_id))
    if not self.current_mr then
        d("omr no  current_mr")
        return
    end
    mr = self.current_mr
    if mail_id ~= mr.mail_id then
        d("omr not current_mr " .. tostring(mr.mail_id))
        return
    end
    fetched = mr:LoadAttachments()
    if not fetched then
        d("omr load-after-async fetch still waiting?")
        return
    end
    self:FetchNext(mr.mail_id)
end

-- Done fetching all mail messages and their attachments.
function MailAttachmentLog:FetchDone()
    self:Deregister()
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
    self.savedVariables.history = self.history
    h = self.savedVariables.history
    d(self.name .. ": saved " ..tostring(#h).. " mail record(s)." )
end

function MailAttachmentLog:Register()
    EVENT_MANAGER:RegisterForEvent( self.name
                                  , EVENT_MAIL_READABLE
                                  , MailAttachmentLog.OnMailReadable )
end

function MailAttachmentLog:Deregister()
    EVENT_MANAGER:RegisterForEvent( self.name
                                  , EVENT_MAIL_READABLE )
end


-- util ----------------------------------------------------------------------

function table_is_empty(t)
    for k in ipairs(t) do
        return false
    end
    return true
end

function table_size(t)
    i = 0
    for k in ipairs(t) do
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
