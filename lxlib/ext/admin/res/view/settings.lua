?>
<div id="settings_page">
	<div id="content" data-bind="template: 'settingsTemplate'"></div>
</div>

<script type="text/javascript">
	var site_url = "<?php 
echo(url())
?>",
		base_url = "<?php 
echo(baseUrl)
?>/",
		asset_url = "<?php 
echo(assetUrl)
?>",
		save_url = "<?php 
echo(route('admin_settings_save', {config:getOption('name')}))
?>",
		custom_action_url = "<?php 
echo(route('admin_settings_custom_action', {config:getOption('name')}))
?>",
		file_url = "<?php 
echo(route('admin_settings_display_file', {config:getOption('name')}))
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
			name: "<?php 
echo(config:getOption('name'))
?>",
			title: "<?php 
echo(config:getOption('title'))
?>",
			data: <?php 
echo(lf.jsen(config:getDataModel()))
?>,
			actions: <?php 
echo(lf.jsen(actions))
?>,
			edit_fields: <?php 
echo(lf.jsen(arrayFields))
?>,
			languages: <?php 
echo(lf.jsen(trans('administrator::knockout')))
?>
		};
</script>

<input type="hidden" name="_token" value="<?php 
echo(csrf_token())
?>" />

<script id="settingsTemplate" type="text/html">
	<?php 
echo(view('administrator::templates.settings'))
?>
</script><?php 