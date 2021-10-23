local JSON = require('cjson')
local COOKIE = require('resty.cookie')
local JWT = require('resty.jwt')

Authorize = {}
-- 请求获取token验证码
function Authorize.authorizeCode()
    local point = os.getenv("SSO_AUTH_POINT")
    if not point then
        ngx.log(ngx.ERR, "sso auth point value is nil.")
        return
    end

    local client_id = os.getenv("SSO_CLIENT_ID")
    if not client_id then
        ngx.log(ngx.ERR, "sso client id value is nil.")
        return
    end

    local sso_callback_uri = os.getenv("SSO_CALLBACK_URI")
    if not sso_callback_uri then
        ngx.log(ngx.ERR, "sso callback uri value is nil.")
        return
    end

    local redirect_uri = ngx.escape_uri(ngx.var.uri)
    if not redirect_uri then
        ngx.log(ngx.ERR, "ngx uri value is nil.")
        return
    end

    local callback_uri = ngx.escape_uri(sso_callback_uri .. "?redirect=" ..
                                            redirect_uri)

    ngx.redirect(point .. "?client_id=" .. client_id ..
                     "&response_type=code&redirect_uri=" .. callback_uri, 302)
end

function Authorize.verification()
    if (ngx.var.scheme ~= 'https') then
        ngx.log(ngx.ERR, 'site scheme not is https.')
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
    end

    local cookie, err = COOKIE:new()
    if not cookie then
        ngx.log(ngx.ERR, err)
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
    end

    local sid, err = cookie:get("_sid")
    if not sid then
        ngx.log(ngx.ERR, "get user token failed.", err)
        Authorize.authorizeCode()
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
    end

    local key = os.getenv('APP_JWT_KEY')
    local jwt = JWT:verify(key, sid)

    if (jwt.verified == false) then
        -- ngx.say(os.getenv('APP_JWT_KEY'))
        Authorize.authorizeCode()
        ngx.exit(ngx.HTTP_FORBIDDEN)
        return
    end
end

function Authorize.callback()
    local code = ngx.var.arg_code
    if (code == nil) then ngx.redirect("/", 302) end

    local httpc = require("resty.http").new()
    local res, err = httpc:request_uri("https://sso.humanrisk.cn/oauth/token", {
        method = "POST",
        ssl_verify = false,
        body = "code=" .. code .. "&grant_type=authorization_code&scope=*",
        headers = {["Content-Type"] = "application/x-www-form-urlencoded"}
    })
    if not res then
        ngx.log(ngx.ERR, "request failed: ", err)
        return
    end

    local status = res.status
    local length = res.headers["Content-Length"]
    local body = res.body
    local access = JSON.decode(res.body)

    local cookie, err = COOKIE:new()
    if not cookie then
        ngx.log(ngx.ERR, err)
        return
    end

    local ok, err = cookie:set({
        key = "_sid",
        value = access.access_token,
        path = "/",
        secure = true,
        httponly = true,
        expires = "Wed, 09 Jun 2029 10:18:14 GMT",
        max_age = 60 * 60 * 24 * 30,
        samesite = "Strict",
        extension = "a4334aebaec"
    })

    if not ok then
        ngx.log(ngx.ERR, err)
        return
    end

    -- ngx.say("<p>body: " .. body .. "</p>")
    -- ngx.say("<p>access_token: " .. access.access_token .. "</p>")
    -- ngx.say("<p>expires_in: " .. access.expires_in .. "</p>")
    -- ngx.say("<p>userid: " .. access.user.Id .. "</p>")
    -- ngx.say("<p>username: " .. access.user.Username .. "</p>")
    -- ngx.say("<p>EMail: " .. access.user.EMail .. "</p>")
    -- ngx.say("<p>Mobile: " .. access.user.Mobile .. "</p>")

    local redirect = ngx.unescape_uri(ngx.var.arg_redirect)
    -- ngx.say("<p>redirect: " .. redirect .. "</p>")

    ngx.redirect(redirect, 302)
end

return Authorize
