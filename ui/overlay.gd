extends CanvasLayer
class_name VerdantOverlay

## Player-facing presentation for Verdant / 青野.
##
## The root bootstrap owns composition and calls setup(world). This overlay reads
## the public world state, listens for state_changed, and sends every gameplay
## request back through the world's application operations.

const BASE_CANVAS_SIZE := Vector2i(2560, 1440)
const SETTINGS_PATH := "user://verdant_ui.cfg"
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]
const QUALITY_LEVELS: Array[String] = ["low", "medium", "high"]

const FOREST := Color("#10231f")
const FOREST_DEEP := Color("#071411")
const FOREST_PANEL := Color(0.035, 0.09, 0.075, 0.91)
const FOREST_PANEL_SOFT := Color(0.035, 0.09, 0.075, 0.76)
const CREAM := Color("#fff9e9")
const CREAM_DIM := Color("#e2ddc8")
const LIME := Color("#c7ea70")
const LIME_SOFT := Color("#e0f2a6")
const LINE := Color(0.72, 0.86, 0.48, 0.30)

const COPY := {
	"en": {
		"eyebrow": "A QUIET FIELD STUDY",
		"title": "VERDANT",
		"subtitle": "Walk slowly. Look closely. Let the meadow move around you.",
		"start": "Start exploring",
		"settings": "Settings",
		"controls": "Controls",
		"quit": "Quit",
		"pause_eyebrow": "FIELD NOTES PAUSED",
		"paused": "Take a breath",
		"pause_body": "The meadow will wait here for you.",
		"resume": "Return to the meadow",
		"restart": "Restart route",
		"settings_title": "Settings",
		"language": "Language",
		"resolution": "Windowed resolution",
		"resolution_hint": "This target applies in windowed mode. Fullscreen uses the display's current resolution.",
		"window_mode": "Window mode",
		"windowed": "Windowed",
		"fullscreen": "Fullscreen",
		"quality": "Grass quality",
		"quality_low": "Low",
		"quality_medium": "Medium",
		"quality_high": "High",
		"wind": "Wind",
		"on": "On",
		"off": "Off",
		"volume": "Volume",
		"close": "Done",
		"display_status": "Current output: {width} × {height} · {mode}",
		"controls_title": "How to explore",
		"move": "Move",
		"look": "Look",
		"sprint": "Sprint",
		"visit": "Record viewpoint",
		"menu": "Pause menu",
		"move_keys": "W  A  S  D",
		"look_keys": "MOUSE",
		"sprint_keys": "SHIFT",
		"visit_keys": "E",
		"menu_keys": "ESC",
		"controls_note": "Move at your own pace. A viewpoint prompt appears when you are close enough to record it.",
		"progress_eyebrow": "FIELD ROUTE",
		"progress": "Viewpoints  {visited} / {total}",
		"route_hint": "Follow the paths and notice how the grass changes.",
		"visit_prompt": "E  ·  Record {name}",
		"visit_detail": "{description}  ·  {distance} m away",
		"complete_eyebrow": "FIELD ROUTE COMPLETE",
		"complete_title": "Three views, one living meadow",
		"complete_body": "Your route is complete. Stay a while, revisit a place, or begin again.",
		"keep_exploring": "Keep exploring",
		"hud_controls": "WASD  MOVE     MOUSE  LOOK     SHIFT  SPRINT     E  RECORD     ESC  MENU",
	},
	"zh": {
		"eyebrow": "一次安静的野外观察",
		"title": "青野",
		"subtitle": "慢慢走，细细看，让草野在身边舒展。",
		"start": "开始探索",
		"settings": "设置",
		"controls": "操作说明",
		"quit": "退出",
		"pause_eyebrow": "观察暂歇",
		"paused": "稍作停留",
		"pause_body": "草野会在这里等你回来。",
		"resume": "回到草野",
		"restart": "重新开始路线",
		"settings_title": "设置",
		"language": "语言",
		"resolution": "窗口分辨率",
		"resolution_hint": "此目标仅用于窗口模式；全屏模式使用显示器当前分辨率。",
		"window_mode": "窗口模式",
		"windowed": "窗口",
		"fullscreen": "全屏",
		"quality": "草地质量",
		"quality_low": "低",
		"quality_medium": "中",
		"quality_high": "高",
		"wind": "风动",
		"on": "开启",
		"off": "关闭",
		"volume": "音量",
		"close": "完成",
		"display_status": "当前输出：{width} × {height} · {mode}",
		"controls_title": "如何探索",
		"move": "移动",
		"look": "观察",
		"sprint": "快走",
		"visit": "记录观景点",
		"menu": "暂停菜单",
		"move_keys": "W  A  S  D",
		"look_keys": "鼠标",
		"sprint_keys": "SHIFT",
		"visit_keys": "E",
		"menu_keys": "ESC",
		"controls_note": "按自己的节奏前行。靠近观景点时，画面会提示你记录它。",
		"progress_eyebrow": "野外路线",
		"progress": "观景点  {visited} / {total}",
		"route_hint": "沿小径前行，留意草地细微的变化。",
		"visit_prompt": "E  ·  记录{name}",
		"visit_detail": "{description}  ·  距此 {distance} 米",
		"complete_eyebrow": "野外路线完成",
		"complete_title": "三处风景，一片生长的青野",
		"complete_body": "路线已经完成。你可以继续漫步、重访一处风景，或从头开始。",
		"keep_exploring": "继续探索",
		"hud_controls": "WASD  移动     鼠标  观察     SHIFT  快走     E  记录     ESC  菜单",
	},
}

