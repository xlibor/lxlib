
local lx, _M, mt = oo{
    _cls_       = '',
    _bond_      = 'exceptionHandlerBond'
}

local app, lf, tb, str, new = lx.kit()

local fmt, smatch = string.format, string.match
local lh = lx.h

local redirect, response = lh.redirect, lh.response

function _M:new(log)

    local this = {
        log = log,
        dontReport = {}
    }

    return oo(this, mt)
end

function _M:report(e)

    if self:shouldReport(e) then
        -- self:log(e)
    end
end

function _M:render(e, ctx)
    
    e = self:prepareException(e)

    if e:__is 'httpResponseException' then 
        return e:getResponse()
    elseif e:__is 'authenticationException' then
        return self:unauthenticated(ctx, e)
    elseif e:__is('validationException') then
        return self:convertValidationException(e, ctx)
    end

    if self:isHttpException(e) then
        self:renderHttpException(e, ctx)
    else
        self:renderException(e, ctx)
    end
end

function _M.__:convertValidationException(e, ctx)

    if e.response then
        ctx.resp = e.response
        
        return e.response
    end
    local errors = e.validator:errors():getMsgs()
    local request = ctx.req
    if request.expectsJson then
        
        return ctx:json(errors, 422)
    end
    
    return redirect():back():withInput(request:input()):withErrors(errors)
end

function _M:prepareException(e)

    if e:__is('modelNotFoundException') then
        e = new('notFoundHttpException', e:getMsg(), 0, e)
    elseif e:__is('authorizationException') then

        e = new('httpException', 403, e:getMsg(), nil, nil, e)
    end
    
    return e
end

function _M:isHttpException(e)

    return e:__is 'httpException'
end

function _M:renderHttpException(e, ctx)
    
    local status = e:getStatusCode()
    local view = app.view

    local errorView = 'error.' .. status .. '.html'
    if view:exists(errorView) then
        ctx:view(errorView, e)
    else
        self:renderException(e, ctx)
    end
end
 
function _M:renderForConsole(output, e)

end

function _M:shouldReport(e)

    return not self:shouldntReport(e)
end

function _M.__:shouldntReport(e)

    if e:__is 'httpResponseException' then 
        return true
    end

    for _, excpType in ipairs(self.dontReport) do
        if e:__is(excpType) then 
            return true
        end
    end

    return false
end

function _M:renderException(e, ctx)
    
    local ecount = 1
    local pre = e.pre
    if pre then
        ecount = 2
    end
    local tpl = self:getTemplate()
    local content = self:getContent(e, ecount, 1)
    if pre then
        content = content .. self:getContent(pre,ecount, 2)
    end
    local ret = tpl .. content .. '\n    </body>\n</html>'

    local statusCode, headers = e.statusCode, e.headers

    if ctx then
        ctx.resp = ctx.resp:create(ret, statusCode, headers)
    else
        echo(ret)
    end
end

function _M.__:getContent(e, ecount, index)

    local status = e.statusCode
    local title = 'hi, looks like something went wrong.'
    if status == 404 then
        title = 'sorry, the page you are looking for could not be found.'
    end

    local traces = e:getTraceList()
    local traceInfo = {}
    local t
    for _, v in ipairs(traces) do
        t = self:formatPath(v.file, v.line)
        if v.func then
            t = 'at ' .. v.func .. ' ' .. t
        end
        tapd(traceInfo, '            <li>' .. t .. '</li>')
    end

    traces = str.join(traceInfo, '\n')

    local class = self:formatClass(e.__cls)
    local path = self:formatPath(e.file, e.line)
    local content = fmt([[
    <h2 class="block_exception clear_fix">
        <span class="exception_counter">%s/%s</span>
        <span class="exception_title">%s %s</span>
        <span class="exception_message">%s</span>
    </h2>]],
    index, ecount, class, path, e.msg)

    local content = content .. fmt([[
    
    <div class="block">
        <ol class="traces list_exception">
%s
        </ol>
    </div>
]], traces)

    local ret = fmt([[
    <div id="sf-resetcontent" class="sf-reset">
        <h1>%s</h1>
%s
    </div>
]], title, content)

    return ret
end

function _M.__:formatClass(class)

    local name = str.last(class, '.')

    local ret = fmt([[
<abbr title="%s" onclick="var f=this.innerHTML;this.innerHTML=this.title;this.title=f;">%s</abbr>]]
    , class, name)

    return ret
end

