window._ipUtils = (function() {

    return { //public API
        sucess: function(toastEvent, message, title) {
            if (title === null || title === "") {
                toastEvent.setParams({
                message: message,
                type: "success"
            });
            } else {
                toastEvent.setParams({
                title: title,
                message: message,
                type: "success"
            }); 
            }
           
            toastEvent.fire();
        },
        validation: function(toastEvent, message) {
            toastEvent.setParams({
                 mode: "sticky",
                title: "You encountered some errors when trying to save this record",
                message: message,
                type: "other"
            });
            toastEvent.fire();
        },
        errorToast: function(toastEvent, message) {
            toastEvent.setParams({
                mode: "sticky",
                title: "Error!",
                message: message,
                type: "error"
            });
            toastEvent.fire();
        }
    };
}());