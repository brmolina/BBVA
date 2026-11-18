for (String url : new List<String>{
        'https://aso-backend-global.live-01.platform.bbva.com/dmt/v0/download-details?opportunityId=TEST',
        'https://aso-backend-global.live-01.platform.bbva.com/dmt/v0/cibglobald-4711-nonexistent' }) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(url);
    req.setMethod('GET');
    req.setTimeout(20000);
    HttpResponse res = new Http().send(req);
    System.debug('CIBGLOBALD-4711 PRO PROBE ' + url + ' -> ' + res.getStatusCode() + ' ' + res.getStatus() + ' | ' + res.getBody().left(300));
}