var current_locale: String = "en"

var _world: Node
var _root: Control
var _main_layer: Control
var _pause_layer: Control
var _hud_layer: Control
var _completion_layer: Control
var _modal_layer: Control
var _settings_panel: PanelContainer
var _controls_panel: PanelContainer

var _progress_label: Label
var _route_hint_label: Label
var _prompt_panel: PanelContainer
var _prompt_title: Label
var _prompt_description: Label
var _display_status_label: Label
var _volume_value_label: Label

var _locale_buttons: Array[Button] = []
var _locale_option: OptionButton
var _resolution_option: OptionButton
var _window_option: OptionButton
var _quality_option: OptionButton
var _wind_option: OptionButton
var _volume_slider: HSlider
var _body_font: Font
var _title_font: Font

var _active_modal := ""
var _completion_dismissed := false
var _showing_completion := false
var _selected_resolution := Vector2i(2560, 1440)
var _selected_quality := "high"
var _wind_enabled := true
var _volume := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_load_locale()
	_build_interface()
	get_tree().root.content_scale_size = BASE_CANVAS_SIZE
	if not get_tree().root.size_changed.is_connected(_update_display_status):
		get_tree().root.size_changed.connect(_update_display_status)
	_refresh_copy()
	_refresh_from_world()
	call_deferred("_update_display_status")


## Injects the Content-owned application interface used by the overlay.
func setup(world: Node) -> void:
	var refresh_callable := Callable(self, "_refresh_from_world")
	if _world != null and _world.has_signal("state_changed"):
		if _world.is_connected("state_changed", refresh_callable):
			_world.disconnect("state_changed", refresh_callable)
	_world = world
	if _world != null and _world.has_signal("state_changed"):
		if not _world.is_connected("state_changed", refresh_callable):
			_world.connect("state_changed", refresh_callable)
	_apply_world_preferences()
	_refresh_from_world()


## Handles Escape requests routed by the root bootstrap.
func handle_escape() -> void:
	if _active_modal != "":
		_close_modal()
		return
	if _completion_layer != null and _completion_layer.visible:
		_keep_exploring()
		return
	if _world == null or not _world_started():
		return
	_call_world("set_paused", [not _world_paused()])


## Switches all player-facing copy immediately. Supported codes are en and zh.
func set_locale(code: String) -> void:
	if code != "en" and code != "zh":
		return
	current_locale = code
	_save_locale()
	_refresh_copy()
	_refresh_from_world()


func _build_interface() -> void:
	_root = Control.new()
	_root.name = "PlayerInterface"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _create_theme()
	add_child(_root)

	_build_main_menu()
	_build_hud()
	_build_pause_menu()
	_build_completion_panel()
	_build_modal_layer()


