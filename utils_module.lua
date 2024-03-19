-- local token_module = require("token_module")
-- local proposals_module = require('proposals_module')
local ao = require("ao")

utils_module = utils_module or {}
utils_module.Subscribers = utils_module.Subscribers or {}

function utils_module.getTotalSupply()
    local totalSupply = 0

    -- Sum balances from token_module.Balances
    for _, balance in pairs(token_module.Balances) do
        totalSupply = totalSupply + balance
    end

    -- Iterate over each proposal in proposals_module.proposals
    for _, proposal in pairs(proposals_module.proposals) do
        -- Iterate over each voter's votes within the proposal
        for _, voterVotes in pairs(proposal.votes) do
            totalSupply = totalSupply + (tonumber(voterVotes.yay) or 0) + (tonumber(voterVotes.nay) or 0)
        end
    end

    return totalSupply
end

function utils_module.addSubscriber(msg)
    local isAlreadySubscriber = false
    for _, subscriber in ipairs(utils_module.Subscribers) do
        if subscriber == msg.From then
            isAlreadySubscriber = true
            break
        end
    end

    if not isAlreadySubscriber then
        table.insert(utils_module.Subscribers, msg.From)
    end
end

function utils_module.removeSubscriber(msg)
    for i, subscriber in ipairs(utils_module.Subscribers) do
        if subscriber == msg.From then
            table.remove(utils_module.Subscribers, i)
            break
        end
    end
end

function utils_module.announce(announcement)
    for _, subscriber in ipairs(utils_module.Subscribers) do
        ao.send({ Target = subscriber, Action = "KARDAnnouncement", Data = announcement })
    end
end


return utils_module
