/**
* ────────────────────────────────────────────────────────────────────
* CucoEmailQIPRO
* Class to send email information and notifications in Salesforce.
* ────────────────────────────────────────────────────────────────────
* @author      CuCo CIB <globalhub_components.group@bbva.com>
* @modifiedBy
* @version     1.0
* @created     October 2021
* @modified
* @systemLayer
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
public with sharing class CucoEmailQIPRO {

    /**
	* SINGLETON PATTERN
	*/
    private static CucoEmailQIPRO instance;

    /**
	* Constructor
	*/
    private CucoEmailQIPRO() {
    }

    /**
	* getInstance
	*/
    public static CucoEmailQIPRO gtInstance() {
        if(instance == null) {
            instance = new CucoEmailQIPRO();
        }
        return instance;
    }

    /**
    * @description method: When Picasso has sent a request for more information or sent to re-study a Pricing Conditions Book
    * and sends an email communication and notification to Salesforce
    * @param inputResponse : Picasso response input information
    * @param pAnalysis : cuco__profitability_analysis__c
    */
    public static void checkComments(cuco.PicassoResponse_Wrapper inputResponse, cuco__profitability_analysis__c pAnalysis) {
    	List<cuco__profitability_analysis__c> lstPA = new List<cuco__profitability_analysis__c> ();
        Map<Id,CucoConstructor.DataBooks> mapToSend = new Map<Id,CucoConstructor.DataBooks> ();
        EmailTemplate template = new EmailTemplate ();
        Map<Id,User> userMap = new Map<Id,User> ();
        Set<Id> idUsersToFind = new Set<Id> ();
        final CustomNotificationType typeId = CucoSendEmail.getcustomNType();

		lstPA.add(pAnalysis);
		idUsersToFind.add(pAnalysis.OwnerId);

        Id resultIds = pAnalysis.Id;
        final Map<Id,List<String>> mapCurrentPP = getProfAnalysisPart(resultIds);
          if (inputResponse.action.id == '01'){
            // template when Picasso sent comments
          	template = CucoSendEmail.getEmailTemplate('CommentsPricing');
          } else {
            // template when Picasso sent restudy
            template = CucoSendEmail.getEmailTemplate('RestudyPricing');
          }

        userMap = CucoSendEmailHelper.getUsers(idUsersToFind);
        mapToSend = getMapToSend(lstPA,mapCurrentPP);

        if(!mapToSend.isEmpty()) {
            CucoSendEmail.sendNotifications(mapToSend,userMap,template);
            CucoSendEmail.setupNotifications(mapToSend,userMap,typeId);
        }
    }

    /**
    * @description method: Find cuco__profitability_analysis_participant__c related
    * @param profASet : Set Id cuco__profitability_analysis__c
    * @return Map<Id,List<String>> Id cuco__profitability_analysis__c, List cuco__profitability_analysis_participant__c
    */
    public static Map<Id,List<String>> getProfAnalysisPart(Id resultIds) {
        Set<Id> profASet = new Set<Id>{resultIds};
        final Map<Id,List<String>> mapCurrentPP = new Map<Id,List<String>> ();
        final cuco.PAParticipant_Selector papSelector = new cuco.PAParticipant_Selector(true);
        final List<cuco__profitability_analysis_participant__c> lstPAP = papSelector.selectByProfAnalysis(profASet);
        for (cuco__profitability_analysis_participant__c pap : lstPAP) {
            string[] lst = new string[]{};
                if (mapCurrentPP.containsKey(pap.cuco__gf_profitablity_analysis_id__c)){
                    lst = mapCurrentPP.get(pap.cuco__gf_profitablity_analysis_id__c);
                    lst.add(pap.cuco__participant_id__r.Name);
                } else {
                    lst.add(pap.cuco__participant_id__r.Name);
                }
            mapCurrentPP.put(pap.cuco__gf_profitablity_analysis_id__c,lst);
        }
        return mapCurrentPP;
    }

    /**
    * @description method: Prepares the data to be sent as notifications
    * @param books : List of cuco__profitability_analysis__c
    * @param mapCurrentPP : Map<Id,List<String>> Id cuco__profitability_analysis__c, List cuco__profitability_analysis_participant__c
    * @return Map<Id,CucoConstructor.DataBooks> Id cuco__profitability_analysis__c, {OwnerId of cuco__profitability_analysis__c, List cuco__profitability_analysis_participant__c,cuco__profitability_analysis__c}
    */
    public static Map<Id,CucoConstructor.DataBooks> getMapToSend (List<cuco__profitability_analysis__c> books, Map<Id,List<String>> mapCurrentPP) {
        Map<Id,CucoConstructor.DataBooks> mapToSend = new Map<Id,CucoConstructor.DataBooks>();
        for (cuco__profitability_analysis__c book: books) {
            CucoConstructor.DataBooks dataBooks = new CucoConstructor.DataBooks();
            Set<Id> idUsers = new Set<Id> ();
            idUsers.add(book.OwnerId);
            dataBooks.idUser = idUsers;
            dataBooks.lstCurrentPP = mapCurrentPP.get(book.Id);
            dataBooks.book = book;
            mapToSend.put(book.Id,dataBooks);
        }
        return mapToSend;
    }

}