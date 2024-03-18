local token_module = require("token_module")
local proposals_module = require('proposals_module')

local utils_module = {}

function utils_module.getTotalSupply()
    local totalSupply = 0

    -- Sum balances from token_module.Balances
    for _, balance in pairs(token_module.Balances) do
        totalSupply = totalSupply + balance
    end

    -- Sum stakes and votes from proposals_module.proposals
    for _, userProposals in pairs(proposals_module.proposals) do
        for _, proposal in pairs(userProposals) do
            totalSupply = totalSupply + proposal.Stake

            totalSupply = totalSupply + (proposal.Votes.yay or 0) + (proposal.Votes.nay or 0)
        end
    end

    return totalSupply
end



return utils_module