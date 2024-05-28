-- local Token_module = require("Token_module")
-- local Utils_module = require("Utils_module")
local json = require("json")

Proposals_module = Proposals_module or {}

Proposals_module.proposals = Proposals_module.proposals or {}


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
    Meme-Frame-Id = txId
})
]]

function Proposals_module.initiateProposal(msg)
    print(msg.From .. " is proposing a proposal.")
    local proposerTokens = tonumber(Token_module.Balances[msg.From])
    assert(msg.Stake, "Must stake tokens with proposal")
    assert(msg.Title, "Must provide a name")
    assert(proposerTokens >= tonumber(msg.Stake), "Cannot stake more tokens than are held")
    assert(
        msg.MemeFrameId == nil or
        (type(msg.MemeFrameId) == "string" and
            #msg.MemeFrameId == 43 and
            msg.MemeFrameId:match("^[A-Za-z0-9_-]+$") ~= nil),
        "MemeFrameId must be nil or a valid Arweave transaction ID"
    )


    proposerTokens = proposerTokens - tonumber(msg.Stake)
    Token_module.Balances[msg.From] = proposerTokens

    local proposal = {
        id = msg.Id,
        author = msg.From,
        title = msg.Title,
        description = msg.Description,
        proposedBlock = msg['Block-Height'],
        deadline = msg['Block-Height'] + 7200,
        votes = {}, -- Initialize votes as an empty table
        status = "active",
        MEMEFRAME_ID = msg.MemeFrameId or nil
    }

    -- Now set the first vote using msg.From as a key
    proposal.votes[msg.From] = {
        yay = tonumber(msg.Stake),
        nay = 0
    }


    Proposals_module.proposals[msg.Id] = proposal

    Utils_module.announce("New proposal with id " .. proposal.id .. " was created by " .. proposal.author)
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

function Proposals_module.vote(msg)
    print(msg.From .. " is trying to vote")
    assert(msg.Stake, "Must stake tokens with vote")
    assert(msg.ProposalId, "Must provide a name")
    assert(msg.Vote, "Must provide a vote")
    assert(Proposals_module.proposals[msg.ProposalId], "The proposal does not exist.")

    local targetProposal = Proposals_module.proposals[msg.ProposalId]

    assert(tonumber(Token_module.Balances[msg.From]) >= tonumber(msg.Stake), "Cannot stake more tokens than owned")
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


    local voterTokens = tonumber(Token_module.Balances[msg.From])
    voterTokens = voterTokens - tonumber(msg.Stake)
    Token_module.Balances[msg.From] = voterTokens

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

function Proposals_module.evaluateProposals(currentBlock)
    print("Starting proposal evaluation")
    local totalSupply = Utils_module.getTotalSupply()
    local requiredVotes = math.floor(totalSupply / 2) + 1
    -- we need to evaluate the accepted proposals in order of their deadline, first completed first evaluated
    local sortedProposals = {}
    for _, proposal in pairs(Proposals_module.proposals) do
        table.insert(sortedProposals, proposal)
    end
    table.sort(sortedProposals, function(a, b)
        return a.deadline < b.deadline
    end)

    for _, proposal in pairs(sortedProposals) do
        if proposal.status == "accepted" or proposal.status == "declined" then
            goto continue
        end
        -- Check if the current block height is equal to or higher than proposal.deadline
        if currentBlock >= proposal.deadline then
            local totalYayVotes = 0

            -- Check if proposal.votes has contents
            if next(proposal.votes) ~= nil then -- next returns nil if table is empty
                -- Iterate over every vote
                for voterId, votes in pairs(proposal.votes) do
                    if type(votes) == "table" then
                        totalYayVotes = totalYayVotes + (tonumber(votes.yay) or 0)

                        -- Refund all voter tokens
                        Token_module.Balances[voterId] = (tonumber(Token_module.Balances[voterId]) or 0) +
                            (tonumber(votes.yay) or 0) + (tonumber(votes.nay) or 0)
                    else
                        print("Unexpected data type for votes of voterId " .. voterId .. ": " .. type(votes))
                    end
                end

                -- Check if total yay votes are equal to or greater than requiredVotes
                if totalYayVotes >= requiredVotes then
                    proposal.status = "accepted"
                    Utils_module.announce("Proposal " .. proposal.id .. " has passed!!")
                    if proposal.MEMEFRAME_ID then
                        Utils_module.announce("MemeFrame ID: " ..
                            proposal.MEMEFRAME_ID .. " has been accepted and set as the new MemeFrame.")
                        MEMEFRAME_ID = proposal.MEMEFRAME_ID
                    end
                else
                    proposal.status = "declined"
                    Utils_module.announce("Proposal " .. proposal.id .. " has failed.")
                end

                -- Clear the vote record after processing
                proposal.votes = {}
            else
                -- If proposal.votes is empty, no action is needed
                print("No votes found for proposal " .. proposal.id)
            end
        end
        -- If current block is lower than proposal.deadline, no action is needed
        ::continue::
    end
    print("Evaluation complete")
end

-- Users can specify Proposal if they want a specific one, otherwise all are returned.

function Proposals_module.getProposals(msg)
    print("Getting proposals")

    if msg.Proposal then
        local proposalData = Proposals_module.proposals[msg.Proposal]
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
            Data = json.encode(Proposals_module.proposals)
        })
    end
end

return Proposals_module
