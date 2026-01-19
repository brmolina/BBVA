/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_GenericUtilitiesInterface
* @Author   ARCE
* @Date     Created: 2020-04-20
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Generic locators for find local class from interface
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2020-04-20 juanignacio.hita.contractor@bbva.com
*             Class creation add workflow config and validate rating process
* |2020-06-23 joseluis.garcia4.contractor@bbva.com
*             Add Arc_Gen_FinancialSponsor_Interface.
* |2020-06-30 javier.soto.carrascosa@bbva.com
*             Enforce GBL class execution in tests
* |2020-07-30 joseluis.garcia4.contractor@bbva.com
*             Add Arc_Gen_CurrencyExchange_Interface.
* |2020-09-15 juanignacio.hita.contractor@bbva.com
*             Remove ValidationRules constructor
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2020-12-17 juanignacio.hita.contractor@bbva.com
*             Add getLocalServiceIASO method
* |2021-10-05 juanignacio.hita.contractor@bbva.com
*             Add getIRPStepFlow method
* -----------------------------------------------------------------------------------------------
*/
public class Arc_Gen_GenericUtilitiesInterface {
    /**
    *-------------------------------------------------------------------------------
    * @description Class custom exception
    *--------------------------------------------------------------------------------
    * @date		20/04/2020
    * @author	juanignacio.hita.contractor@bbva.com
    */
    public class CustomException extends Exception {}
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Validation rules wrapper
    * ----------------------------------------------------------------------------------------------------
    **/
    public class ValidationRules {
        /*
        * @Description Name local class
        */
        private String localClass {get;set;}
        /*
        * @Description Map with the rules and status
        */
        final private Map<String, Boolean> status {get;set;}
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Void Constructor to avoid warning in sonar qube
    * ----------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example Arc_Gen_GenericUtilitiesInterface generic = new Arc_Gen_GenericUtilitiesInterface()
    * ----------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    private Arc_Gen_GenericUtilitiesInterface() {
    }
    /**
    *-------------------------------------------------------------------------------
    * @description function that find a class that implements the Arc_Gen_Workflow interface with the "WorkflowConfig" configuration metadata
    *--------------------------------------------------------------------------------
    * @date		27/04/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @return   Arc_Gen_Workflow_Interface
    * @example	Arc_Gen_GenericUtilitiesInterface.workflowClass();
    */
    public static Arc_Gen_Workflow_Interface workflowClass() {
        final List<arce__Arce_Config__mdt> configMetadata = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('WorkflowConfig');
        Arc_Gen_Workflow_Interface workFlowClass;
        if (!configMetadata.isEmpty()) {
            final String localClass = Test.isRunningTest() ? 'Arc_GBL_Workflow_Service' : configMetadata.get(0).arce__Value1__c;
            final System.Type objType = Type.forName(localClass);
            try {
                workFlowClass = (Arc_Gen_Workflow_Interface) objType.newInstance();
            } catch (Exception ex) {
                throw new QueryException(ex);
            }
        }
        return workFlowClass;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method generic to get Validation Rule configuration metadata
    *--------------------------------------------------------------------------------
    * @date		27/04/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @param    String : nameVal
    * @return   Arc_Gen_ValidationRating_Interface
    * @example	final Arc_Gen_ValidationsRating_Interface classInterface =
    *                                   (Arc_Gen_ValidationsRating_Interface) Arc_Gen_GenericUtilitiesInterface.raipValidationsClass(nameVal);
    */
    public static Arc_Gen_ValidationsRating_Interface raipValidationsClass(String nameVal) {
        final List<arce__Arce_Config__mdt> configMetadata = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('RAIP_ValidationRules');
        Arc_Gen_ValidationsRating_Interface validationClass;
        if (!configMetadata.isEmpty()) {
            try {
                final String strConfig = configMetadata.get(0).arce__Value1__c;
                final ValidationRules validationRules = (ValidationRules) System.JSON.deserialize((String) strConfig, ValidationRules.class);
                if ((Boolean) validationRules.status.get(nameVal)) {
                    final System.Type classLocal = Type.forName((String) validationRules.localClass);
                    validationClass = (Arc_Gen_ValidationsRating_Interface) classLocal.newInstance();
                }
            } catch (Exception ex) {
                throw new QueryException(ex);
            }
        }
        return validationClass;
    }
    /**
    *-------------------------------------------------------------------------------
    * @description Method generic to get Qualitative Question validation
    *--------------------------------------------------------------------------------
    * @date		27/04/2020
    * @author	juanignacio.hita.contractor@bbva.com
    * @param    String : nameVal
    * @return   Arc_Gen_ValidationRating_Interface
    * @example	final Arc_Gen_ValidationsRating_Interface classInterface =
    *                                   (Arc_Gen_ValidationsRating_Interface) Arc_Gen_GenericUtilitiesInterface.qualitativeQuestionValidation();
    */
    public static Arc_Gen_ValidationsRating_Interface qualitativeQuestionValidation() {
        final List<arce__Arce_Config__mdt> configMetadata = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('QualitativeQuestions_Validation');
        Arc_Gen_ValidationsRating_Interface validationClass;
        if (!configMetadata.isEmpty()) {
            try {
                final String strConfig = configMetadata.get(0).arce__Value1__c;
                final ValidationRules validationRules = (ValidationRules) System.JSON.deserialize((String) strConfig, ValidationRules.class);
                if ((Boolean) validationRules.status.get('qualitativeQ')) {
                    final System.Type classLocal = Type.forName((String) validationRules.localClass);
                    validationClass = (Arc_Gen_ValidationsRating_Interface) classLocal.newInstance();
                }
            } catch (Exception ex) {
                throw new QueryException(ex);
            }
        }
        return validationClass;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get the implementation for the interface that checks
    * Financial Sponsor existence for an economic group.
    *--------------------------------------------------------------------------------
    * @date		22/06/2020
    * @author	joseluis.garcia4.contractor@bbva.com
    * @return   Arc_Gen_FinancialSponsor_Interface
    * @example	final Arc_Gen_FinancialSponsor_Interface classInterface =
    *                                   (Arc_Gen_FinancialSponsor_Interface) Arc_Gen_GenericUtilitiesInterface.getFinancialSponsorCheckClass();
    */
    public static Arc_Gen_FinancialSponsor_Interface getFinancialSponsorCheckClass() {
        final List<arce__Arce_Config__mdt> configMetadata = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('FinancialSponsorInterface');
        Arc_Gen_FinancialSponsor_Interface financialSponsorInstance;
        if (!configMetadata.isEmpty()) {
            final System.Type objType = Type.forName(configMetadata.get(0).arce__Value1__c);
            try {
                financialSponsorInstance = (Arc_Gen_FinancialSponsor_Interface) objType.newInstance();
            } catch (Exception ex) {
                throw new QueryException(ex);
            }
        }

        return financialSponsorInstance;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method to get the implementation for the interface that queries
    * currency exchange information.
    *--------------------------------------------------------------------------------
    * @date		30/07/2020
    * @author	joseluis.garcia4.contractor@bbva.com
    * @return   Arc_Gen_CurrencyExchange_Interface
    * @example	final Arc_Gen_CurrencyExchange_Interface classInterface =
    *                                   (Arc_Gen_CurrencyExchange_Interface) Arc_Gen_GenericUtilitiesInterface.getCurrencyExchangeClass();
    */
    public static Arc_Gen_CurrencyExchange_Interface getCurrencyExchangeClass() {
        final List<arce__Arce_Config__mdt> configMetadata = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo('CurrencyExchangeInterface');
        Arc_Gen_CurrencyExchange_Interface currencyExchangeInstance;
        if (!configMetadata.isEmpty()) {
            final System.Type objType = Type.forName(configMetadata.get(0).arce__Value1__c);
            try {
                currencyExchangeInstance = (Arc_Gen_CurrencyExchange_Interface) objType.newInstance();
            } catch (Exception ex) {
                throw new QueryException(ex);
            }
        }

        return currencyExchangeInstance;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that gets the local implementation with the configuration name and based on IASO_Utils_Interface
    *--------------------------------------------------------------------------------
    * @date     17/12/2020
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    String nameConfig - Configuration service name
    * @return   Arc_Gen_IASO_Utils_Interface
    * @example	final Arc_Gen_IASO_Utils_Interface classInterface =
    *                                   (Arc_Gen_IASO_Utils_Interface) Arc_Gen_GenericUtilitiesInterface.getLocalServiceIASO(nameConfig);
    */
    public static arce.Arc_Gen_IASO_Utils_Interface getLocalServiceIASO(String nameConfig) {
        final List<arce__Arce_Config__mdt> configMetadata = arce.Arc_Gen_Arceconfigs_locator.getConfigurationInfo(nameConfig);
        arce.Arc_Gen_IASO_Utils_Interface localServiceIASO;
        final String localClass = configMetadata.isEmpty() && Test.isRunningTest() ? 'Arc_GBL_RiskFiltersIASO_Service' : configMetadata.get(0).arce__Value1__c;
        final System.Type objType = Type.forName(localClass);
        try {
            localServiceIASO = (arce.Arc_Gen_IASO_Utils_Interface) objType.newInstance();
        } catch (Exception ex) {
            throw new QueryException(ex);
        }
        return localServiceIASO;
    }

    /**
    *-------------------------------------------------------------------------------
    * @description Method that returns IRP flow custom interface
    *--------------------------------------------------------------------------------
    * @date     06/10/2021
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    String nameClass (local class)
    * @return   Arc_Gen_IRPFlowCustom_Interface
    * @example	Arc_Gen_IRPFlowCustom_Interface irpflow = getIRPStepFlow('nameClass');
    */
    public static Arc_Gen_IRPFlowCustom_Interface getIRPStepFlow(String nameClass) {
        final System.Type objType = Type.forName(nameClass);
        Arc_Gen_IRPFlowCustom_Interface interfaceIrp;
        try {
            interfaceIrp = (Arc_Gen_IRPFlowCustom_Interface) objType.newInstance();
        } catch (Exception ex) {
            throw new QueryException(ex);
        }
        return interfaceIrp;
    }
}