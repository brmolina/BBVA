/*
Autor: vido
Fecha: 2024-02-27
*/
@JsonAccess(serializable='always' deserializable='always')
public with sharing class DMT_IP_Wrapper {

    /**Description: contains input attributes*/
    @AuraEnabled
    public Map<String, Object> inputMap {get;set;}

    /**Description: contains output attributes*/
    @AuraEnabled
    public Map<String, Object> outputMap {get;set;}

    /**Description: contains option attributes*/
    @AuraEnabled
    public Map<String, Object> optionMap {get;set;}

    /**Description: contains method name*/
    @AuraEnabled
    public String methodName {get;set;}

    public DMT_IP_Wrapper(String methodName, Map<String, Object> args) {
        this.methodName = methodName;
        this.inputMap = (Map<String, Object>)args.get(DMT_Constants.INPUT);
        this.outputMap = (Map<String, Object>)args.get(DMT_Constants.OUTPUT);
        //this.outputMap.put('LastUpdate',Datetime.now().format('HH:mm:ss'));
        this.optionMap= (Map<String, Object>)args.get(DMT_Constants.OPTIONS );
    }

    public DMT_IP_Wrapper() {}
}