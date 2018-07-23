









function love.conf(t)
	local w, m = t.window, t.modules
 --[[
	t.identity		= nil
	t.console		= false
	t.gammacorrect	= false
	t.externalstorage	= false

	w.minwidth	= 1
	w.minheight	= 1
	w.vsync		= true
	w.msaa		= 0
	w.display	= 1
	w.highdpi	= false
	w.x			= nil
	w.y			= nil
	w.icon		= nil
	w.resizable	= false
	w.fullscreen	= false
	w.fullscreentype	= 'desktop'

	w.width		= 900
	w.height	= 480
	w.borderless	= true

	m.event		= true
	m.graphics	= true
	m.image		= true
	m.math		= true
	m.mouse		= true
	m.system	= true
	m.timer		= true
	m.touch		= true
	m.window	= true
 --]]

	t.version		= '11.1'
	t.accelerometerjoystick	= false

	w.title		= 'kwarto'

	m.audio		= false
	m.sound		= false
	m.video		= false
	m.physics	= false
	m.joystick	= false
	m.keyboard	= false
end
