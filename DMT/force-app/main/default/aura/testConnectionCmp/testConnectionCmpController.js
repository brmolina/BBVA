({
testCallPro : function(component, event, helper) {
var http = new XMLHttpRequest();
        http.open("GET","https://cibdesktop.es.igrupobbva/KXWB/kxwb_mult_web_web_01/solrNumResults?type=clientes&query=descripcionGrupo%3A*repsol*%2BAND%2BindicadorCabecera%3AN", true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader("ip-user", "xe24416");
        http.send(null);
},
    testCallDes: function(component, event, helper) {
var http = new XMLHttpRequest();
        http.open("GET","https://de-wbamdesktop.es.igrupobbva/KXWB/kxwb_mult_web_servicios_01/services/opportunities/11aa", true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader("ip-user", "xe24416");
        http.send(null);
},
    testCallPrePro: function(component, event, helper) {
var http = new XMLHttpRequest();
        http.open("GET","https://au-wbamdesktop.es.igrupobbva/KXWB/kxwb_mult_web_servicios_01/services/opportunities/11aa", true);
        http.withCredentials = true;
        http.setRequestHeader("Content-Type", "application/json");
        http.setRequestHeader("ip-user", "xe24416");
        http.send(null);
}
})