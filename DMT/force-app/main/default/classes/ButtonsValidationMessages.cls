/**
* @author GlobalDesktop
*/
global with sharing class ButtonsValidationMessages implements dwp_dbpn.DynamicFlowValidationInterface {
    /** @author GlobalDesktop
     * Almacena el recordID (id del objeto) para accederlo desde cualquier función estática.
     */
    private static String commonRecordId = '';
    /** @author GlobalDesktop
     * Almacena la source (objeto) para accederlo desde cualquier función estática.
     */
    private static String commonSource = '';
    /** @author GlobalDesktop
     * Lista de errores a mostrar.
*/
    private static List<String> lstErrorMessage = new List<String>();
        /**
* @author GlobalDesktop
Comprueba si alguno de los botones pulsados no debería estar presente en la ventana actual y muestra mensajes de error indicando el por qué.
*/  global static List<String> getErrorMessagesList(String recordId, String source, String validationClass) {
        commonRecordId = recordId;
        commonSource = source;
        lstErrorMessage = new List<String>();
		System.debug('validationClass es: ' + validationClass);
        switch on validationClass {
            when  'Create_NBC'{
              validateCreateNBC();
            }
            when 'Amiweb' {
              validateAmiweb();
            }
            when 'Add_sold_order' {
              validateAddSoldOrder();
            }
            when 'Won_Opportunity' {
              validateWonButton();
            }
        }

        //NO BORRAR, MANDATE PUEDE VOLVER A PEDIRSE
        /*List<Opportunity> listOpportunity = [SELECT Id, StageName, opportunity_correct_ind_type__c, oppy_substage_mandate_ind_type__c
FROM Opportunity
WHERE Id = :recordId LIMIT 1];
Opportunity opp = listOpportunity.get(0);
if((opp.StageName == Label.DES_Draft
|| opp.oppy_substage_mandate_ind_type__c == Label.DES_YES)
&& validationClass == 'Mandate') {
lstErrorMessage.add('The opportunity does not meet the conditions.');
}*/ //NOSONAR

        return lstErrorMessage;
    }

    //Validación el botón Create_NBC
    private static void validateCreateNBC() {


        ComponentNBC_Controller.setMapCountryRegion();
        ComponentNBC_Controller.getTemplateConfigurationsList();
        system.debug('MAPREGION-> ' + ComponentNBC_Controller.mapCountryRegion);
        system.debug('LISTCONFIG-> ' + ComponentNBC_Controller.listTemConfigs);

        final UserRecordAccess canEdit = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :commonRecordId LIMIT 1];
        system.debug('canEdit -> ' + canEdit.HasEditAccess);
        if(canEdit.HasEditAccess) { //Sin acceso de edición no se pueden comprobar el resto de puntos.
            if(commonSource == LABEL.Opportunity_Name) {
                boolean nBCOk = false;
                system.debug('ES OPP');
                final set<String> solClassDesc = new set<String> {LABEL.DES_Transaction_Trade_Finance, LABEL.DES_Structure_Trade_Finance, LABEL.DES_Corporate_Loans, LABEL.DES_Working_Capital, LABEL.DES_Leverage_Buyout_LBOs, LABEL.DES_Project_Finance_Lending};
                    final set<String> pdtoFamilies = new set<String> { 'IBF', 'GTB' };
                        final set<String> stageTypes = new set<String> { 'Proposal', 'Approval', 'Ready to close' };
                           final Map<Id, OpportunityLineItem> mapProducts = new Map<Id, OpportunityLineItem>([SELECT Id, ProductCode, product_scope_type__c, syndicated_loan_drawn_amount__c, Converted_Currency__c, opportunity_stage_type__c, DES_Product_Family__c, solution_classification_desc__c, subproduct_name__c, OpportunityId, bbva_prtcp_tranche_amount__c, Name, Opportunity.DES_Booking_Geography__c, Opportunity.Substandard_Operation__c
                                                                                                         FROM OpportunityLineItem
                                                                                                         WHERE OpportunityId = :commonRecordId
                                                                                                         AND solution_classification_desc__c IN :solClassDesc
                                                                                                         AND DES_Product_Family__c IN :pdtoFamilies
                                                                                                         AND opportunity_stage_type__c IN :stageTypes]);

                if([SELECT Count() from DES_Template__c WHERE opportunity_id__c = :commonRecordId] > 0) {
                    lstErrorMessage.add('An NBC template has already been created for this opportunity');
                }

                for(OpportunityLineItem oppl : mapProducts.values()) {
                    if(ComponentNBC_Controller.getTemplateId(oppl.solution_classification_desc__c, ComponentNBC_Controller.mapCountryRegion.get(oppl.Opportunity.DES_Booking_Geography__c), oppl.Converted_Currency__c, oppl.product_scope_type__c, oppl.Opportunity.Substandard_Operation__c) != null) {
                        nBCOk = true;
                        break;
                    }
                }

                if(!nBCOk) {
                    lstErrorMessage.add('NBC template is not required in this case.');
                }
            }
        } else {
            lstErrorMessage.add('You do not have permission to edit the opportunity.');
        }
    }

    //Validación el botón AMIWEB.
    private static void validateAmiweb() {

        final UserRecordAccess canEdit = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId = :commonRecordId LIMIT 1];
        system.debug('canEdit -> ' + canEdit.HasEditAccess);
        if(canEdit.HasEditAccess) { //Sin acceso de edición no se pueden comprobar el resto de puntos.
            if(commonSource == LABEL.Opportunity_Name) {
                system.debug('ES OPP');
                final set<String> pdtoFamilies = new set<String> { 'IBF', 'GTB' };
                    final set<String> stageTypes = new set<String> {  'Proposal', 'Approval', 'Ready to close' };
                        final Boolean validProducts = [SELECT Count()
                                                       FROM OpportunityLineItem
                                                       WHERE OpportunityId = :commonRecordId
                                                       AND DES_Product_Family__c IN :pdtoFamilies
                                                       AND opportunity_stage_type__c IN :stageTypes] > 0;
                if(!validProducts) {
                    lstErrorMessage.add('The opportunity must have at least one IBF or GTB product.');
                }
            }
        } else {
            lstErrorMessage.add('You do not have permission to edit the opportunity.');
        }
    }

    //Validación el botón Add_Sold_Order.
    private static void validateAddSoldOrder() {
        System.debug('el user en validateASO es: ' + UserInfo.getUserId());

            final Boolean isSindication = [
        SELECT Count() 
        FROM PermissionSetAssignment 
        WHERE AssigneeId = :UserInfo.getUserId() 
        AND PermissionSet.Name = 'OPR_Manage_Sold_Orders'
        ] > 0;

		System.debug('IsSindication:  ' + isSindication);
        if(isSindication) { //Si el grupo es válido hay que comprobar si el producto y el stage también son correctos, si no se muestra el mensaje de error.
            final set<String> validProductCode = new Set<String> {'codeCL', 'codeLBOs', 'codePFL'}; //NOSONAR //lista de productos para los que se muestra el botón.
            final set<String> validUWType = new Set<String> {'Yes', 'Deal not materialised', 'Mandatory sell down', 'Best Efforts'}; //NOSONAR //lista de underwriting_agreement_type__c para los que se muestra el botón.
            final Boolean hasValidProducts = [SELECT Count() FROM OpportunityLineItem WHERE OpportunityId = :commonRecordId AND underwriting_agreement_type__c IN :validUWType AND ProductCode IN :validProductCode] > 0;

            if(hasValidProducts) {     //Si el producto permite mostrar el botón comprobamos que el stagename sea correcto.
                final set<String> validStages = new Set<String> {Label.DES_Approvals, Label.DES_Ready_to_close}; //lista de stageNames en que se muestra el botón.
                final Boolean hasValidStage = [SELECT Count() FROM Opportunity WHERE Id = :commonRecordId AND StageName IN :validStages LIMIT 1] > 0; //Solo puede venir 1 oportunidad, la que se accede desde el componente.

                if(!hasValidStage) { //Si el stageName no está en la lista de stagename válidos se devuelve un error.
                    lstErrorMessage.add(Label.Add_sold_order_error_message_wrong_stage_name);
                }
            } else {
                //Si no tiene un producto válido.
                lstErrorMessage.add(Label.Add_sold_order_error_message_invalid_product);
            }

        } else { //Si el grupo no es válido se muestra un error.
            lstErrorMessage.add(Label.Add_sold_order_error_message_invalid_group);
        }
        
    }

    /*
    * @author GlobalDesktop
    * @description validateWonButton
    */
    private static void validateWonButton() {
      Boolean apply = false;
      final Set<Id> usersOpp = new Set<Id>();
      String stage = '';
      for (DES_Opportunity_Management_member__c member :[SELECT Id, DES_User__c, DES_User__r.Name, DES_Opportunity__r.owner.Name, DES_Opportunity__r.OwnerId, DES_Opportunity__r.StageName
      FROM DES_Opportunity_Management_member__c
      WHERE DES_Opportunity__c = :commonRecordId]) {
        usersOpp.add(member.DES_User__c);
        if(stage == '') {
          stage = member.DES_Opportunity__r.StageName;
          usersOpp.add(member.DES_Opportunity__r.OwnerId);
        }
      }
      if(usersOpp.contains(UserInfo.getUserId()) && stage == Label.DES_Ready_to_close) {
        apply = true;
      }

      if(!apply) {
        lstErrorMessage.add('Sorry, the opportunity must be in Ready to Close and you must be as owner or participant ');
      }
    }
}