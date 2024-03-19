-- local token_module = require("token_module")
-- local utils_module = require("utils_module")
local json = require("json")

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
    print(msg.From .. " is proposing a proposal.")
    local proposerTokens = tonumber(token_module.Balances[msg.From])
    assert(msg.Stake, "Must stake tokens with proposal")
    assert(msg.Title, "Must provide a name")
    assert(proposerTokens >= tonumber(msg.Stake), "Cannot stake more tokens than are held")

    proposerTokens = proposerTokens - tonumber(msg.Stake)
    token_module.Balances[msg.From] = proposerTokens

    local proposal = {
        id = msg.Id,
        author = msg.From,
        title = msg.Title,
        description = msg.Description,
        proposedBlock = msg['Block-Height'],
        deadline = msg['Block-Height'] + 7200,
        votes = {},  -- Initialize votes as an empty table
        status = "active"
    }
    
    -- Now set the first vote using msg.From as a key
    proposal.votes[msg.From] = {
        yay = tonumber(msg.Stake),
        nay = 0
    }
    

    proposals_module.proposals[msg.Id] = proposal

    utils_module.announce("New proposal with id " .. proposal.id .. " was created by " .. proposal.author)
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
    print(msg.From .. " is trying to vote")
    assert(msg.Stake, "Must stake tokens with vote")
    assert(msg.ProposalId, "Must provide a name")
    assert(msg.Vote, "Must provide a vote")
    assert(proposals_module.proposals[msg.ProposalId], "The proposal does not exist.")

    local targetProposal = proposals_module.proposals[msg.ProposalId]

    assert(tonumber(token_module.Balances[msg.From]) >= tonumber(msg.Stake), "Cannot stake more tokens than owned")
    assert(
        string.lower(msg.Vote) == "yay" or
        string.lower(msg.Vote) == "yes" or
        string.lower(msg.Vote) == "y" or
        string.lower(msg.Vote) == "nay" or
        string.lower(msg.Vote) == "no" or
        string.lower(msg.Vote) == "n",
        "vote not recognized, use 'yay', 'yes', 'y', 'nay', 'no', 'n'"
    )
    assert(msg['Block-Height'] < targetProposal.deadline, "voting for this proposal has closed")


    local voterTokens = tonumber(token_module.Balances[msg.From])
    voterTokens = voterTokens - tonumber(msg.Stake)
    token_module.Balances[msg.From] = voterTokens

    if not targetProposal.votes[msg.From] then
        targetProposal.votes[msg.From] = { yay = 0, nay = 0 }
    end

    local voteType = string.lower(msg.Vote)
    if voteType == "yay" or voteType == "yes" or voteType == "y" then
        targetProposal.votes[msg.From].yay = targetProposal.votes[msg.From].yay + tonumber(msg.Stake)
    elseif voteType == "nay" or voteType == "no" or voteType == "n" then
        targetProposal.votes[msg.From].nay = targetProposal.votes[msg.From].nay + tonumber(msg.Stake)
    end
end


function proposals_module.evaluateProposals(currentBlock)
    print("Starting proposal evaluation")
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
                    if type(votes) == "table" then
                        totalYayVotes = totalYayVotes + (tonumber(votes.yay) or 0)

                        -- Refund all voter tokens
                        token_module.Balances[voterId] = (tonumber(token_module.Balances[voterId]) or 0) + (tonumber(votes.yay) or 0) + (tonumber(votes.nay) or 0)
                    else
                        print("Unexpected data type for votes of voterId " .. voterId .. ": " .. type(votes))
                    end
                end

                -- Check if total yay votes are equal to or greater than requiredVotes
                if totalYayVotes >= requiredVotes then
                    proposal.status = "accepted"
                    utils_module.announce("Proposal " .. proposal.id .. " has passed!!")
                else
                    proposal.status = "declined"
                    utils_module.announce("Proposal " .. proposal.id .. " has failed.")
                end

                -- Clear the vote record after processing
                proposal.votes = {}
            else
                -- If proposal.votes is empty, no action is needed
                print("No votes found for proposal " .. proposal.id)
            end
        end
        -- If current block is lower than proposal.deadline, no action is needed
    end
    print("Evaluation complete")
end


-- Users can specify Proposal if they want a specific one, otherwise all are returned.

function proposals_module.getProposals(msg)
    print("Getting proposals")

    if msg.Proposal then
        local proposalData = proposals_module.proposals[msg.Proposal]
        if proposalData then
            ao.send({
                Target = msg.From,
                Data = json.encode(proposalData)
            })
        else
            print("Proposal not found")
        end
    else
        print("Sending all proposals")
        ao.send({
            Target = msg.From,
            Data = json.encode(proposals_module.proposals)
        })
    end
end


return proposals_module
