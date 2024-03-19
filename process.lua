local token_module = require('token_module')
local proposals_module = require("proposals_module")
local utils_module = require("utils_module")


-- Token Handlers
Handlers.add(
    "getTokenInfo",
    Handlers.utils.hasMatchingTag("Action", "TokenInfo"),
    function(msg)
        token_module.infoHandler(msg)
    end
)

Handlers.add(
    "TokenBalance",
    Handlers.utils.hasMatchingTag("Action", "TokenBalance"),
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
        if msg.Data == "Credit-Notice" and msg.Tags['From-Process'] == "Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc" then
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
    "InitiateProposal",
    Handlers.utils.hasMatchingTag("Action", "Propose"),
    function(msg)
        proposals_module.initiateProposal(msg)
        proposals_module.evaluateProposals(msg["Block-Height"])
    end
)

Handlers.add(
    "Vote",
    Handlers.utils.hasMatchingTag("Action", "Vote"),
    function(msg)
        proposals_module.vote(msg)
        proposals_module.evaluateProposals(msg["Block-Height"])
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