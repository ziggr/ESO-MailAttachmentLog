-- Read the SavedVariables file that MailAttachmentLog creates  and convert
-- that to a spreadsheet-compatible CSV (comma-separated value) file
-- suitable for usin in our auctions.

IN_FILE_PATH  = "../../SavedVariables/MailAttachmentLog.lua"
OUT_FILE_PATH = "../../SavedVariables/MailAttachmentLog_auction.csv"
dofile(IN_FILE_PATH)
OUT_FILE = assert(io.open(OUT_FILE_PATH, "w"))

local TOTAL_GOLD = 0
local MAX_ITEM_CT_PER_LINE = 4

                        -- How many seconds between email messages from
                        -- the same donor counts as "part of the same lot" ?
                        --
                        -- 10 * 60 = ten minutes, probably too long
                        --  1 * 60 = one minute, probably too short
                        --
                        -- Set this too low and you'll have to manually merge
                        -- some lots in Google Sheets.
                        -- Set this too high and you'll have to manually split
                        -- some lots.
                        --
local MIN_CONTINUATION_SECS = 10*60

-- Lua lacks a split() function. Here's a cheesy hardwired one that works
-- for our specific need.
function split(str)
    t1 = string.find(str, '\t')
    t2 = string.find(str, '\t', 1 + t1)
    return   string.sub(str, 1,      t1 - 1)
           , string.sub(str, 1 + t1, t2 - 1)
           , string.sub(str, 1 + t2)
end

-- Sort incoming mail by donor, then time.
-- By donor helps avoid rare cases where two donors send multi-message
-- lots at the same time, intermingling their messages. By time then
-- groups multi-message lots together in history.
function MessageLessThan(a, b)
    if not (a and a.from and a.ts) then return b end
    if not (b and b.from and b.ts) then return a end
    if a.from < b.from then
        return true
    elseif a.from == b.from then
        return (a.ts < b.ts )
    else
        return false
    end
end

-- Does curr_msg appear to be a continuation of prev_msg?
function IsContinuation(prev_msg, curr_msg)
    return false -- 2017-08-15 continuation is dropping rows
    -- if not prev_msg then return false end
    -- if prev_msg.from ~= curr_msg.from then return false end
    -- local msg_delta_secs = math.abs(curr_msg.ts - prev_msg.ts)
    -- if MIN_CONTINUATION_SECS < msg_delta_secs then
    --     return false
    -- end
    -- return true
end

-- Copy attachments from second-or-later message to first message
function MergeOneLot(prev_msg, curr_msg)
    for _, att in ipairs(curr_msg.attach) do
        table.insert(prev_msg.attach, att)
    end
end

-- Combine multiple adjacent messages from the same sender if they
-- are within MIN_CONTINUATION_SECS
function MergeLots(history)
    local merged_history = {}
    local prev_msg = nil
    for _, curr_msg in ipairs(history) do
        if IsContinuation(prev_msg, curr_msg) then
            MergeOneLot(prev_msg, curr_msg)
        else
            table.insert(merged_history, curr_msg)
        end
        prev_msg = curr_msg
    end
    return merged_history
end

-- Parse the ["history'] table
function TableHistory(history)
    table.sort(history, MessageLessThan)
    local merged_history = MergeLots(history)
    for _, msg in ipairs(merged_history) do
        Message(msg)
    end
end

function merge_stacks(att_table)
    local merged_table = {}
    local did_merge    = false
    for _, att in ipairs(att_table) do
        local link = att.link
        if not merged_table[link] then
            merged_table[link] = att
        else
            merged_table[link].ct = merged_table[link].ct + att.ct
            did_merge = true
        end
    end
                        -- No point in wasting time flattening to produce
                        -- the very same thing we got as input, re-sequenced.
    if not did_merge then return att_table end

    local flattened = {}
    for _, att in pairs(merged_table) do
        table.insert(flattened, att)
    end
    return flattened
end

-- Parse one email message and its attachments
function Message(msg)
    date_str = iso_date(msg.ts)

    TOTAL_GOLD = TOTAL_GOLD + msg.gold
    if not msg.attach then return end
    local msg_attach = merge_stacks(msg.attach)
    local att_list = {}
    for _, att in ipairs(msg_attach) do
        table.insert(att_list, att)
        if MAX_ITEM_CT_PER_LINE <= #att_list then
            WriteLine{ donor    = msg.from
                     , att_list = att_list
                     }
            att_list = {}
        end
    end
    if 0 < #att_list then
            WriteLine{ donor    = msg.from
                     , att_list = att_list
                     }
            att_list = {}
    end
end

function string_concat(delimiter, a, b)
    if a == "" then return b end
    if b == "" then return a end
    return a .. delimiter .. b
end

function prepend_ct(ct, delimiter, s)
    if ct <= 1 then return s end
    return tostring(ct) .. delimiter .. s
end


-- Write a line to output file.
function WriteLine(args)
    local name_str = ""
    local link_str = ""
    for _, att in ipairs(args.att_list) do
                        -- We like brackets, so force them with H1.
        local link_h1 = att.link:gsub("|H0:", "|H1:")
        local link    = prepend_ct(att.ct, "x", link_h1)
        local name    = prepend_ct(att.ct, " ", att.name)
        link_str      = string_concat(" " , link_str, link)
        name_str      = string_concat(", ", name_str, name)
    end

    -- date_str, sender, value_gold, item_name, item_link)
    s = string.format( '"%s",,,,,"%s","%s"\n'
                     , args.donor
                     , name_str
                     , "Donated by "..args.donor.." "..link_str
                     )
    OUT_FILE:write(s)

    -- date_str, sender, value_gold, item_name, item_link)
    t = string.format( '%s\t\t\t\t\t%s\t%s'
                     , args.donor
                     , name_str
                     , "Donated by "..args.donor.." "..link_str
                     )
    print(t)
end

-- Return table keys, sorted, as an array
function sorted_keys(tabl)
    keys = {}
    for k in pairs(tabl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

function enquote(s)
    return '"' .. s .. '"'
end

function round(fp)
                        -- Assumes positive inputs only.
                        -- Does not toggle even/odd 0.5 up/down.
                        -- Fine. Not that important to me.
    return math.floor(fp + 0.5)
end

-- Convert "1456709816" to "2016-02-28T17:36:56" ISO 8601 formatted time
-- Assume "local machine time" and ignore any incorrect offsets due to
-- Daylight Saving Time transitions. Ugh.
function iso_date(secs_since_1970)
    t = os.date("*t", secs_since_1970)
    return string.format("%04d-%02d-%02dT%02d:%02d:%02d"
                        , t.year
                        , t.month
                        , t.day
                        , t.hour
                        , t.min
                        , t.sec
                        )
end

-- For each account
-- for k, v in pairs(MailAttachmentLogVars["Default"]) do
--     if (    MailAttachmentLogVars["Default"][k]["$AccountWide"]
--         and MailAttachmentLogVars["Default"][k]["$AccountWide"]["history"]) then
--         TableHistory(MailAttachmentLogVars["Default"][k]["$AccountWide"]["history"])
--     end
-- end

-- for just ETCAuctions
TableHistory(MailAttachmentLogVars["Default"]["@ETCAuctions"]["$AccountWide"]["history"])

OUT_FILE:close()


