
.pragma library

function createAppIdDbus(app_id) {
  var app_id_dbus = ''
  for (var i=0;i<app_id.length;i++) {
    var c = app_id.charCodeAt(i)
		if (((c >= 'a'.charCodeAt()) && (c <= 'z'.charCodeAt()))
			    || ((c >= 'A'.charCodeAt()) && (c <= 'Z'.charCodeAt()))
			    || ((c >= '0'.charCodeAt()) && (c <= '9'.charCodeAt()))) {
				app_id_dbus += String.fromCharCode(c)
			} else {
				app_id_dbus += '_'
        var hex = Number(c).toString(16)
        if(hex.length < 2)
          app_id_dbus += '0'
				app_id_dbus += hex
			}
  }
  return app_id_dbus
}

function createDesktopFileName(app_name, app_full_name) {
  return app_full_name + "_" + app_name
}
