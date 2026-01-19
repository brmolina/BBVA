/**
* @File Name          : Arc_Gen_UploadAndViewFile_Ctrl.cls
* @Description        :
* @Author             : luisruben.quinto.munoz@bbva.com
* @Group              :
* @Last Modified By   : luisruben.quinto.munoz@bbva.com
* @Last Modified On   : 4/7/2019 12:37:46
* @Modification Log   :
*==============================================================================
* Ver         Date                     Author      		      Modification
*==============================================================================
* 1.0    4/7/2019 11:35:48   luisruben.quinto.munoz@bbva.com     Initial Version
* 1.1    30/04/2021          otiliaramona.veres.contractor@bbva.com     Added an empty constructor method.
* 1.2    04/05/2021          otiliaramona.veres.contractor@bbva.com     Added annotation '@testVisible' to the empty constructor method.
**/
global with sharing class Arc_Gen_UploadAndViewFile_Ctrl {
    /**
    *-------------------------------------------------------------------------------
    * @description Empty constructor method
    *-------------------------------------------------------------------------------
    *@author otiliaramona.veres.contractor@bbva.com
    *@Date   Created:2021-04-30
    */
    @TestVisible
    private Arc_Gen_UploadAndViewFile_Ctrl() { }
    @AuraEnabled
    global static String getIdCont(Id idAcc, String section) {
        String idCont = '';
        for(ContentVersion contObj : [SELECT ContentDocumentId FROM ContentVersion where FirstPublishLocationId=:idAcc and Title=:section]) {
            idCont = contObj.ContentDocumentId;
        }
        return idCont;
    }
    @AuraEnabled
    global static boolean updateFile(Id idFile, String oldName, String section) {
        boolean respo = true;
        try{
            ContentVersion contObj = [SELECT Id,title FROM ContentVersion where ContentDocumentId=:idFile];
            contObj.Title = section;
            update contObj;
        } catch (Exception ex) {
            respo = false;
        }
        return respo;
    }
}