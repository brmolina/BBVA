({
    getuploadedFiles: function (component, uploadedFileses, isOK) {
        if (isOK != false) {
            console.log(uploadedFileses.length);
            for (var i = 0; i < uploadedFileses.length; i++) {
                console.log(uploadedFileses[i].name);
                component.set('v.files', uploadedFileses[i]);
            }
        }

    },
})