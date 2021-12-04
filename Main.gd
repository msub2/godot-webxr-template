extends Spatial
 
var webxr_interface
var vr_supported = false
 
func _ready() -> void:
	$Button.connect("pressed", self, "_on_Button_pressed")
 
	webxr_interface = ARVRServer.find_interface("WebXR")
	if webxr_interface:
		# WebXR uses a lot of asynchronous callbacks, so we connect to various
		# signals in order to receive them.
		webxr_interface.connect("session_supported", self, "_webxr_session_supported")
		webxr_interface.connect("session_started", self, "_webxr_session_started")
		webxr_interface.connect("session_ended", self, "_webxr_session_ended")
		webxr_interface.connect("session_failed", self, "_webxr_session_failed")
 
		webxr_interface.connect("select", self, "_webxr_on_select")
		webxr_interface.connect("selectstart", self, "_webxr_on_select_start")
		webxr_interface.connect("selectend", self, "_webxr_on_select_end")
 
		webxr_interface.connect("squeeze", self, "_webxr_on_squeeze")
		webxr_interface.connect("squeezestart", self, "_webxr_on_squeeze_start")
		webxr_interface.connect("squeezeend", self, "_webxr_on_squeeze_end")
 
		# This returns immediately - our _webxr_session_supported() method 
		# (which we connected to the "session_supported" signal above) will
		# be called sometime later to let us know if it's supported or not.
		webxr_interface.is_session_supported("immersive-vr")
 
	$ARVROrigin/LeftController.connect("button_pressed", self, "_on_LeftController_button_pressed")
	$ARVROrigin/LeftController.connect("button_release", self, "_on_LeftController_button_release")
 
func _webxr_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode == 'immersive-vr':
		vr_supported = supported
 
func _on_Button_pressed() -> void:
	if not vr_supported:
		OS.alert("Your browser doesn't support VR")
		return
 
	# We want an immersive VR session, as opposed to AR ('immersive-ar') or a
	# simple 3DoF viewer ('viewer').
	webxr_interface.session_mode = 'immersive-vr'
	# 'bounded-floor' is room scale, 'local-floor' is a standing or sitting
	# experience (it puts you 1.6m above the ground if you have 3DoF headset),
	# whereas as 'local' puts you down at the ARVROrigin.
	# This list means it'll first try to request 'bounded-floor', then 
	# fallback on 'local-floor' and ultimately 'local', if nothing else is
	# supported.
	webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
	# In order to use 'local-floor' or 'bounded-floor' we must also
	# mark the features as required or optional.
	webxr_interface.required_features = 'local-floor'
	webxr_interface.optional_features = 'bounded-floor'
 
	# This will return false if we're unable to even request the session,
	# however, it can still fail asynchronously later in the process, so we
	# only know if it's really succeeded or failed when our 
	# _webxr_session_started() or _webxr_session_failed() methods are called.
	if not webxr_interface.initialize():
		OS.alert("Failed to initialize")
		return
 
func _webxr_session_started() -> void:
	$Button.visible = false
	# This tells Godot to start rendering to the headset.
	get_viewport().arvr = true
	# This will be the reference space type you ultimately got, out of the
	# types that you requested above. This is useful if you want the game to
	# work a little differently in 'bounded-floor' versus 'local-floor'.
	print ("Reference space type: " + webxr_interface.reference_space_type)
 
func _webxr_session_ended() -> void:
	$Button.visible = true
	# If the user exits immersive mode, then we tell Godot to render to the web
	# page again.
	get_viewport().arvr = false
 
func _webxr_session_failed(message: String) -> void:
	OS.alert("Failed to initialize: " + message)
 
func _on_LeftController_button_pressed(button: int) -> void:
	print ("Button pressed: " + str(button))
 
func _on_LeftController_button_release(button: int) -> void:
	print ("Button release: " + str(button))
 
func _process(delta: float) -> void:
	var left_controller_id = 100
	var thumbstick_x_axis_id = 2
	var thumbstick_y_axis_id = 3
 
	var thumbstick_vector := Vector2(
		Input.get_joy_axis(left_controller_id, thumbstick_x_axis_id),
		Input.get_joy_axis(left_controller_id, thumbstick_y_axis_id))
 
	if thumbstick_vector != Vector2.ZERO:
		print ("Left thumbstick position: " + str(thumbstick_vector))
 
func _webxr_on_select(controller_id: int) -> void:
	print("Select: " + str(controller_id))
 
	var controller: ARVRPositionalTracker = webxr_interface.get_controller(controller_id)
	print (controller.get_orientation())
	print (controller.get_position())
 
func _webxr_on_select_start(controller_id: int) -> void:
	print("Select Start: " + str(controller_id))
 
func _webxr_on_select_end(controller_id: int) -> void:
	print("Select End: " + str(controller_id))
 
func _webxr_on_squeeze(controller_id: int) -> void:
	print("Squeeze: " + str(controller_id))
 
func _webxr_on_squeeze_start(controller_id: int) -> void:
	print("Squeeze Start: " + str(controller_id))
 
func _webxr_on_squeeze_end(controller_id: int) -> void:
	print("Squeeze End: " + str(controller_id))