func _build_main_menu() -> void:
	_main_layer = _full_layer("MainMenu")
	var panel := _anchored_panel(Vector2(112.0, -560.0), Vector2(892.0, 430.0), Vector2(0.0, 0.5))
	panel.name = "TitlePanel"
	panel.add_theme_stylebox_override("panel", _panel_style(FOREST_PANEL, 28, 1))
	_main_layer.add_child(panel)

	var content := _panel_content(panel, 62, 58, 62, 58)
	content.add_child(_keyed_label("eyebrow", 22, LIME, false))
	content.add_child(_spacer(18))
	var title := _keyed_label("title", 88, CREAM, false)
	title.add_theme_font_override("font", _title_font)
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.35))
	content.add_child(title)
	content.add_child(_spacer(10))
	var subtitle := _keyed_label("subtitle", 30, CREAM_DIM, true)
	subtitle.custom_minimum_size = Vector2(0.0, 104.0)
	content.add_child(subtitle)
	content.add_child(_spacer(28))
	content.add_child(_fine_rule())
	content.add_child(_spacer(26))
	content.add_child(_make_locale_switch())
	content.add_child(_spacer(34))
	content.add_child(_keyed_button("start", _begin_exploration, true, false, "StartExploring"))
	content.add_child(_spacer(14))
	content.add_child(_keyed_button("settings", _open_settings, false, false, "MainSettings"))
	content.add_child(_spacer(14))
	content.add_child(_keyed_button("controls", _open_controls, false, false, "MainControls"))
	content.add_child(_spacer(14))
	content.add_child(_keyed_button("quit", _quit_game, false, true, "QuitFromTitle"))


func _build_hud() -> void:
	_hud_layer = _full_layer("HUD")
	var progress_panel := PanelContainer.new()
	progress_panel.name = "ProgressPanel"
	progress_panel.position = Vector2(86.0, 76.0)
	progress_panel.size = Vector2(570.0, 160.0)
	progress_panel.add_theme_stylebox_override("panel", _panel_style(FOREST_PANEL_SOFT, 22, 1))
	_hud_layer.add_child(progress_panel)
	var progress_box := _panel_content(progress_panel, 34, 22, 34, 22)
	progress_box.add_child(_keyed_label("progress_eyebrow", 19, LIME, false))
	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 35)
	_progress_label.add_theme_color_override("font_color", CREAM)
	progress_box.add_child(_progress_label)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "ViewpointPrompt"
	_prompt_panel.anchor_left = 0.5
	_prompt_panel.anchor_top = 1.0
	_prompt_panel.anchor_right = 0.5
	_prompt_panel.anchor_bottom = 1.0
	_prompt_panel.offset_left = -455.0
	_prompt_panel.offset_right = 455.0
	_prompt_panel.offset_top = -300.0
	_prompt_panel.offset_bottom = -132.0
	_prompt_panel.add_theme_stylebox_override("panel", _panel_style(FOREST_PANEL_SOFT, 22, 1))
	_hud_layer.add_child(_prompt_panel)
	var prompt_box := _panel_content(_prompt_panel, 34, 22, 34, 22)
	_prompt_title = Label.new()
	_prompt_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_title.add_theme_font_size_override("font_size", 30)
	_prompt_title.add_theme_color_override("font_color", LIME_SOFT)
	prompt_box.add_child(_prompt_title)
	_prompt_description = Label.new()
	_prompt_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_prompt_description.add_theme_font_size_override("font_size", 22)
	_prompt_description.add_theme_color_override("font_color", CREAM_DIM)
	prompt_box.add_child(_prompt_description)

	_route_hint_label = _keyed_label("route_hint", 22, CREAM, false)
	_route_hint_label.name = "RouteHint"
	_route_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_hint_label.anchor_left = 0.5
	_route_hint_label.anchor_top = 1.0
	_route_hint_label.anchor_right = 0.5
	_route_hint_label.anchor_bottom = 1.0
	_route_hint_label.offset_left = -520.0
	_route_hint_label.offset_right = 520.0
	_route_hint_label.offset_top = -214.0
	_route_hint_label.offset_bottom = -172.0
	_hud_layer.add_child(_route_hint_label)

	var controls_strip := Label.new()
	controls_strip.name = "ControlHints"
	controls_strip.set_meta("copy_key", "hud_controls")
	controls_strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_strip.anchor_left = 0.5
	controls_strip.anchor_top = 1.0
	controls_strip.anchor_right = 0.5
	controls_strip.anchor_bottom = 1.0
	controls_strip.offset_left = -980.0
	controls_strip.offset_right = 980.0
	controls_strip.offset_top = -92.0
	controls_strip.offset_bottom = -50.0
	controls_strip.add_theme_font_size_override("font_size", 19)
	controls_strip.add_theme_color_override("font_color", CREAM_DIM)
	_hud_layer.add_child(controls_strip)
	_set_mouse_ignore_recursively(_hud_layer)


