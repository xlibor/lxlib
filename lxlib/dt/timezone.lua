
local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

local dtBase = require('lxlib.dt.base.date')

local timezones = {
    ["Pacific/Midway"] = -11,
    ["Pacific/Samoa"] = -11,
    ["Pacific/Honolulu"] = -10,
    ["US/Alaska"] = -9,
    ["America/Los_Angeles"] = -8,
    ["America/Tijuana"] = -8,
    ["US/Arizona"] = -7,
    ["America/Chihuahua"] = -7,
    ["America/Mazatlan"] = -7,
    ["US/Mountain"] = -7,
    ["America/Managua"] = -6,
    ["US/Central"] = -6,
    ["America/Mexico_City"] = -6,
    ["America/Monterrey"] = -6,
    ["Canada/Saskatchewan"] = -6,
    ["America/Bogota"] = -5,
    ["US/Eastern"] = -5,
    ["US/East-Indiana"] = -5,
    ["America/Lima"] = -5,
    ["America/Bogota"] = -5,
    ["Canada/Atlantic"] = -4,
    ["America/Caracas"] = -4.5,
    ["America/La_Paz"] = -4,
    ["America/Santiago"] = -4,
    ["Canada/Newfoundland"] = -3.5,
    ["America/Sao_Paulo"] = -3,
    ["America/Argentina/Buenos_Aires"] = -3,
    ["America/Godthab"] = -3,
    ["America/Noronha"] = -2,
    ["Atlantic/Azores"] = -1,
    ["Atlantic/Cape_Verde"] = -1,
    ["Africa/Casablanca"] = 0,
    ["Europe/London"] = 0,
    ["Etc/Greenwich"] = 0,
    ["Europe/Lisbon"] = 0,
    ["Africa/Monrovia"] = 0,
    ["UTC"] = 0,
    ["Europe/Amsterdam"] = 1,
    ["Europe/Belgrade"] = 1,
    ["Europe/Berlin"] = 1,
    ["Europe/Bratislava"] = 1,
    ["Europe/Brussels"] = 1,
    ["Europe/Budapest"] = 1,
    ["Europe/Copenhagen"] = 1,
    ["Europe/Ljubljana"] = 1,
    ["Europe/Madrid"] = 1,
    ["Europe/Paris"] = 1,
    ["Europe/Prague"] = 1,
    ["Europe/Rome"] = 1,
    ["Europe/Sarajevo"] = 1,
    ["Europe/Skopje"] = 1,
    ["Europe/Stockholm"] = 1,
    ["Europe/Vienna"] = 1,
    ["Europe/Warsaw"] = 1,
    ["Africa/Lagos"] = 1,
    ["Europe/Zagreb"] = 1,
    ["Europe/Athens"] = 2,
    ["Europe/Bucharest"] = 2,
    ["Africa/Cairo"] = 2,
    ["Africa/Harare"] = 2,
    ["Europe/Helsinki"] = 2,
    ["Europe/Istanbul"] = 2,
    ["Asia/Jerusalem"] = 2,
    ["Africa/Johannesburg"] = 2,
    ["Europe/Riga"] = 2,
    ["Europe/Sofia"] = 2,
    ["Europe/Tallinn"] = 2,
    ["Europe/Vilnius"] = 2,
    ["Asia/Baghdad"] = 3,
    ["Asia/Kuwait"] = 3,
    ["Europe/Minsk"] = 3,
    ["Africa/Nairobi"] = 3,
    ["Asia/Riyadh"] = 3,
    ["Europe/Volgograd"] = 3,
    ["Asia/Tehran"] = 3.5,
    ["Asia/Muscat"] = 4,
    ["Asia/Baku"] = 4,
    ["Europe/Moscow"] = 4,
    ["Asia/Tbilisi"] = 4,
    ["Asia/Yerevan"] = 4,
    ["Asia/Kabul"] = 4.5,
    ["Asia/Karachi"] = 5,
    ["Asia/Tashkent"] = 5,
    ["Asia/Calcutta"] = 5.5,
    ["Asia/Kolkata"] = 5.5,
    ["Asia/Katmandu"] = 5.75,
    ["Asia/Almaty"] = 6,
    ["Asia/Dhaka"] = 6,
    ["Asia/Yekaterinburg"] = 6,
    ["Asia/Rangoon"] = 6.5,
    ["Asia/Bangkok"] = 7,
    ["Asia/Jakarta"] = 7,
    ["Asia/Novosibirsk"] = 7,
    ["Asia/Hong_Kong"] = 8,
    ["Asia/Chongqing"] = 8,
    ["Asia/Shanghai"] = 8,
    ["Asia/Krasnoyarsk"] = 8,
    ["Asia/Kuala_Lumpur"] = 8,
    ["Australia/Perth"] = 8,
    ["Asia/Singapore"] = 8,
    ["Asia/Taipei"] = 8,
    ["Asia/Ulan_Bator"] = 8,
    ["Asia/Urumqi"] = 8,
    ["Asia/Irkutsk"] = 9,
    ["Asia/Tokyo"] = 9,
    ["Asia/Seoul"] = 9,
    ["Australia/Adelaide"] = 9.5,
    ["Australia/Darwin"] = 9.5,
    ["Australia/Brisbane"] = 10,
    ["Australia/Canberra"] = 10,
    ["Pacific/Guam"] = 10,
    ["Australia/Hobart"] = 10,
    ["Australia/Melbourne"] = 10,
    ["Pacific/Port_Moresby"] = 10,
    ["Australia/Sydney"] = 10,
    ["Asia/Yakutsk"] = 10,
    ["Asia/Vladivostok"] = 11,
    ["Pacific/Auckland"] = 12,
    ["Pacific/Fiji"] = 12,
    ["Pacific/Kwajalein"] = 12,
    ["Asia/Kamchatka"] = 12,
    ["Asia/Magadan"] = 12,
    ["Pacific/Fiji"] = 12,
    ["Pacific/Auckland"] = 12,
    ["Pacific/Tongatapu"] = 13,
}

function _M:new(name)

    local this = {
        name = name,
        location = {}
    }

    return oo(this, mt)
end

function _M:ctor(name)

    local offsetValue, offsetSign= self:calcOffset(name)
    self.offsetSign = offsetSign 
    self.offset = offsetValue
end

function _M:calcOffset(name)

    local hour = timezones[name]

    if not hour then
        error('unsupported timezone')
    end

    local offset = hour * 3600
    local hourNum, hourDec = math.modf(hour)
    local minutes = '00'
    if hourDec > 0 then
        minutes = tostring(hourDec * 60)
    end
    local sign = hourNum
    if math.abs(hourNum) < 10 then
        sign = '0' .. sign
    end
    sign = (hourNum > 0 and '+' or '-') .. sign .. minutes

    return offset, sign
end

function _M:getName()

    return self.name
end

function _M:getOffset(dt)

    local offset = dt:getOffset() * 60

    local currOffset = self.offset

    return currOffset - offset
end

return _M

