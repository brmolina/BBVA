public without sharing class DMT_CreateObjetcsTaxonomyflow 
{
    public class Request {
        @InvocableVariable(required=true)
        public DMT_Taxonomy_Values__c taxonomy;
    }

    public class Response {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
    }
    
    @InvocableMethod(label='Create Taxonomy Objects' description='Create taxonomy objects')
    public static List<Response> createTaxonomyObjects(List<Request> requests) {
        List<Response> responses = new List<Response>();
        List<DMT_Taxonomy_Map__mdt> taxonomyLst = DMT_Taxonomy_Map__mdt.getAll().values();
        Map<String, List<SObject>> mapSObjects = new Map<String, List<SObject>>();
        
        for(Request r : requests)
        {
            try {
                SObject newSObject;
                String mapName;

                for(DMT_Taxonomy_Map__mdt t : taxonomyLst)
                {
                    if(t.DMT_Catalog__c == r.taxonomy.DMT_Catalog__c)
                    {
                        if(newSObject == null)
                        {
                            mapName = t.DMT_Object__c + ';' + t.DMT_ExternalId__c;
                            Schema.SObjectType newSObjectType = Schema.getGlobalDescribe().get(t.DMT_Object__c);
                            newSObject = newSobjectType.newSObject();
                        }
                        
                        newSObject.put(t.DMT_ObjectField__c, r.taxonomy.get(t.DMT_ValueTaxonomy__c));
                    }
                }

                if(newSObject != null)
                {
                    System.debug(newSObject);
                    if(mapSObjects.containsKey(mapName))
                    {
                        mapSObjects.get(mapName).add(newSObject);
                    } else {
                        mapSObjects.put(mapName, new List<SObject>{newSObject});
                    }
                }

                Response response = new Response();
                response.success = true;
                responses.add(response);
            } catch (Exception e) {
                DES_Exception_Utils.logException(
                    e,
                    'DMT_CreateObjetcsTaxonomyflow',
                    'createTaxonomyObjects',
                    'DMT',
                    'Catalog=' + (r.taxonomy != null ? r.taxonomy.DMT_Catalog__c : null) +
                    ', TaxonomyExternalId=' + (r.taxonomy != null ? r.taxonomy.DMT_External_Id__c : null)
                );
                throw e;
            }
            
        }

        for(String s : mapSObjects.keySet())
        {
            List<String> split = s.split(';');
            try {
                Database.upsert(mapSObjects.get(s), Schema.getGlobalDescribe().get(split[0]).getDescribe().fields.getMap().get(split[1]));
            } catch (Exception e) {
                DES_Exception_Utils.logException(
                    e,
                    'DMT_CreateObjetcsTaxonomyflow',
                    'createTaxonomyObjects',
                    'DMT',
                    'Object=' + split[0] + ', Records=' + mapSObjects.get(s).size()
                );
                throw e;
            }
        }

        return responses;

    }

    
}