func _build_pause_menu() -> void:
	_pause_layer = _full_layer("PauseMenu")
	_pause_layer.add_child(_backdrop(Color(0.01, 0.035, 0.028, 0.58)))
	var panel := _centered_panel(Vector2(780.0, 790.0))
	panel.name = "PausePanel"
	_pause_layer.add_child(panel)
	var content := _panel_content(panel, 62, 54, 62, 54)
	var eyebrow := _keyed_label("pause_eyebrow", 21, LIME, false)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	content.add_child(_spacer(12))
	var title := _keyed_label("paused", 58, CREAM, false)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(_spacer(8))
	var body := _keyed_label("pause_body", 27, CREAM_DIM, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size = Vector2(0.0, 68.0)
	content.add_child(body)
	content.add_child(_spacer(28))
	content.add_child(_keyed_button("resume", _resume_exploration, true, false, "Resume"))
	content.add_child(_spacer(13))
	content.add_child(_keyed_button("settings", _open_settings, false, false, "PauseSettings"))
	content.add_child(_spacer(13))
	content.add_child(_keyed_button("controls", _open_controls, false, false, "PauseControls"))
	content.add_child(_spacer(13))
	content.add_child(_keyed_button("restart", _restart_exploration, false, false, "RestartFromPause"))
	content.add_child(_spacer(13))
	content.add_child(_keyed_button("quit", _quit_game, false, true, "QuitFromPause"))


func _build_completion_panel() -> void:
	_completion_layer = _full_layer("RouteComplete")
	_completion_layer.add_child(_backdrop(Color(0.01, 0.035, 0.028, 0.40)))
	var panel := _centered_panel(Vector2(980.0, 620.0))
	panel.name = "CompletionPanel"
	_completion_layer.add_child(panel)
	var content := _panel_content(panel, 70, 54, 70, 54)
	var eyebrow := _keyed_label("complete_eyebrow", 21, LIME, false)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)
	content.add_child(_spacer(14))
	var title := _keyed_label("complete_title", 50, CREAM, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0.0, 126.0)
	content.add_child(title)
	var body := _keyed_label("complete_body", 27, CREAM_DIM, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size = Vector2(0.0, 108.0)
	content.add_child(body)
	content.add_child(_spacer(24))
	content.add_child(_keyed_button("keep_exploring", _keep_exploring, true, false, "KeepExploring"))
	content.add_child(_spacer(13))
	content.add_child(_keyed_button("restart", _restart_exploration, false, false, "RestartFromCompletion"))


func _build_modal_layer() -> void:
	_modal_layer = _full_layer("ModalLayer")
	_modal_layer.add_child(_backdrop(Color(0.005, 0.02, 0.016, 0.70)))

	_settings_panel = _centered_panel(Vector2(1160.0, 1160.0))
	_settings_panel.name = "SettingsPanel"
	_modal_layer.add_child(_settings_panel)
	var settings := _panel_content(_settings_panel, 72, 50, 72, 50)
	var settings_title := _keyed_label("settings_title", 52, CREAM, false)
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings.add_child(settings_title)
	settings.add_child(_spacer(22))
	settings.add_child(_fine_rule())
	settings.add_child(_spacer(22))

	var grid := GridContainer.new()
	grid.name = "SettingsGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 24)
	settings.add_child(grid)
	_add_setting_row(grid, "language", _build_language_option())
	_add_setting_row(grid, "resolution", _build_resolution_option())
	_add_setting_row(grid, "window_mode", _build_window_option())
	_add_setting_row(grid, "quality", _build_quality_option())
	_add_setting_row(grid, "wind", _build_wind_option())
	_add_setting_row(grid, "volume", _build_volume_control())

	_display_status_label = Label.new()
	_display_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_display_status_label.add_theme_font_size_override("font_size", 21)
	_display_status_label.add_theme_color_override("font_color", LIME_SOFT)
	settings.add_child(_display_status_label)
	var resolution_hint := _keyed_label("resolution_hint", 20, CREAM_DIM, true)
	resolution_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resolution_hint.custom_minimum_size = Vector2(0.0, 58.0)
	settings.add_child(resolution_hint)
	settings.add_child(_spacer(12))
	settings.add_child(_keyed_button("close", _close_modal, true, false, "SettingsDone"))

	_controls_panel = _centered_panel(Vector2(1060.0, 1000.0))
	_controls_panel.name = "ControlsPanel"
	_modal_layer.add_child(_controls_panel)
	var controls := _panel_content(_controls_panel, 72, 52, 72, 52)
	var controls_title := _keyed_label("controls_title", 52, CREAM, false)
	controls_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(controls_title)
	controls.add_child(_spacer(22))
	controls.add_child(_fine_rule())
	controls.add_child(_spacer(18))
	var controls_grid := GridContainer.new()
	controls_grid.name = "ControlsGrid"
	controls_grid.columns = 2
	controls_grid.add_theme_constant_override("h_separation", 42)
	controls_grid.add_theme_constant_override("v_separation", 17)
	controls.add_child(controls_grid)
	_add_control_row(controls_grid, "move", "move_keys")
	_add_control_row(controls_grid, "look", "look_keys")
	_add_control_row(controls_grid, "sprint", "sprint_keys")
	_add_control_row(controls_grid, "visit", "visit_keys")
	_add_control_row(controls_grid, "menu", "menu_keys")
	controls.add_child(_spacer(28))
	var note := _keyed_label("controls_note", 25, CREAM_DIM, true)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.custom_minimum_size = Vector2(0.0, 114.0)
	controls.add_child(note)
	controls.add_child(_spacer(12))
	controls.add_child(_keyed_button("close", _close_modal, true, false, "ControlsDone"))

	_modal_layer.visible = false


func _make_locale_switch() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "LanguageSwitch"
	row.add_theme_constant_override("separation", 12)
	for locale_data in [["en", "EN"], ["zh", "中文"]]:
		var button := Button.new()
		button.name = "LanguageEnglish" if locale_data[0] == "en" else "LanguageChinese"
		button.text = locale_data[1]
		button.custom_minimum_size = Vector2(126.0, 54.0)
		button.add_theme_font_size_override("font_size", 23)
		button.pressed.connect(set_locale.bind(locale_data[0]))
		button.set_meta("locale_code", locale_data[0])
		_apply_compact_button_style(button)
		_locale_buttons.append(button)
		row.add_child(button)
	return row


func _build_language_option() -> OptionButton:
	_locale_option = _option_button("Language")
	_locale_option.item_selected.connect(_on_locale_selected)
	return _locale_option


func _build_resolution_option() -> OptionButton:
	_resolution_option = _option_button("Resolution")
	_resolution_option.add_item("2560 × 1440")
	_resolution_option.add_item("3840 × 2160")
	_resolution_option.item_selected.connect(_on_resolution_selected)
	return _resolution_option


func _build_window_option() -> OptionButton:
	_window_option = _option_button("WindowMode")
	_window_option.item_selected.connect(_on_window_mode_selected)
	return _window_option


func _build_quality_option() -> OptionButton:
	_quality_option = _option_button("Quality")
	_quality_option.item_selected.connect(_on_quality_selected)
	return _quality_option


func _build_wind_option() -> OptionButton:
	_wind_option = _option_button("Wind")
	_wind_option.item_selected.connect(_on_wind_selected)
	return _wind_option


func _build_volume_control() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(550.0, 70.0)
	row.add_theme_constant_override("separation", 22)
	_volume_slider = HSlider.new()
	_volume_slider.name = "Volume"
	_volume_slider.custom_minimum_size = Vector2(420.0, 54.0)
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.01
	_volume_slider.value = _volume
	_volume_slider.value_changed.connect(_on_volume_changed)
	row.add_child(_volume_slider)
	_volume_value_label = Label.new()
	_volume_value_label.custom_minimum_size = Vector2(90.0, 54.0)
	_volume_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_volume_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_volume_value_label.add_theme_color_override("font_color", LIME_SOFT)
	row.add_child(_volume_value_label)
	return row


func _add_setting_row(grid: GridContainer, copy_key: String, control: Control) -> void:
	var label := _keyed_label(copy_key, 27, CREAM, false)
	label.custom_minimum_size = Vector2(350.0, 70.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grid.add_child(label)
	grid.add_child(control)


func _add_control_row(grid: GridContainer, action_key: String, key_key: String) -> void:
	var action := _keyed_label(action_key, 28, CREAM, false)
	action.custom_minimum_size = Vector2(560.0, 64.0)
	action.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grid.add_child(action)
	var key_label := _keyed_label(key_key, 23, LIME_SOFT, false)
	key_label.custom_minimum_size = Vector2(280.0, 64.0)
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(key_label)


func _refresh_from_world() -> void:
	if _root == null:
		return
	var started := _world_started()
	var paused := _world_paused()
	var viewpoints := _get_viewpoints()
	var total := viewpoints.size() if not viewpoints.is_empty() else 3
	var visited := clampi(_world_int("visited_count", 0), 0, total)
	var completed := visited >= total
	if not completed:
		_completion_dismissed = false
		_showing_completion = false
	elif not _completion_dismissed and not _showing_completion:
		_showing_completion = true
		if not paused:
			_call_world("set_paused", [true])
			paused = _world_paused()

	_main_layer.visible = not started
	_pause_layer.visible = started and paused and not _showing_completion
	_hud_layer.visible = started and not paused
	_completion_layer.visible = started and completed and _showing_completion
	_progress_label.text = _l("progress").format({"visited": visited, "total": total})

	var nearest := _world_int("nearest_viewpoint", -1)
	var visit_distance := _world_float("visit_distance", 1000.0)
	var can_visit := nearest >= 0 and nearest < viewpoints.size() and visit_distance <= 3.0
	_prompt_panel.visible = can_visit and not completed
	_route_hint_label.visible = not can_visit and not completed
	if can_visit:
		var viewpoint: Dictionary = viewpoints[nearest]
		var suffix := "en" if current_locale == "en" else "zh"
		var point_name := str(viewpoint.get("name_" + suffix, ""))
		var description := str(viewpoint.get("description_" + suffix, ""))
		var distance := maxf(visit_distance, 0.0)
		_prompt_title.text = _l("visit_prompt").format({"name": point_name})
		_prompt_description.text = _l("visit_detail").format({
			"description": description,
			"distance": roundi(distance),
		})

	_update_pointer_mode()


func _refresh_copy() -> void:
	if _root == null:
		return
	_apply_copy_recursively(_root)
	for button in _locale_buttons:
		var selected := str(button.get_meta("locale_code")) == current_locale
		button.add_theme_color_override("font_color", LIME if selected else CREAM_DIM)
		button.add_theme_color_override("font_hover_color", LIME)
	_refresh_options()
	_update_volume_label()
	_update_display_status()


func _apply_copy_recursively(node: Node) -> void:
	if node.has_meta("copy_key"):
		var value := _l(str(node.get_meta("copy_key")))
		if node is Label:
			(node as Label).text = value
		elif node is Button:
			(node as Button).text = value
	for child in node.get_children():
		_apply_copy_recursively(child)


func _refresh_options() -> void:
	if _locale_option == null:
		return
	_rebuild_option(_locale_option, ["English", "简体中文"], 0 if current_locale == "en" else 1)
	_rebuild_option(_window_option, [_l("windowed"), _l("fullscreen")], _current_window_mode_index())
	_rebuild_option(
		_quality_option,
		[_l("quality_low"), _l("quality_medium"), _l("quality_high")],
		QUALITY_LEVELS.find(_selected_quality)
	)
	_rebuild_option(_wind_option, [_l("on"), _l("off")], 0 if _wind_enabled else 1)
	_resolution_option.select(RESOLUTIONS.find(_selected_resolution))


func _rebuild_option(option: OptionButton, labels: Array, selected_index: int) -> void:
	option.clear()
	for label in labels:
		option.add_item(str(label))
	option.select(maxi(selected_index, 0))


func _begin_exploration() -> void:
	_completion_dismissed = false
	_showing_completion = false
	_call_world("begin_exploration")
	_refresh_from_world()


func _resume_exploration() -> void:
	_call_world("set_paused", [false])


func _restart_exploration() -> void:
	_completion_dismissed = false
	_showing_completion = false
	_active_modal = ""
	_modal_layer.visible = false
	_call_world("restart_exploration")
	_refresh_from_world()


func _keep_exploring() -> void:
	_completion_dismissed = true
	_showing_completion = false
	_call_world("set_paused", [false])
	_refresh_from_world()


func _open_settings() -> void:
	_active_modal = "settings"
	_settings_panel.visible = true
	_controls_panel.visible = false
	_modal_layer.visible = true
	_update_pointer_mode()


func _open_controls() -> void:
	_active_modal = "controls"
	_settings_panel.visible = false
	_controls_panel.visible = true
	_modal_layer.visible = true
	_update_pointer_mode()


func _close_modal() -> void:
	_active_modal = ""
	_modal_layer.visible = false
	_refresh_from_world()


func _quit_game() -> void:
	get_tree().quit()


func _on_locale_selected(index: int) -> void:
	set_locale("en" if index == 0 else "zh")


func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return
	_selected_resolution = RESOLUTIONS[index]
	if _current_window_mode_index() == 0:
		DisplayServer.window_set_size(_selected_resolution)
	call_deferred("_update_display_status")


func _on_window_mode_selected(index: int) -> void:
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_selected_resolution)
		_center_window_deferred.call_deferred()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	call_deferred("_update_display_status")


func _center_window_deferred() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var window_size := DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen_size - window_size) / 2)


