global with sharing class NONC_CustomLookUpControllerMobile {
    @AuraEnabled
    global static List < sObject > fetchLookUpValues(String searchKeyWord, String objectName, String fieldAPIName, String queryWhere) {
        String searchKey = searchKeyWord;

        List < sObject > returnList = new List < sObject > ();

        String whereConditionSosl = ' WHERE ' + queryWhere + ' ';

        String searchquery = 'FIND :searchKey IN NAME FIELDS RETURNING Account(id, Name, createdDate, ' + fieldAPIName + (queryWhere!='' && queryWhere!='null' && queryWhere!=null ? whereConditionSosl:' ') + ' order by createdDate DESC limit 5)';

        List<List<SObject> > searchList = new List<List<SObject> >();
        String escapeQuery = String.escapeSingleQuotes(searchquery);
        searchList = search.query(escapeQuery);

        for(List<SObject> lObject : searchList) {
            for(SObject obj : lObject) {
                returnList.add(obj);
            }
        }
        return returnList;
    }
}