public with sharing class LocationVisitMatcherFlow {
    @InvocableMethod(label='Match location visit records')
    public static List<Output> matchCountry(List<Input> input){
        List<Output> results = new List<Output>();
        String locationValue = null;
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get('dwp_kitv__Visit__c') ;
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get('gf_location__c').getDescribe();
        List<Schema.PicklistEntry> picklistLocationValues = fieldResult.getPicklistValues();
        Map<String, String> mapCountryValues = new Map<String, String>();
        for (Schema.PicklistEntry value : picklistLocationValues) {
            if(!mapCountryValues.containsKey(value.getLabel())){
                mapCountryValues.put(value.getLabel(), value.getValue());
            }
        }
        System.debug('mapCountryValues:::: '+mapCountryValues);
        for (Country_Translation__mdt entry : [Select Label, Value__c from Country_Translation__mdt ]) {
           if(!mapCountryValues.containsKey(entry.Label)){
                mapCountryValues.put(entry.Label, entry.Value__c);
            }
        }
        System.debug('mapCountryValues:::: '+mapCountryValues);

        String matchedValue = null;
        String location = input[0].location;
        for (String entry : mapCountryValues.keySet()) {
            if (location.contains(entry)) {
                locationValue= mapCountryValues.get(entry);
                System.debug('locationValue::: '+locationValue);
                break;
            }
        }
        
        results.add(new Output(locationValue));
        return results;
    }
    public class Input {
        @InvocableVariable(required=true)
        public String location;
    }

    public class Output {
        @InvocableVariable
        public String matchedCountry;

        public Output(String matchedCountry) {
            this.matchedCountry = matchedCountry;
        }
    }
}