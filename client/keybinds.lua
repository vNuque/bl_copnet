-- Gemeinsame Keybind-Registrierung.
-- Config.Keybinds.*.default = nur Startwert für neue Spieler.
-- Danach umbelegbar unter: Einstellungen → Tastatur → FiveM.

BlCopNetKeybinds = BlCopNetKeybinds or {}

function BlCopNetKeybinds.Register(cfg, commandName, handler, opts)
  opts = opts or {}
  cfg = type(cfg) == 'table' and cfg or {}

  local description = tostring(cfg.description or commandName)
  local defaultKey = tostring(cfg.default or ''):gsub('%s+', '')
  -- Leerer Default → trotzdem registrieren, damit Spieler die Taste selbst belegen können
  if defaultKey == '' then
    defaultKey = tostring(opts.fallback or 'F10')
  end

  if opts.button then
    -- Halten-kompatibel (+/-), z.B. Panic
    RegisterCommand('+' .. commandName, handler, false)
    RegisterCommand('-' .. commandName, function() end, false)
    RegisterKeyMapping('+' .. commandName, description, 'keyboard', defaultKey)
  else
    RegisterCommand(commandName, handler, false)
    RegisterKeyMapping(commandName, description, 'keyboard', defaultKey)
  end
end
