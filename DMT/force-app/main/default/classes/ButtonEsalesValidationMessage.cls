/**
* @author GlobalDesktop
*/
@SuppressWarnings('sf:CyclomaticComplexity, sf:ConfusingTernary')
global with sharing class ButtonEsalesValidationMessage implements dwp_dbpn.DynamicFlowValidationInterface { //NOSONAR
    /** @author GlobalDesktop
     * Almacena el recordID (id del objeto) para accederlo desde cualquier función estática.
     */
    private static String commonRecordId = '';//NOSONAR
    /** @author GlobalDesktop
     * Almacena la source (objeto) para accederlo desde cualquier función estática.
     */
    private static String commonSource = '';//NOSONAR
    /** @author GlobalDesktop
     * Lista de errores a mostrar.
    */
    private static List<String> lstErrorMessage = new List<String>();

    /*
    * String para comprobar si el RT del NBC es del tipo Virtual
    */
    static final String NEWSTR = 'New';
    /*
    * String para comprobar si el RT del NBC es del tipo Virtual
    */
    static final String VALIDATE = 'Validate';
    /*
    * String para comprobar si el RT del NBC es del tipo Virtual
    */
    static final String REVIEW = 'Review';
    /*
    * String para comprobar si el RT del NBC es del tipo Virtual
    */
    static final String IMPLEMENT = 'Implement';
    /*
    * String para comprobar si el RT del NBC es del tipo Virtual
    */
    static final String GLOBALESALES = 'GLOBAL MARKETS ECOMMERCE SALES';


    /**
    * @author GlobalDesktop
    Comprueba si alguno de los botones pulsados no debería estar presente en la ventana actual y muestra mensajes de error indicando el por qué.
    */
global static List<String> getErrorMessagesList(String recordId, String source, String validationClass) {
        commonRecordId = recordId;
        commonSource = source;
        lstErrorMessage = new List<String>();

        switch on validationClass {
            when  'Review'{
                validateReview(recordId);
            }
            when 'Approve' {
                validateApprove(recordId);
            }
            when 'Submit' {
                validateSubmit(recordId);
            }
            when 'Implement' {
                validateImplement(recordId);
            }
            when 'Edit' {
                validateEdit(recordId);
            }
            when 'AddProduct' {
                validateAddProduct(recordId);
            }
            when 'ApproveTrader' {
                validateApproveTrader(recordId);
            }
            when 'Reject' {
                validateReject(recordId);
            }
            when 'Edit_Tier' {
                validateEditTier(recordId);
            }
            when 'Complete' {
                validateComplet(recordId);
            }
        }
        return lstErrorMessage;
    }

    /*
    * @author GlobalDesktop
    * @description getForm
    */
    private static Asset_Template__c getForm(String recordId) {
        return [SELECT Id, Name, Status__c, OwnerId, Murex_Code__c, eSales_check__c, Reject_Reason__c, Rejection_Reason__c, User_Rejection_Reason__c, Onboarding_Type__c, Asset_Class__c, Secondary_Sales_Id__c,(SELECT Id, Does_the_client_confirm_via_Markitwire__c FROM Asset_Products__r WHERE Does_the_client_confirm_via_Markitwire__c = 'No') FROM Asset_Template__c WHERE Id = :recordId LIMIT 1];
    }

    /*
    * @author GlobalDesktop
    * @description validateReview
    */
    private static void validateReview(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        if(form.Status__c != NEWSTR) {
            lstErrorMessage.add('Sorry, the registry is not in status New or Wrong Data');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateApprove
    */
    private static void validateApprove(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        if(form.Status__c != VALIDATE) {
            lstErrorMessage.add('Sorry, the registry is not in status Validate');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateSubmit
    */
    private static void validateSubmit(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        EsalesDynamicButtonsHandler buttonHandler;
        buttonHandler = new EsalesDynamicButtonsHandler();
        if(form.Status__c != REVIEW && form.Status__c != NEWSTR && !buttonHandler.rolImplement(GLOBALESALES)) {
            lstErrorMessage.add('Sorry, the registry or New');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateImplement
    */
    private static void validateImplement(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        if(form.Status__c != NEWSTR && form.Status__c != 'Wrong Data' && form.Asset_Class__c != 'IRS' && form.Asset_Class__c != 'Equity') {
            lstErrorMessage.add('Sorry, the registry is not in status New or Wrong Data');
        } else if (form.Status__c != NEWSTR && form.Status__c != 'Wrong Data' && form.Status__c != 'Review' && (form.Asset_Class__c == 'IRS' || form.Asset_Class__c == 'Equity')) {
            lstErrorMessage.add('Sorry, the registry is not in status New or Wrong Data');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateEdit
    */
    private static void validateEdit(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        System.debug('form----> '+form);
        String rolId;
        rolId = UserInfo.getUserRoleId();
        System.debug('rolId----> '+rolId);
        EsalesDynamicButtonsHandler buttonHandler;
        buttonHandler = new EsalesDynamicButtonsHandler();
        System.debug('buttonHandler----> '+buttonHandler);
        if(!EsalesDynamicButtonsHandler.getProfile()) { //NOSONAR
            if(form.Status__c == NEWSTR && !buttonHandler.getUserId(form) && !buttonHandler.rolImplement(GLOBALESALES)) {
                lstErrorMessage.add('Sorry, you are not the owner of the registry');
            } else if(form.Status__c == REVIEW && form.Secondary_Sales_Id__c != rolId && !buttonHandler.rolImplement(GLOBALESALES)) {
                lstErrorMessage.add('Sorry, the registry is in review status and you are not part of the secondary sales or eSales');
            } else if(form.Status__c == 'Wrong Data' && !buttonHandler.rolImplement(GLOBALESALES) && form.Secondary_Sales_Id__c != rolId && form.Secondary_Sales_Id__c == rolId && !form.eSales_check__c) {
                lstErrorMessage.add('Sorry, the registry cannot be modified in Wrong Data status.');
            } else if(form.Status__c == IMPLEMENT || form.Status__c == 'Client Rejected' || form.Status__c == 'Completed' || form.Status__c == VALIDATE) {
                lstErrorMessage.add('Sorry, the registry cannot be modified in this status');
            }
        }
    }
    /*
    * @author GlobalDesktop
    * @description validateAddProduct
    */
    private static void validateAddProduct(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        if(form.Status__c != NEWSTR) {
            lstErrorMessage.add('Sorry, the registry is not in new status');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateAddProduct
    */
    private static void validateApproveTrader(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        //String rolId = UserInfo.getUserRoleId();
        EsalesDynamicButtonsHandler buttonHandler;
        buttonHandler = new EsalesDynamicButtonsHandler();
        if(form.Status__c != VALIDATE && !buttonHandler.getIfTrader(recordId) && !EsalesDynamicButtonsHandler.comprobarAprove(recordId)) {
            lstErrorMessage.add('Sorry, the registry is not in validate status');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateReject
    */
    private static void validateReject(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        EsalesDynamicButtonsHandler buttonHandler;
        buttonHandler = new EsalesDynamicButtonsHandler();
        if(form.Status__c != VALIDATE && !buttonHandler.getIfTrader(recordId) && !EsalesDynamicButtonsHandler.comprobarAprove(recordId)) {
            lstErrorMessage.add('Sorry, the registry is not in validate status');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateReject
    */
    private static void validateEditTier(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        EsalesDynamicButtonsHandler buttonHandler;
        buttonHandler = new EsalesDynamicButtonsHandler();
        if(form.Status__c != VALIDATE && !buttonHandler.getIfTrader(recordId) && !EsalesDynamicButtonsHandler.comprobarAprove(recordId)) {
            lstErrorMessage.add('Sorry, the registry is not in validate status');
        }
    }

    /*
    * @author GlobalDesktop
    * @description validateComplet
    */
    private static void validateComplet(String recordId) {
        Asset_Template__c form;
        form = getForm(recordId);
        EsalesDynamicButtonsHandler buttonHandler;
        buttonHandler = new EsalesDynamicButtonsHandler();
        if(form.Status__c != IMPLEMENT && !buttonHandler.rolImplement('GLOBAL MARKETS E-COMMERCE')) {
            lstErrorMessage.add('Sorry, the registry is not in implement status or you are not part of the Role GLOBAL MARKETS E-COMMERCE.');
        }
    }
}