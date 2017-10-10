--	The bulk of this class is pulled from the Resizer bundle I edited it to fit my needs here
--	@author Nick Kelly(original author Jarrod Oberto &  Maikel D)
--	@version 1.0


local lx, _M, mt = oo{
    _cls_ = ''
}

local app, lf, tb, str = lx.kit()

function _M:new()

    local this = {
        file = nil,
        width = nil,
        new_width = nil,
        height = nil,
        new_height = nil,
        option = nil,
        image_resized = nil
    }
    
    return oo(this, mt)
end

--	The file object of the original image
--	@var File
--	Original width of the image being resized
--	@var int
--	New width of the image being resized
--	@var int
--	Original height of the image being resized
--	@var int
--	New height of the image being resized
--	@var int
--	Type of crop being performed
--	@var str
--	The resized image resource
--	@var resource

    Create multiple thumbs/resizes of an image
    Path to the original
    sizes
        width, height, crop type, path, quality

function _M:create(file, path, filename, sizes)

    local resized
    self.file = file
    if lf.isTbl(sizes) then
        resized = {}
        for _, size in pairs(sizes) do
            self.new_width = size[0]
            --$new_width;
            self.new_height = size[1]
            --$new_height;
            self.option = size[2]
            --crop type
            --ensure that the directory path exists
            if not is_dir(size[3]) then
                mkdir(size[3])
            end
            tapd(resized, self:do_resize(path .. filename, size[3] .. filename, size[4]))
        end
    end
    
    return resized
end

-- Resizes and/or crops an image.
-- @param mixed       image     resource or filepath
-- @param strung      save_path where to save the resized image
-- @param int (0-100) quality
-- @return bool

function _M.__:do_resize(image, save_path, image_quality)

    image = self:open_image(image)
    self.width = imagesx(image)
    self.height = imagesy(image)
    -- Get optimal width and height - based on option.
    local option_array = self:get_dimensions(self.new_width, self.new_height, self.option)
    local optimal_width = option_array['optimal_width']
    local optimal_height = option_array['optimal_height']
    -- Resample - create image canvas of x, y size.
    self.image_resized = imagecreatetruecolor(optimal_width, optimal_height)
    -- Retain transparency for PNG and GIF files.
    imagecolortransparent(self.image_resized, imagecolorallocatealpha(self.image_resized, 255, 255, 255, 127))
    imagealphablending(self.image_resized, false)
    imagesavealpha(self.image_resized, true)
    -- Create the new image.
    imagecopyresampled(self.image_resized, image, 0, 0, 0, 0, optimal_width, optimal_height, self.width, self.height)
    -- if option is 'crop' or 'fit', then crop too
    if self.option == 'crop' or self.option == 'fit' then
        self:crop(optimal_width, optimal_height, self.new_width, self.new_height)
    end
    -- Get extension of the output file
    local extension = str.lower(File.extension(save_path))
    local st = extension
    if st == 'jpg' then
    elseif st == 'jpeg' then
        if imagetypes() & IMG_JPG then
            imagejpeg(self.image_resized, save_path, image_quality)
        end
    elseif st == 'gif' then
        if imagetypes() & IMG_GIF then
            imagegif(self.image_resized, save_path)
        end
    elseif st == 'png' then
        -- Scale quality from 0-100 to 0-9
        scale_quality = round(image_quality / 100 * 9)
        -- Invert quality setting as 0 is best, not 9
        invert_scale_quality = 9 - scale_quality
        if imagetypes() & IMG_PNG then
            imagepng(self.image_resized, save_path, invert_scale_quality)
        end
    else 
        
        return false
    end
    -- Remove the resource for the resized image
    imagedestroy(self.image_resized)
    
    return true
end

-- Open a file, detect its mime-type and create an image resrource from it.
-- @param table file Attributes of file from the _FILES table
-- @return mixed

function _M.__:open_image(file)

    local sfile = new('sFile', file)
    -- If file isn't an table, we'll turn it into one
    if not lf.isTbl(file) then
        file = {type = sfile:getMimeType(), tmp_name = file}
    end
    local mime = file['type']
    local file_path = file['tmp_name']
    local st = mime
    if st == 'image/pjpeg' then
        -- IE6
    elseif st == 'image/jpeg' then
        img = @imagecreatefromjpeg(file_path)
    elseif st == 'image/gif' then
        img = @imagecreatefromgif(file_path)
    elseif st == 'image/png' then
        img = @imagecreatefrompng(file_path)
    else 
        img = false
    end
    
    return img
end

-- Return the image dimentions based on the option that was chosen.
-- @param int    new_width  The width of the image
-- @param int    new_height The height of the image
-- @param string option     Either exact, portrait, landscape, auto or crop.
-- @return table