function _M.__:formatPath(path, line)

    local file = smatch(path, '(%w*%.lua)') or path
    line = line or '?'
    local ret = fmt([[
in <a title="%s line %s" onclick="var f=this.innerHTML;this.innerHTML=this.title;this.title=f;">%s line %s</a>:]]
, path, line, file, line)

    return ret
end

function _M.__:formatArgs()

end

function _M.__:getTemplate()

    return
[[<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="robots" content="noindex,nofollow" />
        <style>
            html{color:#000;background:#FFF;}body,div,dl,dt,dd,ul,ol,li,h1,h2,h3,h4,h5,h6,pre,code,form,fieldset,legend,input,textarea,p,blockquote,th,td{margin:0;padding:0;}table{border-collapse:collapse;border-spacing:0;}fieldset,img{border:0;}address,caption,cite,code,dfn,em,strong,th,var{font-style:normal;font-weight:normal;}li{list-style:none;}caption,th{text-align:left;}h1,h2,h3,h4,h5,h6{font-size:100%;font-weight:normal;}q:before,q:after{content:'';}abbr,acronym{border:0;font-variant:normal;}sup{vertical-align:text-top;}sub{vertical-align:text-bottom;}input,textarea,select{font-family:inherit;font-size:inherit;font-weight:inherit;}input,textarea,select{*font-size:100%;}legend{color:#000;}

            html { background: #eee; padding: 10px }
            img { border: 0; }
            #sf-resetcontent { width:970px; margin:0 auto; }
            .sf-reset { font: 11px Verdana, Arial, sans-serif; color: #333 }
            .sf-reset .clear { clear:both; height:0; font-size:0; line-height:0; }
            .sf-reset .clear_fix:after { display:block; height:0; clear:both; visibility:hidden; }
            .sf-reset .clear_fix { display:inline-block; }
            .sf-reset * html .clear_fix { height:1%; }
            .sf-reset .clear_fix { display:block; }
            .sf-reset, .sf-reset .block { margin: auto }
            .sf-reset abbr { border-bottom: 1px dotted #000; cursor: help; }
            .sf-reset p { font-size:14px; line-height:20px; color:#868686; padding-bottom:20px }
            .sf-reset strong { font-weight:bold; }
            .sf-reset a { color:#6c6159; cursor: default; }
            .sf-reset a img { border:none; }
            .sf-reset a:hover { text-decoration:underline; }
            .sf-reset em { font-style:italic; }
            .sf-reset h1, .sf-reset h2 { font: 20px Georgia, "Times New Roman", Times, serif }
            .sf-reset .exception_counter { background-color: #fff; color: #333; padding: 6px; float: left; margin-right: 10px; float: left; display: block; }
            .sf-reset .exception_title { margin-left: 3em; margin-bottom: 0.7em; display: block; }
            .sf-reset .exception_message { margin-left: 3em; display: block; }
            .sf-reset .traces li { font-size:14px; padding: 2px 4px; list-style-type:decimal; margin-left:20px; }
            .sf-reset .block { background-color:#FFFFFF; padding:10px 28px; margin-bottom:20px;
                -webkit-border-bottom-right-radius: 16px;
                -webkit-border-bottom-left-radius: 16px;
                -moz-border-radius-bottomright: 16px;
                -moz-border-radius-bottomleft: 16px;
                border-bottom-right-radius: 16px;
                border-bottom-left-radius: 16px;
                border-bottom:1px solid #ccc;
                border-right:1px solid #ccc;
                border-left:1px solid #ccc;
            }
            .sf-reset .block_exception { background-color:#ddd; color: #333; padding:20px;
                -webkit-border-top-left-radius: 16px;
                -webkit-border-top-right-radius: 16px;
                -moz-border-radius-topleft: 16px;
                -moz-border-radius-topright: 16px;
                border-top-left-radius: 16px;
                border-top-right-radius: 16px;
                border-top:1px solid #ccc;
                border-right:1px solid #ccc;
                border-left:1px solid #ccc;
                overflow: hidden;
                word-wrap: break-word;
            }
            .sf-reset a { background:none; color:#868686; text-decoration:none; }
            .sf-reset a:hover { background:none; color:#313131; text-decoration:underline; }
            .sf-reset ol { padding: 10px 0; }
            .sf-reset h1 { background-color:#FFFFFF; padding: 15px 28px; margin-bottom: 20px;
                -webkit-border-radius: 10px;
                -moz-border-radius: 10px;
                border-radius: 10px;
                border: 1px solid #ccc;
            }
        </style>
    </head>
    <body>
]]

end

return _M

