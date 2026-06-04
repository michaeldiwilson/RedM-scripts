Config = {}

Config.OpenKey = 'F9'
Config.OpenCommand = 'adminmenu'

Config.Permissions = {
    AceEnabled = true,
    Ace = 'command',
    UserGroupsEnabled = true,
    Groups = { 'admin', 'god' },
}

Config.Commands = {
    Ban      = { enabled = true, name = 'ban' },
    Kick     = { enabled = true, name = 'kick' },
    Noclip   = { enabled = true, name = 'noclip' },
    Revive   = { enabled = true, name = 'arevive' },
    Tp       = { enabled = true, name = 'tp' },
    Bring    = { enabled = true, name = 'bring' },
    Goto     = { enabled = true, name = 'goto' },
}

Config.Noclip = {
    DefaultSpeed = 1.0,
    MaxSpeed     = 10.0,
    MinSpeed     = 0.25,
    SpeedStep    = 0.5,
}

Config.Weathers = {
    { label = 'Sunny',          value = 'SUNNY' },
    { label = 'Clear',          value = 'CLEAR' },
    { label = 'Clouds',         value = 'CLOUDS' },
    { label = 'Overcast',       value = 'OVERCAST' },
    { label = 'Summer',         value = 'SUMMER' },
    { label = 'Rain',           value = 'RAIN' },
    { label = 'Drizzle',        value = 'DRIZZLE' },
    { label = 'Thunder',        value = 'THUNDER' },
    { label = 'Shower',         value = 'SHOWER' },
    { label = 'Fog',            value = 'FOG' },
    { label = 'Misty',          value = 'MISTY' },
    { label = 'Hail',           value = 'HAIL' },
    { label = 'Sleet',          value = 'SLEET' },
    { label = 'Snow',           value = 'SNOW' },
    { label = 'Snow Light',     value = 'SNOWLIGHT' },
    { label = 'Snow Clouds',    value = 'SNOWCLOUDS' },
    { label = 'Blizzard',       value = 'BLIZZARD' },
    { label = 'Ground Blizzard',value = 'GROUNDBLIZZARD' },
    { label = 'High Pressure',  value = 'HIGHPRESSURE' },
    { label = 'Sandstorm',      value = 'SANDSTORM' },
    { label = 'Hurricane',      value = 'HURRICANE' },
}

Config.BanDurations = {
    { label = '1 Hour',    hours = 1 },
    { label = '24 Hours',  hours = 24 },
    { label = '1 Week',    hours = 168 },
    { label = '1 Month',   hours = 720 },
    { label = 'Permanent', hours = -1 },
}

Config.Jobs = {
    { label = 'Lawman',   name = 'lawman' },
    { label = 'Doctor',   name = 'doctor' },
    { label = 'Sheriff',  name = 'sheriff' },
}

Config.AnnouncePrefix = '[ADMIN]'