func _on_quality_selected(index: int) -> void:
	if index < 0 or index >= QUALITY_LEVELS.size():
		return
	_selected_quality = QUALITY_LEVELS[index]
	_call_world("set_quality", [_selected_quality])


func _on_wind_selected(index: int) -> void:
	_wind_enabled = index == 0
	_call_world("set_wind_enabled", [_wind_enabled])


func _on_volume_changed(value: float) -> void:
	_volume = value
	_update_volume_label()
	_call_world("set_volume", [_volume])


func _update_volume_label() -> void:
	if _volume_value_label != null:
		_volume_value_label.text = "%d%%" % roundi(_volume * 100.0)


func _update_display_status() -> void:
	if _display_status_label == null:
		return
	var size := DisplayServer.window_get_size()
	var mode := _l("windowed") if _current_window_mode_index() == 0 else _l("fullscreen")
	_display_status_label.text = _l("display_status").format({
		"width": size.x,
		"height": size.y,
		"mode": mode,
	})


func _current_window_mode_index() -> int:
	var mode := DisplayServer.window_get_mode()
	return 0 if mode == DisplayServer.WINDOW_MODE_WINDOWED else 1


func _apply_world_preferences() -> void:
	_call_world("set_quality", [_selected_quality])
	_call_world("set_wind_enabled", [_wind_enabled])
	_call_world("set_volume", [_volume])


