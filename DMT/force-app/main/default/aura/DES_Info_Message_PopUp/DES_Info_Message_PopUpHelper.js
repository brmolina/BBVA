({
	helperMethod : function() {

	},
    setCookie: function (cname1, cvalue, minutes) {
        var d = new Date();
        d.setTime(d.getTime() + (minutes * 60 * 1000));
        var expires = "expires="+d.toUTCString();
        document.cookie = cname1 + "=" + cvalue + ";" + expires + ";path=/";
	},
    getCookie: function(cname1) {
        var name = cname1 + "=";
        var ca = document.cookie.split(';');
        for(var i = 0; i < ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0) == ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) == 0) {
                return c.substring(name.length, c.length);
            }
        }
        return "";
    },

	checkCookie: function(ident1, minutes) {
        var id = this.getCookie(ident1);
        if (id != "") {
            return true;
        } else {
            if (ident1 != "" && ident1 != null) {
                this.setCookie(ident1, ident1, minutes);
            }
            return false;
        }
    }
})