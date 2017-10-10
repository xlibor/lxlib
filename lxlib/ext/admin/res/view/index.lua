?>
<div id="admin_page" class="with_sidebar">
	<div id="sidebar">
		<div class="panel sidebar_section" id="filters_sidebar_section" data-bind="template: 'filtersTemplate'"></div>
	</div>
	<div id="content" data-bind="template: 'adminTemplate'"></div>
</div>

<script type="text/javascript">
	var site_url = "<?php 
echo(Request.url())
?>",
		base_url = "<?php 
echo(baseUrl)
?>/",
		asset_url = "<?php 
echo(assetUrl)
?>",
		file_url = "<?php 
echo(route('admin_display_file', {config:getOption('name')}))
?>",
		rows_per_page_url = "<?php 
echo(route('admin_rows_per_page', {config:getOption('name')}))
?>",
		route = "<?php 
echo(route)
?>",
		csrf = "<?php 
echo(csrf_token())
?>",
		language = "<?php 
echo(app:conf('app.locale'))
?>",
		adminData = {
			primary_key: "<?php 
echo(primaryKey)
?>",
			<?php 
if itemId ~= nil then
    ?>
				id: "<?php 
    echo(itemId)
    ?>",
			<?php 
end
?>
			rows: <?php 
echo(lf.jsen(rows))
?>,
			rows_per_page: <?php 
echo(dataTable:getRowsPerPage())
?>,
			sortOptions: <?php 
echo(lf.jsen(dataTable:getSort()))
?>,
			model_name: "<?php 
echo(config:getOption('name'))
?>",
			model_title: "<?php 
echo(config:getOption('heading'))
?>",
			sub_title: '<?php 
echo(config:getOption('subtitle', ''))
?>',
			model_single: "<?php 
echo(config:getOption('single'))
?>",
			expand_width: <?php 
echo(formWidth)
?>,
			actions: <?php 
echo(lf.jsen(actions))
?>,
			global_actions: <?php 
echo(lf.jsen(globalActions))
?>,
			filters: <?php 
echo(lf.jsen(filters))
?>,
			edit_fields: <?php 
echo(lf.jsen(arrayFields))
?>,
			data_model: <?php 
echo(lf.jsen(dataModel))
?>,
			column_model: <?php 
echo(lf.jsen(columnModel))
?>,
			action_permissions: <?php 
echo(lf.jsen(actionPermissions))
?>,
			languages: <?php 
echo(lf.jsen(trans('administrator::knockout')))
?>,
			// hack by @Monkey: for paging logic
			filter_by: "<?php 
echo(Request.get('filter_by'))
?>",
			filter_by_id: <?php 
echo(tonumber(Request.get('filter_by_id')))
?>
		};
</script>

<style type="text/css">

	div.item_edit form.edit_form select, div.item_edit form.edit_form input[type=hidden], div.item_edit form.edit_form .select2-container {
		width: <?php 
echo(formWidth - 59)
?>px !important;
	}

	div.item_edit form.edit_form .cke {
		width: <?php 
echo(formWidth - 67)
?>px !important;
	}

	div.item_edit form.edit_form div.markdown textarea {
		width: <?php 
echo(tonumber((formWidth - 75) / 2) - 12)
?>px !important;
		max-width: <?php 
echo(tonumber((formWidth - 75) / 2) - 12)
?>px !important;
	}

	div.item_edit form.edit_form div.markdown div.preview {
		width: <?php 
echo(tonumber((formWidth - 75) / 2))
?>px !important;
	}

	div.item_edit form.edit_form > div.image img, div.item_edit form.edit_form > div.image div.image_container {
		max-width: <?php 
echo(formWidth - 65)
?>px;
	}

</style>

<input type="hidden" name="_token" value="<?php 
echo(csrf_token())
?>" />

<script id="adminTemplate" type="text/html">
	<?php 
echo(view('administrator::templates.admin'))
?>
</script>

<script id="itemFormTemplate" type="text/html">
	<?php 
echo(view('administrator::templates.edit', {config = config}))
?>
</script>

<script id="filtersTemplate" type="text/html">
	<?php 
echo(view('administrator::templates.filters'))
?>
</script><?php 