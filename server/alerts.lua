BlCopNet = BlCopNet or {}

--- CAD-Alert an CopNet schicken (Hausraub, Schüsse, …).
--- Andere Resources:
---   exports['bl_copnet']:CreateCadAlert({
---     title = 'Schüsse gemeldet',
---     code = 'SHOTS',
---     kind = 'shots_fired',
---     priority = 1,
---     x = 100.0, y = 200.0, z = 30.0,
---     street = 'Forum Drive',
---     postal = '123',
---     agencyId = 'lspd', -- optional
---     notes = 'Mehrere Schüsse gehört',
---     source = 'my_script',
---   }, function(ok, data) end)
function BlCopNet.CreateCadAlert(opts, cb)
  opts = type(opts) == 'table' and opts or {}
  if Config.CadAlerts and Config.CadAlerts.enabled == false then
    if cb then cb(false, { error = 'alerts_disabled' }) end
    return
  end

  local title = tostring(opts.title or ''):gsub('^%s+', ''):gsub('%s+$', '')
  if title == '' then
    BlCopNet.Warn('CreateCadAlert: title fehlt')
    if cb then cb(false, { error = 'title_required' }) end
    return
  end

  local cfg = Config.CadAlerts or {}
  local agencyId = tostring(opts.agencyId or opts.agency_id or cfg.defaultAgencyId or ''):gsub('^%s+', ''):gsub('%s+$', '')
  local priority = tonumber(opts.priority) or tonumber(cfg.defaultPriority) or 2

  local body = {
    title = title,
    code = opts.code,
    kind = opts.kind or opts.type,
    priority = priority,
    agencyId = agencyId ~= '' and agencyId or nil,
    locationText = opts.locationText or opts.location,
    x = opts.x or opts.posX or opts.pos_x,
    y = opts.y or opts.posY or opts.pos_y,
    z = opts.z or opts.posZ or opts.pos_z,
    street = opts.street,
    crossing = opts.crossing,
    district = opts.district or opts.zone,
    postal = opts.postal,
    gender = opts.gender,
    personName = opts.personName or opts.person,
    vehicle = opts.vehicle,
    plate = opts.plate,
    color = opts.color,
    notes = opts.notes,
    source = opts.source or opts.script or GetInvokingResource() or 'fivem',
    details = type(opts.details) == 'table' and opts.details or nil,
    assignedOfficerIds = type(opts.assignedOfficerIds) == 'table' and opts.assignedOfficerIds or nil,
  }

  BlCopNet.Request('POST', '/api/fivem/cad/alerts', body, function(ok, data)
    if ok then
      BlCopNet.Debug('CAD-Alert angelegt: %s (%s)', title, tostring(data and data.call and data.call.id or '?'))
    else
      BlCopNet.Warn('CAD-Alert fehlgeschlagen: %s', tostring(data and (data.error or data.raw) or 'unknown'))
    end
    if cb then cb(ok, data) end
  end)
end

--- Convenience: Koordinaten aus Player-Server-ID übernehmen
function BlCopNet.CreateCadAlertAtPlayer(src, opts, cb)
  opts = type(opts) == 'table' and opts or {}
  local ped = GetPlayerPed(src)
  if ped and ped ~= 0 then
    local coords = GetEntityCoords(ped)
    opts.x = opts.x or coords.x
    opts.y = opts.y or coords.y
    opts.z = opts.z or coords.z
  end
  return BlCopNet.CreateCadAlert(opts, cb)
end

exports('CreateCadAlert', function(opts, cb)
  return BlCopNet.CreateCadAlert(opts, cb)
end)

exports('CreateCadAlertAtPlayer', function(src, opts, cb)
  return BlCopNet.CreateCadAlertAtPlayer(src, opts, cb)
end)
