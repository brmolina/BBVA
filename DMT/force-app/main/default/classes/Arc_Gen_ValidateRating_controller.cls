/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ValidateRating_controller
* @Author   Eduardo Efraín Hernández Rendón  eduardoefrain.hernandez.contractor@bbva.com
* @Date     Created: 23/07/2019
* @Group    ARCE Team
* ----------------------------------------------------------------------------------------------
* @Description Class that receives the response of the rating validation from the service
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |13/5/2019 eduardoefrain.hernandez.contractor@bbva.com
*            Initial Version
* |23/5/2019 eduardoefrain.hernandez.contractor@bbva.com
*            documentation
* |01/3/2020 eduardoefrain.hernandez.contractor@bbva.com
*            Add subProcessType to RatingData wrapper
* |02/4/2020 juanignacio.hita.contractor@bbva.com
*            Added user pre-validation for validate rating
* |16/6/2020 joseluis.garcia4.contractor@bbva.com
*            Prevent rating validation if user has no permissions on analysis.
* |17/09/2020 eduardoefrain.hernandez.contractor@bbva.com
*             Update getRatingData method
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |24/02/2021 joseluis.garcia4.contractor@bbva.com
*             Adds "isRaip" parameter to control persistence of validate action.
* |28/05/2021 joseluis.garcia4.contractor@bbva.com
*             Makes IRP validation error more user-friendly.
**/
public without sharing class Arc_Gen_ValidateRating_controller {
    /**
    *-------------------------------------------------------------------------------
    * @description empty constructor for sonar
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-05-13
    * @param void
    * @return void
    * @example Arc_Gen_ValidateRating_controller()
    **/
    @TestVisible
    private Arc_Gen_ValidateRating_controller() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description wrapper for the rating data from the service class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-05-13
    * @example RatingData rData = new RatingData();
    **/
    public class RatingData {
        @AuraEnabled public String ratingId {get;set;}
        @AuraEnabled public String ratingFinal {get;set;}
        @AuraEnabled public String ratingScore {get;set;}
        @AuraEnabled public String subProcessType {get;set;}
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the rating data from the service class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-05-13
    * @param String arce analysis Id
    * @return RatingData - A wrapper with information of the rating
    * @example public static RatingData getRatingData(String analysisId)
    **/
    @AuraEnabled
    public static RatingData getRatingData(String analysisId) {
        RatingData rData = new RatingData();
        try {
            final Map<String, Object> rDataString = Arc_Gen_ValidateRating_service.getRatingData(analysisId);

            rData.ratingId = (String)rDataString.get('ratingId');
            rData.ratingFinal = (String)rDataString.get('ratingValue');
            rData.ratingScore = (String)rDataString.get('ratingScore');
            rData.subProcessType = (String)rDataString.get('subprocessType');
            System.debug('rDataString '+ JSON.serializePretty(rDataString));

            if ((String)rDataString.get('subprocessType') == arce.Arc_Gen_Constants.SUBPROCESS_RATING) {
                Arc_Gen_ValidateRating_service.raipValidations(rDataString);
            }
        } catch (Arc_Gen_ValidateRating_service.CustomException cex) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(cex.getMessage());
        } catch (Exception e) {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Lc_arce_NewARCE_UnexpectedError);
        }
        return rData;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method that obtains the response of the changing status from the service class
    --------------------------------------------------------------------------------
    * @author eduardoefrain.hernandez.contractor@bbva.com
    * @date 2019-05-13
    * @param String arce analysis Id
    * @param String rating  Id
    * @return arce.Arc_Gen_ServiceAndSaveResponse - A wrapper with information of saving records
    * @example public static arce.Arc_Gen_ServiceAndSaveResponse changeStatus(String analysisId)
    **/
    @AuraEnabled
    public static arce.Arc_Gen_ServiceAndSaveResponse changeStatus(String analysisId, String ratingId, Boolean isRaip) {
        arce.Arc_Gen_ServiceAndSaveResponse response = new arce.Arc_Gen_ServiceAndSaveResponse();
        if (Arc_Gen_TabSet_service.getPermissionToEdit(analysisId) == 'true') {
            try {
                response = Arc_Gen_ValidateRating_service.setupValidateRating(analysisId, ratingId, null, isRaip);
            } catch (Exception e) {
                arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_ErrorService);
            }
        } else {
            arce.Arc_Gen_GenericUtilities.throwAuraExcept(System.Label.Arc_Gen_Generic_NotAllowed);
        }
        return response;
    }
}