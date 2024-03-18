local token_module = require("token_module")
local utils_module = require("utils_module")

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
    Title = "name" -- a name for the proposal to track multiple proposals from same user
    Description = -- description of proposal, can be used
})
]]

function proposals_module.initiateProposal(msg)
    local proposerTokens = token_module.Balances[msg.From]
    assert(msg.Stake, "Must stake tokens with proposal")
    assert(msg.Title, "Must provide a name")
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
        id = msg.id,
        author = msg.From,
        title = msg.Title,
        description = msg.Description,
        proposedBlock = msg['Block-Height'],
        deadline = msg['Block-Height'] + 7200,
        votes = {
            yay = tonumber(msg.Stake),
            nay = 0
        },
        status = "active"

    }

    table.insert(proposals_module.proposals[msg.id], proposal)

    ao.send({ Target = msg.From, Data = "Successfully created proposal " .. msg.title .. " with an id of " .. msg.id })

    -- Add an announcement here
end

--[[
    syntax of vote message

    Send({
        Target = us,
        Action = "Vote",
        ProposalId = "TxID of proposal", -- We can add ArNS to this later
        Vote = "yay" -- will accept "yay", "yes", "y", "nay", "no", "n"
        Stake = 5000 -- amount to stake on vote
    })
]]

function proposals_module.vote(msg)
    assert(msg.Stake, "Must stake tokens with vote")
    assert(msg.ProposalId, "Must provide a name")
    assert(msg.Vote, "Must provide a vote")
    assert(proposals_module.proposals[msg.ProposalId], "The proposal does not exist.")

    local targetProposal = proposals_module.proposals[msg.ProposalId]

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

    if not targetProposal.Votes[msg.From] then
        targetProposal.Votes[msg.From] = { yay = 0, nay = 0 }
    end

    local voteType = string.lower(msg.Vote)
    if voteType == "yay" or voteType == "yes" or voteType == "y" then
        targetProposal.Votes[msg.From].yay = targetProposal.Votes[msg.From].yay + tonumber(msg.Stake)
    elseif voteType == "nay" or voteType == "no" or voteType == "n" then
        targetProposal.Votes[msg.From].nay = targetProposal.Votes[msg.From].nay + tonumber(msg.Stake)
    end
end


function proposals_module.evaluateProposals(currentBlock)
    local totalSupply = utils_module.getTotalSupply()
    local requiredVotes = math.floor(totalSupply / 2) + 1

    for _, proposal in pairs(proposals_module.proposals) do
        -- Check if the current block height is equal to or higher than proposal.deadline
        if currentBlock >= proposal.deadline then
            local totalYayVotes = 0

            -- Check if proposal.votes has contents
            if next(proposal.votes) ~= nil then  -- next returns nil if table is empty
                -- Iterate over every vote
                for voterId, votes in pairs(proposal.votes) do
                    totalYayVotes = totalYayVotes + (votes.yay or 0)

                    -- Refund all voter tokens
                    token_module.Balances[voterId] = (token_module.Balances[voterId] or 0) + (votes.yay or 0) + (votes.nay or 0)
                end

                -- Check if total yay votes are equal to or greater than requiredVotes
                if totalYayVotes >= requiredVotes then
                    proposal.status = "accepted"
                    -- add an announcement here
                else
                    proposal.status = "declined"
                    -- add an announcement here
                end

                -- Clear the vote record after processing
                proposal.votes = {}
            else
                -- If proposal.votes is empty, no action is needed
            end
        end
        -- If current block is lower than proposal.deadline, no action is needed
    end
end



return proposals_module
