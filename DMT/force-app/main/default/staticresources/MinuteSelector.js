// MinuteSelector
function closePopUp(){
    Sfdc.canvas.publisher.publish({ name: "publisher.close", payload:{ refresh: "true" }});
}
function downloadPDF( urlResource ){
    top.location.href = urlResource;
}
