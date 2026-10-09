public with sharing class DMT_FinishedConditionCase {

    @InvocableMethod(label='Return Cases to restart' description='Returns the list of cases that not fulfill the finish conditions of each finished case.')
    public static List<List<Case>> checkFinishConditions(List<List<Case>> listcases) {
        List<Case> cases = listcases[0];
        Set<Case> returnCases = new Set<Case> ();
        DMT_Line__c line = [SELECT Id, Client_Type__c, FD_Amount__c, DvP_Amount__c, DMT_DerivativesAmount__c, Start_Date__c, End_Date__c, Client__c, Custom_Association__c from DMT_Line__c where Id = :cases[0].DMT_Line__c limit 1];
        List<DMT_Risk_Line_Term__c> risks = [SELECT Id, DMT_Amount__c, DMT_Risk_Type__c, DMT_Init_Term__c, DMT_End_Term__c from DMT_Risk_Line_Term__c where DMT_Line__c = : line.Id];
        List<DMT_Line_Product_Item__c> lpis = [SELECT iD, Product_Code_Value__c, DMT_DerivativeRestriction__c, DMT_DVPRestriction__c, DMT_FDRestriction__c from DMT_Line_Product_Item__c where Line__c = : line.Id];
        Decimal maxMaturityRisk = 0;
        Set<String> productSet = new Set<String>();
        Set<String> customerSet = new Set<String>();
        for(DMT_Line_Product_Item__c lpi : lpis){
            if(lpi.DMT_DerivativeRestriction__c || lpi.DMT_DVPRestriction__c || lpi.DMT_FDRestriction__c){
                productSet.add(lpi.Product_Code_Value__c);
            }
        }
        for(DMT_Risk_Line_Term__c risk : risks){
            if(risk.DMT_Amount__c > 0 && Decimal.valueOf(risk.DMT_End_Term__c) > maxMaturityRisk){
                maxMaturityRisk = Decimal.valueOf(risk.DMT_End_Term__c);
            }
        }

        if(line.Client_Type__c == 'Custom'){
            List<Custom_Association_Client__c> customclients = [SELECT Id, g_customer_id__c from Custom_Association_Client__c where Custom_Association__c = : line.Custom_Association__c];
            for(Custom_Association_Client__c customclient : customclients){
                customerSet.add(customclient.g_customer_id__c);
            }
        }else if(line.Client_Type__c == 'Group'){
            Account groupClient = [Select Id, DES_Group_Code__c from Account where Id = : line.Client__c LIMIT 1];
            customerSet.add(groupClient.DES_Group_Code__c);
        }else if(line.Client_Type__c == 'Customer'){
          Account customer = [Select Id, g_customer_id__c from Account where Id = : line.Client__c LIMIT 1];
            customerSet.add(customer.g_customer_id__c);
        }

        for(Case caseCon : cases){
            if(caseCon.DMT_ConditionsCloseCase__c != null && caseCon.DMT_ConditionsCloseCase__c != ''){
                
            DMT_FinishConditionsWrapper conditionsJSON = (DMT_FinishConditionsWrapper) JSON.deserialize(caseCon.DMT_ConditionsCloseCase__c,DMT_FinishConditionsWrapper.class);
            if(Date.valueOf(conditionsJSON.dateMaximum) < line.End_Date__c){
                returnCases.add(caseCon);system.debug('dateMaximum '+ conditionsJSON.dateMaximum + line.End_Date__c);
            }
            if(Decimal.valueOf(conditionsJSON.maximumLinePeriod) < line.Start_Date__c.daysBetween(line.End_Date__c)){
                returnCases.add(caseCon);system.debug('maximumLinePeriod '+ conditionsJSON.maximumLinePeriod +'  ' + line.Start_Date__c.daysBetween(line.End_Date__c));
            }
            if(Decimal.valueOf(conditionsJSON.maximumProductMaturity) < maxMaturityRisk){
                returnCases.add(caseCon);system.debug('maximumProductMaturity '+ conditionsJSON.maximumProductMaturity + maxMaturityRisk);
            }
            if(!conditionsJSON.clients.isEmpty() && conditionsJSON.products != productSet){
                returnCases.add(caseCon);system.debug('products '+ conditionsJSON.products + productSet);
            }
            if(!conditionsJSON.products.isEmpty() && conditionsJSON.clients != customerSet){
                returnCases.add(caseCon);system.debug('clients '+ conditionsJSON.clients + customerSet);
            }
            if(!String.isBlank(conditionsJSON.fdAmount) && Decimal.valueOf(conditionsJSON.fdAmount) < line.FD_Amount__c){
                returnCases.add(caseCon);system.debug('fdAmount '+ conditionsJSON.fdAmount + line.FD_Amount__c);
            }
            if(!String.isBlank(conditionsJSON.dvpAmount) && Decimal.valueOf(conditionsJSON.dvpAmount) < line.DvP_Amount__c){
                returnCases.add(caseCon);system.debug('dvpAmount '+ conditionsJSON.dvpAmount + line.DvP_Amount__c);
            }
            if(!String.isBlank(conditionsJSON.derivativesAmount) && Decimal.valueOf(conditionsJSON.derivativesAmount) < line.DMT_DerivativesAmount__c){
                returnCases.add(caseCon);system.debug('derivativesAmount '+ conditionsJSON.derivativesAmount + line.DMT_DerivativesAmount__c);
            }
            }
        }
        List<Case> returnList = new List<Case>(returnCases);system.debug('returnLIst '+returnList);
        List<List<Case>> reuturnListList = new List<List<Case>>{returnList};
        return reuturnListList;
    }

    @JsonAccess(serializable='always' deserializable='always')
    public class DMT_FinishConditionsWrapper {
        
        public String dateMaximum;
        
        public String maximumLinePeriod;
        
        public String maximumProductMaturity;

        public String fdAmount;

        public String dvpAmount;

        public String derivativesAmount;

        public Set<String> products;
 
        public Set<String> clients;
    
    }
}