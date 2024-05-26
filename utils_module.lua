-- local Token_module = require("Token_module")
-- local Proposals_module = require('Proposals_module')
local ao = require("ao")

Utils_module = Utils_module or {}
Utils_module.Subscribers = Utils_module.Subscribers or {}

function Utils_module.getTotalSupply()
    local totalSupply = 0

    -- Sum balances from Token_module.Balances
    for _, balance in pairs(Token_module.Balances) do
        totalSupply = totalSupply + balance
    end

    -- Iterate over each proposal in Proposals_module.proposals
    for _, proposal in pairs(Proposals_module.proposals) do
        -- Iterate over each voter's votes within the proposal
        for _, voterVotes in pairs(proposal.votes) do
            totalSupply = totalSupply + (tonumber(voterVotes.yay) or 0) + (tonumber(voterVotes.nay) or 0)
        end
    end
    print("Total token supply fetched: " .. tostring(totalSupply))
    return totalSupply
end

function Utils_module.addSubscriber(msg)
    local isAlreadySubscriber = false
    for _, subscriber in ipairs(Utils_module.Subscribers) do
        if subscriber == msg.From then
            isAlreadySubscriber = true
            break
        end
    end

    if not isAlreadySubscriber then
        table.insert(Utils_module.Subscribers, msg.From)
        print("Added " .. msg.From .. " to the subsciber list.")
    end
end

function Utils_module.removeSubscriber(msg)
    for i, subscriber in ipairs(Utils_module.Subscribers) do
        if subscriber == msg.From then
            table.remove(Utils_module.Subscribers, i)
            print("Removed " .. " from the subscriber list.")
            break
        end
    end
end

function Utils_module.announce(announcement)
    for _, subscriber in ipairs(Utils_module.Subscribers) do
        ao.send({ Target = subscriber, Action = "KARDAnnouncement", Data = announcement })
    end
    print("Announcement sent: " .. announcement)
end


return Utils_module
