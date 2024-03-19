local token_module = require(".token_module")
local proposals_module = require(".proposals_module")
local utils_module = require(".utils_module")


-- Token Handlers
Handlers.add(
    "getTokenInfo",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        token_module.infoHandler(msg)
    end
)

Handlers.add(
    "Balance",
    Handlers.utils.hasMatchingTag("Action", "Balance"),
    function(msg)
        token_module.balanceHandler(msg)
    end
)

Handlers.add(
    "TokenBalances",
    Handlers.utils.hasMatchingTag("Action", "TokenBalances"),
    function(msg)
        token_module.balancesHandler(msg)
    end
)

Handlers.add(
    "Transfer",
    Handlers.utils.hasMatchingTag("Action", "Transfer"),
    function(msg)
        token_module.transferHandler(msg)
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
        token_module.Mint(msg)
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
        token_module.selfMintHandler(msg)
    end
)


-- Proposal handlers

Handlers.add(
    "Propose",
    Handlers.utils.hasMatchingTag("Action", "Propose"),
    function(msg)
        print("This handler was triggered")
        proposals_module.initiateProposal(msg)

        local status, err = pcall(proposals_module.evaluateProposals, msg["Block-Height"])
        if not status then
            print("Error in evaluateProposals: " .. err)
        end
    end
)


Handlers.add(
    "Vote",
    Handlers.utils.hasMatchingTag("Action", "Vote"),
    function(msg)
        local statusVote, errVote = pcall(proposals_module.vote, msg)
        if not statusVote then
            print("Error in voting: " .. errVote)
        end

        local statusEvaluate, errEvaluate = pcall(proposals_module.evaluateProposals, msg["Block-Height"])
        if not statusEvaluate then
            print("Error in evaluating proposals: " .. errEvaluate)
        end
    end
)


Handlers.add(
    "GetProposals",
    Handlers.utils.hasMatchingTag("Action", "GetProposals"),
    function(msg)
        proposals_module.evaluateProposals(msg["Block-Height"])
        proposals_module.getProposals(msg)
    end
)

-- Subscription Handlers

Handlers.add(
    "Subscribe",
    Handlers.utils.hasMatchingTag("Action", "Subscribe"),
    function(msg)
        utils_module.addSubscriber(msg)
    end
)

Handlers.add(
    "Unsubscribe",
    Handlers.utils.hasMatchingTag("Action", "Unsubscribe"),
    function(msg)
        utils_module.removeSubscriber(msg)
    end
)
