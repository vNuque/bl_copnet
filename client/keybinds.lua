-- Gemeinsame Keybind-Registrierung.
-- Config.Keybinds.*.default = nur Startwert für neue Spieler.
-- Danach umbelegbar unter: Einstellungen → Tastatur → FiveM.
-- Aktuelle Belegung: BlCopNetKeybinds.GetLabel(commandName)

BlCopNetKeybinds = BlCopNetKeybinds or {}

local registered = {} -- commandName -> { command = '…'|'+…', default = 'G', button = bool }

-- Spezielle Codes von GetControlInstructionalButton (b_XXX)
local SPECIAL_KEYS = {
  ['b_100'] = 'LMB',
  ['b_101'] = 'RMB',
  ['b_102'] = 'MMB',
  ['b_103'] = 'Mouse.Extra1',
  ['b_104'] = 'Mouse.Extra2',
  ['b_105'] = 'Mouse.Extra3',
  ['b_106'] = 'Mouse.Extra4',
  ['b_107'] = 'Mouse.Extra5',
  ['b_108'] = 'Mouse.Extra6',
  ['b_109'] = 'Mouse.Extra7',
  ['b_110'] = 'Mouse.Extra8',
  ['b_115'] = 'Mouse.WheelUp',
  ['b_116'] = 'Mouse.WheelDown',
  ['b_130'] = 'Num -',
  ['b_131'] = 'Num +',
  ['b_132'] = 'Num .',
  ['b_133'] = 'Num /',
  ['b_134'] = 'Num *',
  ['b_135'] = 'Num Enter',
  ['b_136'] = 'Num 0',
  ['b_137'] = 'Num 1',
  ['b_138'] = 'Num 2',
  ['b_139'] = 'Num 3',
  ['b_140'] = 'Num 4',
  ['b_141'] = 'Num 5',
  ['b_142'] = 'Num 6',
  ['b_143'] = 'Num 7',
  ['b_144'] = 'Num 8',
  ['b_145'] = 'Num 9',
  ['b_170'] = 'F1',
  ['b_171'] = 'F2',
  ['b_172'] = 'F3',
  ['b_173'] = 'F4',
  ['b_174'] = 'F5',
  ['b_175'] = 'F6',
  ['b_176'] = 'F7',
  ['b_177'] = 'F8',
  ['b_178'] = 'F9',
  ['b_179'] = 'F10',
  ['b_180'] = 'F11',
  ['b_181'] = 'F12',
  ['b_182'] = 'F13',
  ['b_183'] = 'F14',
  ['b_184'] = 'F15',
  ['b_185'] = 'F16',
  ['b_186'] = 'F17',
  ['b_187'] = 'F18',
  ['b_188'] = 'F19',
  ['b_189'] = 'F20',
  ['b_190'] = 'F21',
  ['b_191'] = 'F22',
  ['b_192'] = 'F23',
  ['b_193'] = 'F24',
  ['b_194'] = 'Arrow Up',
  ['b_195'] = 'Arrow Down',
  ['b_196'] = 'Arrow Left',
  ['b_197'] = 'Arrow Right',
  ['b_198'] = 'Del',
  ['b_199'] = 'Esc',
  ['b_200'] = 'Insert',
  ['b_201'] = 'End',
  ['b_1000'] = 'Shift',
  ['b_1001'] = 'Ctrl',
  ['b_1002'] = 'Alt',
  ['b_1003'] = 'Pause',
  ['b_1004'] = 'Caps',
  ['b_1005'] = 'Backspace',
  ['b_1006'] = 'Tab',
  ['b_1008'] = 'Enter',
  ['b_1009'] = 'Sym',
  ['b_1010'] = '¿',
  ['b_1012'] = '`',
  ['b_1013'] = 'LMB',
  ['b_1014'] = 'RMB',
  ['b_1015'] = 'MMB',
  ['b_1016'] = 'Mouse.Extra1',
  ['b_1017'] = 'Mouse.Extra2',
  ['b_1018'] = 'Mouse.Extra3',
  ['b_1019'] = 'Mouse.Extra4',
  ['b_1020'] = 'Mouse.Extra5',
  ['b_1021'] = 'Mouse.Extra6',
  ['b_1022'] = 'Mouse.Extra7',
  ['b_1023'] = 'Mouse.Extra8',
  ['b_1024'] = 'Mouse.WheelUp',
  ['b_1025'] = 'Mouse.WheelDown',
  ['b_1026'] = 'Num Enter',
  ['b_1027'] = 'Num /',
  ['b_1028'] = 'Num *',
  ['b_1029'] = 'Num -',
  ['b_1030'] = 'Num +',
  ['b_1031'] = 'Num .',
  ['b_2000'] = 'Space',
  ['b_1011'] = '=',
  ['b_1055'] = 'Home',
  ['b_1056'] = 'Page Up',
  ['b_1057'] = 'Page Down',
}

local function normalizeLabel(raw, fallback)
  local key = tostring(raw or ''):gsub('%s+', '')
  if key == '' or key == 'NULL' or key == '????' then
    return tostring(fallback or '?'):upper()
  end

  if key:sub(1, 2) == 't_' then
    local label = key:sub(3)
    if label == '' then return tostring(fallback or '?'):upper() end
    return label:upper()
  end

  if key:sub(1, 2) == 'b_' then
    return SPECIAL_KEYS[key] or key:upper()
  end

  return key:upper()
end

--- Liest die aktuelle Tastaturbelegung (auch nach Umlegen in den FiveM-Settings).
function BlCopNetKeybinds.GetLabel(commandName, fallback)
  local meta = registered[commandName]
  local command = (meta and meta.command) or commandName
  local fb = (meta and meta.default) or fallback or '?'

  local ok, raw = pcall(function()
    return GetControlInstructionalButton(2, joaat(command) | 0x80000000, true)
  end)
  if not ok or type(raw) ~= 'string' or raw == '' then
    return tostring(fb):upper()
  end
  return normalizeLabel(raw, fb)
end

function BlCopNetKeybinds.Register(cfg, commandName, handler, opts)
  opts = opts or {}
  cfg = type(cfg) == 'table' and cfg or {}

  local description = tostring(cfg.description or commandName)
  local defaultKey = tostring(cfg.default or ''):gsub('%s+', '')
  -- Leerer Default → trotzdem registrieren, damit Spieler die Taste selbst belegen können
  if defaultKey == '' then
    defaultKey = tostring(opts.fallback or 'F10')
  end

  local mappedCommand = commandName
  if opts.button then
    -- Halten-kompatibel (+/-), z.B. Panic
    mappedCommand = '+' .. commandName
    RegisterCommand(mappedCommand, handler, false)
    RegisterCommand('-' .. commandName, function() end, false)
    RegisterKeyMapping(mappedCommand, description, 'keyboard', defaultKey)
  else
    RegisterCommand(commandName, handler, false)
    RegisterKeyMapping(commandName, description, 'keyboard', defaultKey)
  end

  registered[commandName] = {
    command = mappedCommand,
    default = defaultKey,
    button = opts.button and true or false,
  }
end