func _call_world(method: StringName, arguments: Array = []) -> Variant:
	if _world == null or not _world.has_method(method):
		return null
	return _world.callv(method, arguments)


func _world_started() -> bool:
	return _world_bool("started", false)


func _world_paused() -> bool:
	return _world_bool("paused", false)


func _world_bool(property_name: StringName, fallback: bool) -> bool:
	if _world == null:
		return fallback
	var value: Variant = _world.get(property_name)
	return fallback if value == null else bool(value)


func _world_int(property_name: StringName, fallback: int) -> int:
	if _world == null:
		return fallback
	var value: Variant = _world.get(property_name)
	return fallback if value == null else int(value)


func _world_float(property_name: StringName, fallback: float) -> float:
	if _world == null:
		return fallback
	var value: Variant = _world.get(property_name)
	return fallback if value == null else float(value)


func _get_viewpoints() -> Array:
	if _world == null or not _world.has_method("get_viewpoints"):
		return []
	var result: Variant = _world.call("get_viewpoints")
	return result if result is Array else []


func _update_pointer_mode() -> void:
	var needs_pointer := (
		_active_modal != ""
		or _main_layer.visible
		or _pause_layer.visible
		or _completion_layer.visible
	)
	var desired_mode := Input.MOUSE_MODE_VISIBLE if needs_pointer else Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != desired_mode:
		Input.mouse_mode = desired_mode


