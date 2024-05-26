local Token_module = require("token_module")
local Proposals_module = require("proposals_module")
local Utils_module = require("utils_module")

MEMEFRAME_ID = MEMEFRAME_ID or "Hkg1j_MCrJFF42xXSWYc6x8M-ERuOCFvey3QFTgLFsU"
-- Token Handlers
Handlers.add(
    "getTokenInfo",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        Token_module.infoHandler(msg)
    end
)

Handlers.add(
    "Balance",
    Handlers.utils.hasMatchingTag("Action", "Balance"),
    function(msg)
        Token_module.balanceHandler(msg)
    end
)

Handlers.add(
    "TokenBalances",
    Handlers.utils.hasMatchingTag("Action", "TokenBalances"),
    function(msg)
        Token_module.balancesHandler(msg)
    end
)

Handlers.add(
    "Transfer",
    Handlers.utils.hasMatchingTag("Action", "Transfer"),
    function(msg)
        Token_module.transferHandler(msg)
    end
)

Handlers.add(
    "Mint",
    function(msg)
        if msg.Action == "Credit-Notice" and msg.Tags['From-Process'] == "Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc" then
            return true
        else
            return false
        end
    end,
    function(msg)
        Token_module.Mint(msg)
    end
)

Handlers.add(
    "SelfMint",
    function(msg)
        if msg.From == ao.id and msg.Tags["Action"] == "SelfMint" then
            return true
        else
            return false
        end
    end,
    function(msg)
        Token_module.selfMintHandler(msg)
    end
)


-- Proposal handlers

Handlers.add(
    "Propose",
    Handlers.utils.hasMatchingTag("Action", "Propose"),
    function(msg)
        print("This handler was triggered")
        Proposals_module.initiateProposal(msg)

        local status, err = pcall(Proposals_module.evaluateProposals, msg["Block-Height"])
        if not status then
            print("Error in evaluateProposals: " .. err)
        end
    end
)


Handlers.add(
    "Vote",
    Handlers.utils.hasMatchingTag("Action", "Vote"),
    function(msg)
        local statusVote, errVote = pcall(Proposals_module.vote, msg)
        if not statusVote then
            print("Error in voting: " .. errVote)
        end

        local statusEvaluate, errEvaluate = pcall(Proposals_module.evaluateProposals, msg["Block-Height"])
        if not statusEvaluate then
            print("Error in evaluating proposals: " .. errEvaluate)
        end
    end
)


Handlers.add(
    "GetProposals",
    Handlers.utils.hasMatchingTag("Action", "GetProposals"),
    function(msg)
        Proposals_module.evaluateProposals(msg["Block-Height"])
        Proposals_module.getProposals(msg)
    end
)

-- Subscription Handlers

Handlers.add(
    "Subscribe",
    Handlers.utils.hasMatchingTag("Action", "Subscribe"),
    function(msg)
        Utils_module.addSubscriber(msg)
    end
)

Handlers.add(
    "Unsubscribe",
    Handlers.utils.hasMatchingTag("Action", "Unsubscribe"),
    function(msg)
        Utils_module.removeSubscriber(msg)
    end
)
