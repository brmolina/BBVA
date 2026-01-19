/**
* ____________________________________________________________________________
* Controller class for DPMX_CommentsComponent.cmp aura Component
* ____________________________________________________________________________
* @author      David Otero <david.otero.carcia.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2022-02-20
* @modified
* @systemLayer Sample
* ____________________________________________________________________________
* @changes
*
* ____________________________________________________________________________
*/
public class DPMX_CommentsComponent_ctrl {
    
     /**
    * @description Private constructor to avoid sonar err
    */
    public DPMX_CommentsComponent_ctrl() {
		Map<String, Object> retMap = new Map<String, Object>();
    }
    /**
    * @description Get data from services
    * @param recordId : 
    * @return retMap ??????
    */
    @AuraEnabled
    public static Map<String,Object> getInitialData (String recordId) {
        Map<String, Object> retMap = new Map<String, Object>();
        DPMX_authorization__c coments = [SELECT OwnerFullName__c, Comentario__c, DATE_SolicitudeDate__c, Status__c, FRML_AsignedToFullName__c, commentAuthorizer__c, Date_AuthorizerDate__c
        FROM DPMX_authorization__c
        WHERE Id =:recordId];
        retMap.put('solicitorName', coments.OwnerFullName__c);
        retMap.put('solicitorComment', coments.Comentario__c);
        retMap.put('solicitorDate', coments.DATE_SolicitudeDate__c);
        retMap.put('status', coments.Status__c);
        retMap.put('authorizatorName', coments.FRML_AsignedToFullName__c);
        retMap.put('authorizatorComment', coments.commentAuthorizer__c);
        retMap.put('authorizatorrDate', coments.Date_AuthorizerDate__c);
        return retMap;
    }

}