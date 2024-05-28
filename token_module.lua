-- Token_module.lua
-- local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json')
-- local Utils_module = require('Utils_module')



Token_module = Token_module or {}

-- Initialize State
Token_module.Balances = Token_module.Balances or { [ao.id] = 0 }
Token_module.Name = 'Kardeshev'
Token_module.Ticker = 'KARD'
Token_module.Denomination = 3
Token_module.CRED = "Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc"
Token_module.Logo = "JcxV9Mb-X9E4tW5Dkk1DY8JmFlu6pAW0djklvNAbcPQ"

local Colors = {
  red = "\27[31m",
  green = "\27[32m",
  blue = "\27[34m",
  yellow = "\27[33m",
  magenta = "\27[35m",
  reset = "\27[0m",
  gray = "\27[90m"
}

-- Handler functions
function Token_module.infoHandler(msg)
  ao.send({
    Target = msg.From,
    Name = Token_module.Name,
    Ticker = Token_module.Ticker,
    Logo = Token_module.Logo,
    Denomination = tostring(Token_module.Denomination),
    MemeframeId = MEMEFRAME_ID
  })
end

function Token_module.balanceHandler(msg)
  print("Balance Handler started")
  local bal = '0'

  if (msg.Owner and Token_module.Balances[msg.Owner]) then
    bal = tostring(Token_module.Balances[msg.Owner])
    -- If not Recipient is provided, then return the Senders balance
  elseif (msg.Tags.Recipient and Token_module.Balances[msg.Tags.Recipient]) then
    bal = tostring(Token_module.Balances[msg.Tags.Recipient])
  elseif Token_module.Balances[msg.From] then
    bal = tostring(Token_module.Balances[msg.From])
  end

  ao.send({
    Target = msg.From,
    Balance = bal,
    Ticker = Token_module.Ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
  print("Balance message sent")
end

function Token_module.balancesHandler(msg)
  print("Balances handler")
  ao.send({ Target = msg.From, Data = json.encode(Token_module.Balances) })
end

function Token_module.transferHandler(msg)
  assert(type(msg.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(tonumber(msg.Quantity) > 0, 'Quantity must be greater than 0')


  if not Token_module.Balances[msg.From] then Token_module.Balances[msg.From] = "0" end
  if not Token_module.Balances[msg.Recipient] then Token_module.Balances[msg.Recipient] = "0" end

  local qty = tonumber(msg.Quantity)
  local balance = tonumber(Token_module.Balances[msg.From])

  if qty and balance and qty <= balance then
    Token_module.Balances[msg.From] = tostring(balance - qty)
    Token_module.Balances[msg.Recipient] = tostring((tonumber(Token_module.Balances[msg.Recipient]) or 0) + qty)


    --[[
         Only send the notifications to the Sender and Recipient
         if the Cast tag is not set on the Transfer message
       ]]
    --
    if not msg.Cast then
      -- Send Debit-Notice to the Sender
local debitNotice =   {Target = msg.From,
Action = 'Debit-Notice',
Recipient = msg.Recipient,
Quantity = tostring(qty),
Data = Colors.gray ..
    "You transferred " ..
    Colors.blue .. msg.Quantity .. Colors.gray .. " to " .. Colors.green .. msg.Recipient .. Colors.reset,
}
local creditNotice = {
  Target = msg.Recipient,
  Action = 'Credit-Notice',
  Sender = msg.From,
  Quantity = tostring(qty),
  Data = Colors.gray ..
      "You received " ..
      Colors.blue ..
      qty / 10 ^ Token_module.Denomination ..
      Colors.gray .. " from " .. Colors.green .. msg.Recipient .. Colors.reset,
}

for tagName, tagValue in pairs(msg) do
  -- Tags beginning with "X-" are forwarded
  if string.sub(tagName, 1, 2) == "X-" then
    debitNotice[tagName] = tagValue
    creditNotice[tagName] = tagValue
  end
end
      ao.send(debitNotice)
      -- Send Credit-Notice to the Recipient
      ao.send(creditNotice)
    end
  else
    ao.send({
      Target = msg.From,
      Action = 'Transfer-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Insufficient Balance!'
    })
  end
end

function Token_module.selfMintHandler(msg)
  print("Starting selfMint")
  -- assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(tonumber(msg.Quantity) > 0, 'Quantity must be greater than 0')


  if not Token_module.Balances[ao.id] then Token_module.Balances[ao.id] = "0" end

  if msg.From == ao.id then
    -- Add tokens to the token pool, according to Quantity
    local fromBalance = tonumber(Token_module.Balances[msg.From]) or 0
    local quantity = tonumber(msg.Quantity) or 0
    Token_module.Balances[msg.From] = fromBalance + quantity

    ao.send({
      Target = msg.From,
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. msg.Quantity .. Colors.reset
    })
  else
    ao.send({
      Target = msg.From,
      Action = 'Mint-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Only the Process Id can mint new ' .. Token_module.Ticker .. ' tokens!'
    })
  end
end

function Token_module.Mint(msg)
  print("Starting Mint")
  local requestedAmount = tonumber(msg.Quantity)
  local actualAmount = requestedAmount
  assert(type(Token_module.Balances) == "table", "Balances not found!")
  local prevBalance = tonumber(Token_module.Balances[msg.Sender]) or 0
  Token_module.Balances[msg.Sender] = math.floor(prevBalance + actualAmount)
  print("Minted " .. tostring(actualAmount) .. " to " .. msg.Sender)
  local isAlreadySubscriber = false
  for _, subscriber in ipairs(Utils_module.Subscribers) do
    if subscriber == msg.Sender then
      isAlreadySubscriber = true
      break
    end
  end

  if not isAlreadySubscriber then
    table.insert(Utils_module.Subscribers, msg.Sender)
  end
  ao.send({ Target = msg.Sender, Data = "Successfully Minted " .. actualAmount })
end

return Token_module
