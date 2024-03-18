local token_module = require("token_module")
local proposals_module = require('proposals_module')

local utils_module = {}

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



return utils_module