function _M.__:get_dimensions(new_width, new_height, option)

    local st = option
    if st == 'exact' then
        optimal_width = new_width
        optimal_height = new_height
    elseif st == 'portrait' then
        optimal_width = self:get_size_by_fixed_height(new_height)
        optimal_height = new_height
    elseif st == 'landscape' then
        optimal_width = new_width
        optimal_height = self:get_size_by_fixed_width(new_width)
    elseif st == 'auto' then
        option_array = self:get_size_by_auto(new_width, new_height)
        optimal_width = option_array['optimal_width']
        optimal_height = option_array['optimal_height']
    elseif st == 'fit' then
        option_array = self:get_size_by_fit(new_width, new_height)
        optimal_width = option_array['optimal_width']
        optimal_height = option_array['optimal_height']
    elseif st == 'crop' then
        option_array = self:get_optimal_crop(new_width, new_height)
        optimal_width = option_array['optimal_width']
        optimal_height = option_array['optimal_height']
    end
    
    return {optimal_width = optimal_width, optimal_height = optimal_height}
end

-- Returns the width based on the image height.
-- @param int new_height The height of the image
-- @return int

function _M.__:get_size_by_fixed_height(new_height)

    local ratio = self.width / self.height
    local new_width = new_height * ratio
    
    return new_width
end

-- Returns the height based on the image width.
-- @param int new_width The width of the image
-- @return int

function _M.__:get_size_by_fixed_width(new_width)

    local ratio = self.height / self.width
    local new_height = new_width * ratio
    
    return new_height
end

-- Checks to see if an image is portrait or landscape and resizes accordingly.
-- @param int new_width  The width of the image
-- @param int new_height The height of the image
-- @return table

function _M.__:get_size_by_auto(new_width, new_height)

    local optimal_height
    local optimal_width
    -- Image to be resized is wider (landscape)
    if self.height < self.width then
        optimal_width = new_width
        optimal_height = self:get_size_by_fixed_width(new_width)
    elseif self.height > self.width then
        optimal_width = self:get_size_by_fixed_height(new_height)
        optimal_height = new_height
    else 
        if new_height < new_width then
            optimal_width = new_width
            optimal_height = self:get_size_by_fixed_width(new_width)
        elseif new_height > new_width then
            optimal_width = self:get_size_by_fixed_height(new_height)
            optimal_height = new_height
        else 
            -- Sqaure being resized to a square
            optimal_width = new_width
            optimal_height = new_height
        end
    end
    
    return {optimal_width = optimal_width, optimal_height = optimal_height}
end

-- Resizes an image so it fits entirely inside the given dimensions.
-- @param int new_width  The width of the image
-- @param int new_height The height of the image
-- @return table

function _M.__:get_size_by_fit(new_width, new_height)

    local height_ratio = self.height / new_height
    local width_ratio = self.width / new_width
    local max = max(height_ratio, width_ratio)
    
    return {optimal_width = self.width / max, optimal_height = self.height / max}
end

-- Attempts to find the best way to crop. Whether crop is based on the
-- image being portrait or landscape.
-- @param int new_width  The width of the image
-- @param int new_height The height of the image
-- @return table

function _M.__:get_optimal_crop(new_width, new_height)

    local optimal_ratio
    local height_ratio = self.height / new_height
    local width_ratio = self.width / new_width
    if height_ratio < width_ratio then
        optimal_ratio = height_ratio
    else 
        optimal_ratio = width_ratio
    end
    local optimal_height = self.height / optimal_ratio
    local optimal_width = self.width / optimal_ratio
    
    return {optimal_width = optimal_width, optimal_height = optimal_height}
end

-- Crops an image from its center.
-- @param int optimal_width  The width of the image
-- @param int optimal_height The height of the image
-- @param int new_width      The new width
-- @param int new_height     The new height
-- @return true

function _M.__:crop(optimal_width, optimal_height, new_width, new_height)

    -- Find center - this will be used for the crop
    local crop_start_x = optimal_width / 2 - new_width / 2
    local crop_start_y = optimal_height / 2 - new_height / 2
    local crop = self.image_resized
    local dest_offset_x = max(0, -crop_start_x)
    local dest_offset_y = max(0, -crop_start_y)
    crop_start_x = max(0, crop_start_x)
    crop_start_y = max(0, crop_start_y)
    local dest_width = min(optimal_width, new_width)
    local dest_height = min(optimal_height, new_height)
    -- Now crop from center to exact requested size
    self.image_resized = imagecreatetruecolor(new_width, new_height)
    imagealphablending(crop, true)
    imagealphablending(self.image_resized, false)
    imagesavealpha(self.image_resized, true)
    imagefilledrectangle(self.image_resized, 0, 0, new_width, new_height, imagecolorallocatealpha(self.image_resized, 255, 255, 255, 127))
    imagecopyresampled(self.image_resized, crop, dest_offset_x, dest_offset_y, crop_start_x, crop_start_y, dest_width, dest_height, dest_width, dest_height)
    
    return true
end

return _M

