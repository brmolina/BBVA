public class DES_visitRedirectController {

    public DES_visitRedirectController() {
    
    }
    
 	private static DES_visitRedirectController instance;
    public static DES_visitRedirectController getInstance() {
        if (instance == null) instance = new DES_visitRedirectController();
        return instance;
    }
    
    private final DES_Denorm_AccountVisits__c visitDenorm;
    private final String idRelatedVisti;
    
    public DES_visitRedirectController(ApexPages.StandardController stdController) {
        List<String> fields = new List<String> {'DES_Visit_new__c'};
        if (!Test.isRunningTest()) stdController.addFields(fields);
        this.visitDenorm = (DES_Denorm_AccountVisits__c)stdController.getRecord();
    }

    public PageReference goToVisit() {
        
        return new PageReference('/'+visitDenorm.DES_Visit_new__c);
    }

}