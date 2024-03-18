local token_module = require("token_module")
local utils = require("utils")

proposals_module = proposals_module or {}

proposals_module.proposals = proposals_module.proposals or {}

local function any(table, predicate)
    for _, value in ipairs(table) do
        if predicate(value) then
            return true
        end
    end
    return false
end


--[[
syntax for proposing stake

Send({
    Target = us,
    Action = "Propose",
    Stake = 500 -- amount of tokens to stake as a yes vote
    ProposalName = "name" -- a name for the proposal to track multiple proposals from same user
    TxID = arweaveTxId -- (optional) if the proposal is to set a tx for the memeframe, this is where they would put it
    Description = -- description of proposal, can be used
})
]]

function proposals_module.initiateProposal(msg)
    local proposerTokens = token_module.Balances[msg.From]
    assert(msg.Stake, "Must stake tokens with proposal")
    assert(msg.Name, "Must provide a name")
    assert(proposerTokens >= msg.Stake, "Cannot stake more tokens than are held")
    assert(
        not proposals_module[msg.From] or
        not any(proposals_module[msg.From], function(item) return item.Name == msg.ProposalName end),
        "The propoposal must have a unique name"
    )
    assert(
        (type(msg.Stake) == "number" and msg.Stake == math.floor(msg.Stake)) or
        (tonumber(msg.Stake) and tonumber(msg.Stake) == math.floor(tonumber(msg.Stake))),
        "Stake must be an integer or convertible to an integer"
    )

    proposerTokens = proposerTokens - tonumber(msg.Stake)
    token_module.Balances[msg.From] = proposerTokens

    proposal = {
        Name = msg.ProposalName,
        TxID = msg.TxID or nil,
        Description = msg.Description,
        ProposedBlock = msg['Block-Height'],
        ProposerStake = msg.Stake,
        FinalizeBlock = msg['Block-Height'] + 7200,
        Votes = {
            yay = 0,
            nay = 0
        },
        Pass = false

    }

    table.insert(proposals_module[msg.From], proposal)

    ao.send({ Target = msg.From, Data = "Successfully created proposal " .. msg.Name .. " with a stake of " .. msg.Stake })

    -- Add an announcement here
end

--[[
    syntax of vote message

    Send({
        Target = us,
        Action = "Vote",
        Proposer = "PID or wallet address of proposer", -- We can add ArNS to this later
        ProposalName = "proposal name",
        Vote = "yay" -- will accept "yay", "yes", "y", "nay", "no", "n"
        Stake = 5000 -- amount to stake on vote
    })
]]

function proposals_module.vote(msg)
    assert(msg.Stake, "Must stake tokens with vote")
    assert(msg.ProposalName, "Must provide a name")
    assert(msg.Proposer, "Must identify the proposal owner")
    assert(msg.Vote, "Must provide a vote")
    assert(proposals_module[msg.Proposer], "The proposer does not have any proposals.")

    local targetProposal = nil
    for _, proposal in pairs(proposals_module[msg.Proposer]) do
        if proposal.Name == msg.ProposalName then
            targetProposal = proposal
            break
        end
    end

    assert(targetProposal, "No proposal found with the given name.")
    assert(
        (type(msg.Stake) == "number" and msg.Stake == math.floor(msg.Stake)) or
        (tonumber(msg.Stake) and tonumber(msg.Stake) == math.floor(tonumber(msg.Stake))),
        "Stake must be an integer or convertible to an integer"
    )
    assert(token_module.Balances[msg.From] >= tonumber(msg.Stake), "Cannot stake more tokens than owned")
    assert(
        string.lower(msg.Vote) == "yay" or
        string.lower(msg.Vote) == "yes" or
        string.lower(msg.Vote) == "y" or
        string.lower(msg.Vote) == "nay" or
        string.lower(msg.Vote) == "no" or
        string.lower(msg.Vote) == "n",
        "vote not recognized, use 'yay', 'yes', 'y', 'nay', 'no', 'n'"
    )
    assert(msg['Block-Height'] < targetProposal.FinalizeBlock, "voting for this proposal has closed")


    local voterTokens = token_module.Balances[msg.From]
    voterTokens = voterTokens - tonumber(msg.Stake)
    token_module.Balances[msg.From] = voterTokens

    if string.lower(msg.Vote) == "yay" or
        string.lower(msg.Vote) == "yes" or
        string.lower(msg.Vote) == "y" then
        targetProposal.Votes.yay = targetProposal.Votes.yay + tonumber(msg.Stake)
    else
        if string.lower(msg.Vote) == "nay" or
            string.lower(msg.Vote) == "no" or
            string.lower(msg.Vote) == "n" then
            targetProposal.Votes.nay = targetProposal.Votes.nay + tonumber(msg.Stake)
        end
    end
end

return proposals_module