func _load_locale() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		var saved := str(config.get_value("interface", "locale", "en"))
		if saved == "en" or saved == "zh":
			current_locale = saved


func _save_locale() -> void:
	var config := ConfigFile.new()
	config.set_value("interface", "locale", current_locale)
	config.save(SETTINGS_PATH)


func _l(key: String) -> String:
	var locale_copy: Dictionary = COPY.get(current_locale, COPY["en"])
	return str(locale_copy.get(key, key))


func _full_layer(node_name: String) -> Control:
	var control := Control.new()
	control.name = node_name
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(control)
	return control


func _backdrop(color: Color) -> ColorRect:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = color
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	return backdrop


func _anchored_panel(top_left: Vector2, bottom_right: Vector2, anchor: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = anchor.x
	panel.anchor_right = anchor.x
	panel.anchor_top = anchor.y
	panel.anchor_bottom = anchor.y
	panel.offset_left = top_left.x
	panel.offset_top = top_left.y
	panel.offset_right = bottom_right.x
	panel.offset_bottom = bottom_right.y
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel


func _centered_panel(size: Vector2) -> PanelContainer:
	var panel := _anchored_panel(-size / 2.0, size / 2.0, Vector2(0.5, 0.5))
	panel.add_theme_stylebox_override("panel", _panel_style(FOREST_PANEL, 30, 1))
	return panel


func _panel_content(panel: PanelContainer, left: int, top: int, right: int, bottom: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = "PanelMargin"
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "PanelContent"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)
	return box


func _keyed_label(copy_key: String, font_size: int, color: Color, wrap: bool) -> Label:
	var label := Label.new()
	label.set_meta("copy_key", copy_key)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _keyed_button(
	copy_key: String,
	action: Callable,
	accent := false,
	quiet := false,
	node_name := ""
) -> Button:
	var button := Button.new()
	button.name = node_name if node_name != "" else copy_key.to_pascal_case()
	button.set_meta("copy_key", copy_key)
	button.custom_minimum_size = Vector2(0.0, 72.0)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(action)
	_apply_button_style(button, accent, quiet)
	return button


func _option_button(node_name: String) -> OptionButton:
	var option := OptionButton.new()
	option.name = node_name
	option.custom_minimum_size = Vector2(550.0, 70.0)
	option.add_theme_font_size_override("font_size", 25)
	option.add_theme_color_override("font_color", CREAM)
	option.add_theme_color_override("font_hover_color", LIME_SOFT)
	option.add_theme_stylebox_override("normal", _button_style(Color(0.04, 0.12, 0.095, 0.92), LINE))
	option.add_theme_stylebox_override("hover", _button_style(Color(0.06, 0.16, 0.12, 0.96), LIME))
	option.add_theme_stylebox_override("focus", _button_style(Color.TRANSPARENT, LIME))
	return option


func _apply_button_style(button: Button, accent: bool, quiet: bool) -> void:
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", FOREST_DEEP if accent else CREAM)
	button.add_theme_color_override("font_hover_color", FOREST_DEEP if accent else LIME_SOFT)
	button.add_theme_color_override("font_pressed_color", FOREST_DEEP if accent else LIME)
	button.add_theme_color_override("font_focus_color", FOREST_DEEP if accent else CREAM)
	var normal_color := LIME if accent else Color(0.055, 0.14, 0.11, 0.88)
	if quiet:
		normal_color = Color(0.04, 0.09, 0.075, 0.62)
	button.add_theme_stylebox_override("normal", _button_style(normal_color, LIME if accent else LINE))
	button.add_theme_stylebox_override("hover", _button_style(LIME_SOFT if accent else Color(0.08, 0.20, 0.15, 0.96), LIME))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#9fc64c") if accent else Color(0.04, 0.12, 0.09, 1.0), LIME))
	button.add_theme_stylebox_override("focus", _button_style(Color.TRANSPARENT, LIME))


func _apply_compact_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_style(Color(0.04, 0.12, 0.095, 0.86), LINE))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.08, 0.20, 0.15, 0.96), LIME))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.04, 0.12, 0.09, 1.0), LIME))
	button.add_theme_stylebox_override("focus", _button_style(Color.TRANSPARENT, LIME))


