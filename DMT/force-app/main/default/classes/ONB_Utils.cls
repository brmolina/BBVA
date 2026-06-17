public with sharing class ONB_Utils {


    public static HttpResponse callService(String serviceName, Map<String, Object> request) {
        request.put('userId', getFederationIdentifier());
        final String requestStr = JSON.serialize(request);
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = getMock('ONB_Agreements');
        } else {
            response = iaso.GBL_Integration_GenericService.invoke(serviceName, requestStr);
        }
        return response;
    }

    public static String getFederationIdentifier() {
        String res;
        final Id userId = UserInfo.getUserId();
        final User usr = [SELECT FederationIdentifier FROM User WHERE Id = :userId LIMIT 1];
        res = usr.FederationIdentifier;
        return res;
    }

    public static HttpResponse getMock(String serviceName) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody([Select iaso__Mock_LTA__c from iaso__GBL_Integration_Service__mdt where DeveloperName =: serviceName].iaso__Mock_LTA__c);
        return res;
    }

    @InvocableMethod(label='Traducir Etiquetas Tipo de Cliente' description='Sobrescribe en memoria el API Name con el Label para el Flow')
    public static List<List<Account>> traducirValores(List<List<Account>> listasDeRegistros) {
        List<List<Account>> resultadoFinal = new List<List<Account>>();

        Map<String, String> mapaValores = new Map<String, String>();
        Schema.DescribeFieldResult esquemaCampo = Account.DES_Activity__c.getDescribe();
        for (Schema.PicklistEntry entrada : esquemaCampo.getPicklistValues()) {
            mapaValores.put(entrada.getValue(), entrada.getLabel());
        }

        for (List<Account> listaRegistros : listasDeRegistros) {
            for (Account registro : listaRegistros) {
                String apiName = registro.DES_Activity__c;
                if (String.isNotBlank(apiName) && mapaValores.containsKey(apiName)) {
                    registro.DES_Activity__c = mapaValores.get(apiName);
                }
            }
            resultadoFinal.add(listaRegistros);
        }

        return resultadoFinal;
    }

}