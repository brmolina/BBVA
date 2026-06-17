({
	helperMethod : function(component, event, helper) {
        var onlyOnce= component.get("v.onlyOnce");
        if(onlyOnce){
            var minutes = component.get("v.cookieLifetime");
            var recordId = component.get("v.recordId");
            var mostrarPopup = helper.checkCookie(recordId, minutes);
            if(mostrarPopup){
                component.set("v.isOpen", false);
            }
        }
	},

	checkError: function(component, event, helper) {
        var action = component.get("c.checkError");

        action.setParams({
          "assetID": component.get("v.recordId"),
          "errorType": component.get('v.PopUpMessage')
        });
        action.setCallback(this, function (response) {
          var state = response.getState();
          if (state === "SUCCESS") {
            console.log('>>>>> SUCCESS');
            if(response.getReturnValue() !== "none") {
                component.set("v.isOpen", true);
                component.set("v.PopUpMessage", response.getReturnValue());
                helper.helperMethod(component, event, helper);
            }
          } else {
            console.log('FALLO : ', JSON.stringify(response.getReturnValue()));
          }
        });
        $A.enqueueAction(action);
    },
    setCookie: function (cname, cvalue, minutes) {
        var d = new Date();
        d.setTime(d.getTime() + (minutes * 60 * 1000));
        var expires = "expires="+d.toUTCString();
        document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
	},
    getCookie: function(cname) {
        var name = cname + "=";
        var ca = document.cookie.split(';');
        for(var i = 0; i < ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0) === ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) === 0) {
                return c.substring(name.length, c.length);
            }
        }
        return "";
    },

	checkCookie: function(ident, minutes) {
        var id = this.getCookie(ident);
        if (id !== "") {
            return true;
        } else {
            if (ident !== "" && ident != null) {
                this.setCookie(ident, ident, minutes);
            }
            return false;
        }
    }
})