func _panel_style(color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = LINE
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _button_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 13
	style.corner_radius_top_right = 13
	style.corner_radius_bottom_left = 13
	style.corner_radius_bottom_right = 13
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	return style


func _create_theme() -> Theme:
	var theme := Theme.new()
	var base_font: Font
	if ResourceLoader.exists("res://content/fonts/NotoSansSC[wght].ttf"):
		base_font = load("res://content/fonts/NotoSansSC[wght].ttf") as Font
	else:
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray([
			"Noto Sans CJK SC",
			"Noto Sans SC",
			"PingFang SC",
			"Microsoft YaHei",
			"Arial Unicode MS",
			"Noto Sans",
		])
		system_font.font_weight = 500
		base_font = system_font
	_body_font = _make_font_variation(base_font, 480.0)
	_title_font = _make_font_variation(base_font, 360.0)
	theme.default_font = _body_font
	theme.default_font_size = 28
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_color", "OptionButton", CREAM)
	theme.set_color("font_color", "PopupMenu", CREAM)
	theme.set_color("font_hover_color", "PopupMenu", FOREST_DEEP)
	theme.set_color("font_separator_color", "PopupMenu", CREAM_DIM)
	theme.set_stylebox("panel", "PopupMenu", _panel_style(Color(0.025, 0.075, 0.06, 0.98), 12, 1))
	theme.set_stylebox("hover", "PopupMenu", _button_style(LIME_SOFT, LIME))
	return theme


func _make_font_variation(base_font: Font, weight: float) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = base_font
	var text_server := TextServerManager.get_primary_interface()
	variation.variation_opentype = {text_server.name_to_tag("wght"): weight}
	return variation


func _fine_rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 1.0)
	rule.color = LINE
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func _spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _set_mouse_ignore_recursively(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore_recursively(child)
