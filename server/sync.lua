BlCopNet = BlCopNet or {}

local function decodeJson(raw)
  if type(raw) == 'table' then return raw end
  if type(raw) ~= 'string' or raw == '' then return {} end
  local ok, data = pcall(json.decode, raw)
  if ok and type(data) == 'table' then return data end
  return {}
end

local function vehicleStatus(row)
  if row.impound == 1 or row.impound == true or (row.impound_data and tostring(row.impound_data) ~= '' and tostring(row.impound_data) ~= 'null') then
    return 'impound'
  end
  if row.stored == 1 or row.stored == true or row.in_garage == 1 or row.in_garage == true then
    return 'garage'
  end
  return 'out'
end

local function vehicleModel(row)
  if row.nickname and tostring(row.nickname) ~= '' then
    return tostring(row.nickname)
  end
  local props = decodeJson(row.vehicle)
  if props.model ~= nil then
    return tostring(props.model)
  end
  return ''
end

function BlCopNet.GetDiscordId(src)
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    local discord = id:match('^discord:(%d+)$')
    if discord then return discord end
  end
  return nil
end

function BlCopNet.FetchPhone(identifier)
  local ok, row = pcall(function()
    return MySQL.single.await([[
      SELECT phone_number AS phone
      FROM phone_last_phone
      WHERE id = ?
      LIMIT 1
    ]], { identifier })
  end)
  if ok and row and row.phone then return tostring(row.phone) end

  ok, row = pcall(function()
    return MySQL.single.await([[
      SELECT phone_number AS phone
      FROM phone_phones
      WHERE id = ? OR owner_id = ?
      ORDER BY last_seen DESC
      LIMIT 1
    ]], { identifier, identifier })
  end)
  if ok and row and row.phone then return tostring(row.phone) end
  return ''
end

function BlCopNet.FetchVehicles(identifier)
  local ok, rows = pcall(function()
    return MySQL.query.await('SELECT * FROM owned_vehicles WHERE owner = ?', { identifier })
  end)
  if not ok or not rows then return {} end

  local out = {}
  for _, row in ipairs(rows) do
    out[#out + 1] = {
      plate = row.plate,
      model = vehicleModel(row),
      vehicleType = row.type or 'car',
      status = vehicleStatus(row),
    }
  end
  return out
end

function BlCopNet.BuildCharacterPayload(row)
  if not row or not row.identifier then return nil end
  local height = row.height
  if height ~= nil and height ~= '' then
    height = tostring(height)
  else
    height = ''
  end

  return {
    externalIdentifier = row.identifier,
    firstName = row.firstname or '',
    lastName = row.lastname or '',
    birthDate = row.dateofbirth or '',
    gender = row.sex or '',
    height = height,
    phone = BlCopNet.FetchPhone(row.identifier),
    syncStatus = 'fivem',
    status = 'active',
    vehicles = BlCopNet.FetchVehicles(row.identifier),
    replaceVehicles = true,
  }
end

function BlCopNet.FetchUserRow(identifier)
  return MySQL.single.await([[
    SELECT identifier, firstname, lastname, dateofbirth, sex, height, job, job_grade
    FROM users
    WHERE identifier = ?
    LIMIT 1
  ]], { identifier })
end

function BlCopNet.SyncIdentifier(identifier, cb)
  local row = BlCopNet.FetchUserRow(identifier)
  if not row then
    BlCopNet.Warn('Kein users-Eintrag für %s', tostring(identifier))
    if cb then cb(false, { error = 'user_not_found' }) end
    return
  end
  local payload = BlCopNet.BuildCharacterPayload(row)
  BlCopNet.SyncCharacter(payload, cb)
end

function BlCopNet.SyncPlayer(src, cb)
  local xPlayer = ESX.GetPlayerFromId(src)
  if not xPlayer then
    if cb then cb(false, { error = 'no_xplayer' }) end
    return
  end
  BlCopNet.SyncIdentifier(xPlayer.identifier, cb)
end

function BlCopNet.SyncAllUsers(cb)
  local rows = MySQL.query.await([[
    SELECT identifier, firstname, lastname, dateofbirth, sex, height, job, job_grade
    FROM users
    WHERE firstname IS NOT NULL AND firstname != ''
    ORDER BY identifier ASC
  ]]) or {}

  local batchSize = tonumber(Config.FullDbSyncBatchSize) or 40
  local delay = tonumber(Config.FullDbSyncDelayMs) or 750
  local index = 1
  local total = #rows
  local created = 0
  local updated = 0
  local failed = 0

  BlCopNet.Warn('Full-Sync gestartet: %s Charaktere', total)

  local function sendBatch()
    if index > total then
      BlCopNet.Warn('Full-Sync fertig: created=%s updated=%s failed=%s', created, updated, failed)
      if cb then cb(true, { created = created, updated = updated, failed = failed, total = total }) end
      return
    end

    local batch = {}
    for _ = 1, batchSize do
      if index > total then break end
      local payload = BlCopNet.BuildCharacterPayload(rows[index])
      if payload then batch[#batch + 1] = payload end
      index = index + 1
    end

    if #batch == 0 then
      SetTimeout(delay, sendBatch)
      return
    end

    BlCopNet.SyncCharacters(batch, function(ok, data)
      if ok and data then
        created = created + (tonumber(data.created) or 0)
        updated = updated + (tonumber(data.updated) or 0)
        failed = failed + (tonumber(data.failed) or 0)
      else
        failed = failed + #batch
      end
      SetTimeout(delay, sendBatch)
    end)
  end

  sendBatch()
end
