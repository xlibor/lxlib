--Use Admin\Libraries\Includes\Resize as Resize;
-- @package Multup
-- @version 0.2.0
-- @author Nick Kelly @ Frozen Node
-- @link github.com/
-- Requires Validator, URL, and Str class from Laravel if used


local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        image = nil,
        rules = nil,
        random = nil,
        path = nil,
        input = nil,
        random_length = 32,
        random_cb = nil,
        image_sizes = nil,
        upload_callback = nil,
        upload_callback_args = nil
    }
    
    return oo(this, mt)
end

    image table

    string of laravel validation rules

    randomize uploaded filename

    path relative to /public/ that the image should be saved in

    id/name of the file input to find

    How long the random filename should be
--	Callback function for setting your own random filename
-- Sizing information for thumbs to create
-- table ( width, height, crop_type, path_to_save, quality)
--	Upload callback function to be called after an image is done being uploaded
--	@var function/closure
--	Arry of additional arguements to be passed into the callback function
--	@var table
-- Instantiates the Multup.
-- @param mixed file The file table provided by Laravel's Input::file('field_name') or a path to a file

function _M:ctor(input, rules, path, random)

    self.input = input
    self.rules = rules
    self.path = path
    self.random = random
end

-- Static call, Laravel style.
-- Returns a new Multup object, allowing for chainable calls.
-- @param string input  name of the file to upload
-- @param string rules  laravel style validation rules string
-- @param string path   relative to /public/ to move the images if valid
-- @param bool   random Whether or not to randomize the filename, the filename will be set to a 32 character string if true
-- @return Multup

function _M.s__.open(input, rules, path, random)

    random = lf.needTrue(random)
    
    return new('self', input, rules, path, random)
end

--	Set the length of the randomized filename
--   @param int len

function _M:set_length(len)

    self.random_length = len
    
    return self
end

--	Upload the image
--	@return table of results
--			each result will be an table() with keys:
--			errors table -> empty if saved properly, otherwise validation->errors object
--			path string -> full URL to the file if saved, empty if not saved
--			filename string -> name of the saved file or file that could not be uploaded
function _M:upload()

    self.image = {['self.input'] = Input.file(self.input)}
    local result = {}
    tapd(result, self:post_upload_process(self:upload_image()))
    
    return result
    if image then
        self.image = {['self.input'] = {
            name = image:getClientOriginalName(),
            type = image:getClientMimeType(),
            tmp_name = image:getFilename(),
            error = image:getError(),
            size = image:getSize()
        }}
        tapd(result, self:post_upload_process(self:upload_image()))
    end
    
    return result
    if not lf.isTbl(images) then
        self.image = {['self.input'] = images}
        tapd(result, self:post_upload_process(self:upload_image()))
    else 
        size = count(images['name'])
        for i = 0 + 1,size + 1 do
            self.image = {['self.input'] = {
                name = images['name'][i],
                type = images['type'][i],
                tmp_name = images['tmp_name'][i],
                error = images['error'][i],
                size = images['size'][i]
            }}
            tapd(result, self:post_upload_process(self:upload_image()))
        end
    end
    
    return result
end

--	Upload the image

function _M.__:upload_image()

    /* validate the image */
    local validation = Validator.make(self.image, {['self.input'] = self.rules})
    local errors = {}
    local original_name = self.image[self.input]:getClientOriginalName()
    local path = ''
    local filename = ''
    local resizes = ''
    if validation:fails() then
        /* use the messages object for the erros */
        errors = str.join(validation:messages():all(), '. ')
    else 
        if self.random then
            if lf.isCallable(self.random_cb) then
                filename = lf.call(self.random_cb, original_name)
            else 
                ext = File.extension(original_name)
                filename = self:generate_random_filename() .. '.' .. ext
            end
        else 
            filename = original_name
        end
        /* upload the file */
        save = self.image[self.input]:move(self.path, filename)
        --$save = Input::upload($this->input, this->path, filename);
        if save then
            path = self.path .. filename
            if lf.isTbl(self.image_sizes) then
                resizer = new('resize')
                resizes = resizer:create(save, self.path, filename, self.image_sizes)
            end
        else 
            errors = 'Could not save image'
        end
    end
    
    return compact('errors', 'path', 'filename', 'original_name', 'resizes')
end

-- Default random filename generation

function _M.__:generate_random_filename()

    return str.random(self.random_length)
end

-- Default random filename generation

function _M:filename_callback(func)

    if lf.isCallable(func) then
        self.random_cb = func
    end
    
    return self
end

    Set the callback function to be called after each image is done uploading
    @var mixed anonymous function or string name of function

function _M:after_upload(cb, args)

    args = args or ''
    if lf.isCallable(cb) then
        self.upload_callback = cb
        self.upload_callback_args = args
    else 
        /* some sort of error... */
    end
    
    return self
end

--	Sets the sizes for resizing the original
--  @param table(
--		array(
--			int width,  int height,  string 'exact, portrait, landscape, auto or crop', string 'path/to/file.jpg',  int quality
--		)
--	)
function _M:sizes(sizes)

    self.image_sizes = sizes
    
    return self
end

    Called after an image is successfully uploaded
    The function will append the vars to the images property
    If an after_upload function has been defined it will also append a variable to the table
        named callback_result

    @var table
        path
        resize ->this will be empty as the resize has not yet occurred
        filename -> the name of the successfully uploaded file
    @return void

function _M.__:post_upload_process(args)

    if lf.isEmpty(args['errors']) then
        /* add the saved image to the images table thing */
        if lf.isCallable(self.upload_callback) then
            if not lf.isEmpty(self.upload_callback_args) and lf.isTbl(self.upload_callback_args) then
                args = tb.merge(self.upload_callback_args, args)
            end
            args['callback_result'] = lf.call(self.upload_callback, args)
        end
    end
    
    return args
end

return _M

