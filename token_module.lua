-- token_module.lua
-- local bint = require('.bint')(256)
local ao = require('ao')
local json = require('json')
-- local utils_module = require('utils_module')



token_module = token_module or {}

-- Initialize State
token_module.Balances = token_module.Balances or { [ao.id] = 0 }
token_module.Name = 'Kardeshev'
token_module.Ticker = 'KARD'
token_module.Denomination = 1
token_module.CRED = "Sa0iBLPNyJQrwpTTG-tWLQU-1QeUAJA73DdxGGiKoJc"
token_module.Logo = "oDSg_8Qmy8nHOgtS_77cxFTq3oytZ7TBbu0ntGv3Xas"

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
function token_module.infoHandler(msg)
  ao.send({
    Target = msg.From,
    Name = token_module.Name,
    Ticker = token_module.Ticker,
    Denomination = tostring(token_module.Denomination)
  })
end

function token_module.balanceHandler(msg)
  local bal = '0'

  -- If not Recipient is provided, then return the Senders balance
  if (msg.Tags.Recipient and token_module.Balances[msg.Tags.Recipient]) then
    bal = token_module.Balances[msg.Tags.Recipient]
  elseif token_module.Balances[msg.From] then
    bal = token_module.Balances[msg.From]
  end

  ao.send({
    Target = msg.From,
    Balance = bal,
    Ticker = token_module.Ticker,
    Account = msg.Tags.Recipient or msg.From,
    Data = bal
  })
end

function token_module.balancesHandler(msg)
  ao.send({ Target = msg.From, Data = json.encode(token_module.Balances) })
end

function token_module.transferHandler(msg)
  assert(type(msg.Recipient) == 'string', 'Recipient is required!')
  assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(tonumber(msg.Quantity) > 0, 'Quantity must be greater than 0')


  if not token_module.Balances[msg.From] then token_module.Balances[msg.From] = "0" end
  if not token_module.Balances[msg.Recipient] then token_module.Balances[msg.Recipient] = "0" end

  local qty = tonumber(msg.Quantity)
  local balance = tonumber(token_module.Balances[msg.From])

  if qty and balance and qty <= balance then
    token_module.Balances[msg.From] = tostring(balance - qty)
    token_module.Balances[msg.Recipient] = tostring((tonumber(token_module.Balances[msg.Recipient]) or 0) + qty)


    --[[
         Only send the notifications to the Sender and Recipient
         if the Cast tag is not set on the Transfer message
       ]]
    --
    if not msg.Cast then
      -- Send Debit-Notice to the Sender
      ao.send({
        Target = msg.From,
        Action = 'Debit-Notice',
        Recipient = msg.Recipient,
        Quantity = tostring(qty),
        Data = Colors.gray ..
            "You transferred " ..
            Colors.blue .. msg.Quantity .. Colors.gray .. " to " .. Colors.green .. msg.Recipient .. Colors.reset
      })
      -- Send Credit-Notice to the Recipient
      ao.send({
        Target = msg.Recipient,
        Action = 'Credit-Notice',
        Sender = msg.From,
        Quantity = tostring(qty),
        Data = Colors.gray ..
            "You received " ..
            Colors.blue .. msg.Quantity .. Colors.gray .. " from " .. Colors.green .. msg.Recipient .. Colors.reset
      })
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

function token_module.selfMintHandler(msg)
  assert(type(msg.Quantity) == 'string', 'Quantity is required!')
  assert(tonumber(msg.Quantity) > 0, 'Quantity must be greater than 0')


  if not token_module.Balances[ao.id] then token_module.Balances[ao.id] = "0" end

  if msg.From == ao.id then
    -- Add tokens to the token pool, according to Quantity
    local fromBalance = tonumber(token_module.Balances[msg.From]) or 0
    local quantity = tonumber(msg.Quantity) or 0
    token_module.Balances[msg.From] = tostring(fromBalance + quantity)

    ao.send({
      Target = msg.From,
      Data = Colors.gray .. "Successfully minted " .. Colors.blue .. msg.Quantity .. Colors.reset
    })
  else
    ao.send({
      Target = msg.From,
      Action = 'Mint-Error',
      ['Message-Id'] = msg.Id,
      Error = 'Only the Process Id can mint new ' .. token_module.Ticker .. ' tokens!'
    })
  end
end

function token_module.Mint(msg)
  local requestedAmount = tonumber(msg.Quantity)
  local actualAmount = requestedAmount
  assert(type(token_module.Balances) == "table", "Balances not found!")
  local prevBalance = tonumber(token_module.Balances[msg.Sender]) or 0
  token_module.Balances[msg.Sender] = tostring(math.floor(prevBalance + actualAmount))
  print("Minted " .. tostring(actualAmount) .. " to " .. msg.Sender)
  local isAlreadySubscriber = false
  for _, subscriber in ipairs(utils_module.Subscribers) do
    if subscriber == msg.Sender then
      isAlreadySubscriber = true
      break
    end
  end

  if not isAlreadySubscriber then
    table.insert(utils_module.Subscribers, msg.Sender)
  end
  ao.send({ Target = msg.Sender, Data = "Successfully Minted " .. actualAmount })
end

return token_module
