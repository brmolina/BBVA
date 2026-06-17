/**
* @File Name          : Arc_Gen_ScheduleInSan_Controller_Test.cls
* @Description        : Utils test class to create test data
* @Author             : Diego Miguel Tamarit - diego.miguel.contractor@bbva.com / dmiguelt@minsait.com
* @Group              : ARCE
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 02-06-2026
* @Modification Log   :
*_________________________________________________________________________________
*Version    Date           Author                                       Description
*1.0        11/04/2019     diego.miguel.contractor@bbva.com    	        Creation.
*1.1        26/04/2019     diego.miguel.contractor@bbva.com             Added getEconomicParticipations // listParticipants custom settings URL
*1.2        01/07/2019     ricardo.almanza.contractor@bbva.com          Added crearLimitExposures
*1.3        27/08/2019     luisruben.quinto.munoz@bbva.com              Delete reference to arce__id__c
*1.4        26/09/2019     javier.soto.carrascosa@bbva.com              Remove unused iaso
*1.4.1      02/12/2019     german.sanchez.perez.contractor@bbva.com
*                          franciscojavier.bueno@bbva.com               Api names modified with the correct name on business glossary
*1.5        20/12/2019     mariohumberto.ramirez.contractor@bbva.com    Added new custom setting for Financial Statement Details service
*                                                                       in crearIasoUrlsCustomSettings method
*1.6        07/01/2019     javier.soto.carrascosa@bbva.com              Add getSRAccounts and setupAccounts methods, remove unused methods
*1.7        24/01/2020     juanmanuel.perez.ortiz.contractor@bbva.com   Remove logic static parameters to ASO services
*1.8        09/03/2020     eduardoefrain.hernandez.contractor@bbva.com  update methods because of Indepentent Rating (RAIP)
*1.9        29/03/2020     javier.soto.carrascosa@bbva.com              add support for product load through static resource
*2.0        13/05/2020     cesaroctavio.villanueva.cebal@bbva.com       added value for financial sponsor indicator in account
*2.1        01/06/2020     joseluis.garcia4.contractor@bbva.com         Add currency value to AHA.
*2.2        12/06/2020     joseluis.garcia4.contractor@bbva.com         Add new createStandardPricebookEntries method
*2.3        20/07/2020     juanignacio.hita.contractor@bbva.com         Add new setupFFSS method
*2.4        03/08/2020     juanignacio.hita.contractor@bbva.com         Add new crearDependentVal method
*2.5        11/08/2020     javier.soto.carrascosa@bbva.com              Update sector field
*2.6        15/09/2020     javier.soto.carrascosa@bbva.com              Create sector active by default for tests
*2.7        18/09/2020     juanignacio.hita.contractor@bbva.com         Changed crearFinStatement method and add bank_id__c in crearCuenta method
*2.9        23/09/2020     saimassimilianno.jordana.contractor@bbva.com Added arce. namespace to all classes that are now in the arce-dependencies package
*2.10       15/01/2021     juanignacio.hita.contractor@bbva.com         Add riskFilter and riskFilterGroup endpoints to crearIasoUrlsCustomSettings
*2.11       18/01/2021     luisdavid.rivera.ortiz@bbva.com              Remove field references for usused fields (namings nivelation)
*2.12       17/06/2021     juanignacio.hita.contractor@bbva.com         Rollback last commit  (PR: 1231)
*2.13       24/05/2023     joseluis.miralles.contractor@bbva.com        Added method to get Projection Data
-----------------------------------------------------------------------------------------*/
@SuppressWarnings('PMD.CouplingBetweenObjects, PMD.ExcessivePublicCount, sf:ExcessiveClassLength, sf:TooManyMethods, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList')
@isTest
public with sharing class Arc_UtilitysDataTest_tst {
    /** ------------------------------------------------------------------------------------------------
    * @Description perfilMapa map for profiles
    * ------------------------------------------------------------------------------------------------**/
    static Map<String, Profile> perfilMapa = new Map<String, Profile>();
    /** ------------------------------------------------------------------------------------------------
    * @Description utility map of roles
    * ------------------------------------------------------------------------------------------------**/
    static Map<String, UserRole> rolMapa   = new Map<String, UserRole>();
    /** ------------------------------------------------------------------------------------------------
    * @Description utility list of profiles
    * ------------------------------------------------------------------------------------------------**/
    static List<Profile> lstProfile;
    /** ------------------------------------------------------------------------------------------------
    * @Description utility list of user roles
    * ------------------------------------------------------------------------------------------------**/
    static List<UserRole> userRole;
    /** ------------------------------------------------------------------------------------------------
    * @Description map client types
    * ------------------------------------------------------------------------------------------------**/
    static Map<String, RecordType> mapaRTypesClientes = new Map<String, RecordType>();
    /** ------------------------------------------------------------------------------------------------
    * @Description list recordType clientes
    * ------------------------------------------------------------------------------------------------**/
    static List<RecordType> rTypesClientes;
    static {
        rTypesClientes = new List<RecordType>([SELECT Id, Name FROM RecordType WHERE SobjectType='Account']);
        for(RecordType rt:rTypesClientes) { mapaRTypesClientes.put(rt.Name, rt); }
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Method that assert the max number of querys
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Method:      maxNumQuerys
    * @Date     Created: 2019-05-22
    * @param void
    * @return void
    * @example maxNumQuerys()
    * ------------------------------------------------------------------------------------------------
    **/
    @isTest static void maxNumQuerys() {
        final Integer mAXQUERY = Limits.getLimitQueries();
        final Integer nUMQUERY = mAXQUERY - 1;
        System.assert(Limits.getQueries() < nUMQUERY, 'numero de querys dentro del rango  permitido');
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Método que retorna el id del recordtype correspondiente
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Method:      getRecordTypeId
    * @Date     Created: 2019-05-22
    * @param objectName -  name of the object
    * @return developerName -developerName for record type
    * @example getRecordTypeId(name)
    * ------------------------------------------------------------------------------------------------
    **/
    public static Id getRecordTypeId(String objectName, String developerName) {
        return [SELECT id FROM recordType WHERE SobjectType =: objectName AND DeveloperName =: developerName LIMIT 1][0].id;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Método que retorna el iaso correspondiente
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Method:      crearIasoUrlsCustomSettings
    * @Date     Created: 2019-05-22
    * @param void
    * @return return custom settings (iaso__GBL_Rest_Services_Url__c)
    * @example crearIasoUrlsCustomSettings(name)
    * ------------------------------------------------------------------------------------------------
    **/
    public static List<sObject> crearIasoUrlsCustomSettings() {

        final List<iaso__GBL_Rest_Services_Url__c> iasoCnfList = new List<iaso__GBL_Rest_Services_Url__c>();
        final map<String,String> iasoNameUrlMap = new map<String,String>();
        iasoNameUrlMap.put('GrantingTickets', 'https://maxwebseallo.prev.bancomer.mx/QSRV_A02/TechArchitecture/mx/grantingTicket/V02');
        iasoNameUrlMap.put('GrantingTicketsDev', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/TechArchitecture/mx/grantingTicket/V02');
        iasoNameUrlMap.put('pathEngine', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/risk-business-admissions/v0/risk-assessments/');
        iasoNameUrlMap.put('ratiosEngine', 'https://maxwebseal.bancomer.mx/QSRV_A02/enterpriseRatings/V01/');
        iasoNameUrlMap.put('financialStatements', 'https://maxwebseal.bancomer.mx/QSRV_A02/enterpriseRatings/V01/');
        iasoNameUrlMap.put('validateRatingPersistance', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/risks/v0/businesses-financial-relationships');
        iasoNameUrlMap.put('economicParticipations', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/economic-groups/v1/economic-groups/economic-participations');
        iasoNameUrlMap.put('listParticipants', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/economic-groups/v1/economic-groups/');
        iasoNameUrlMap.put('listCustomers', 'https://maxwebsealdesa.prev.bancomer.mx:6443/SRVS_A02/customers/v1/customers');
        iasoNameUrlMap.put('ratingEngine', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/risk-business-admissions/v0/risk-assessments');
        iasoNameUrlMap.put('triageEngine', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/risk-business-admissions/v0/risk-assessments');
        iasoNameUrlMap.put('encryptClients', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/proxyValueCipher/V01/security');
        iasoNameUrlMap.put('riskassessments', 'https://maxwebsealdesa.prev.bancomer.mx:6443/QSRV_A02/proxyValueCipher/V01/security');
        iasoNameUrlMap.put('financialStatementDetails', 'https://maxwebsealdesa.prev.bancomer.mx:6443/SRVS_A02/businesses/v0/businesses/');
        iasoNameUrlMap.put('overRating', 'https://maxwebsealqa.prev.bancomer.mx/SRVS_A02/risk-business-admissions/v0/risk-assessments');
        iasoNameUrlMap.put('riskFilters', 'https://maxwebsealdesa.prev.bancomer.mx:6443/SRVS_A02/risks/v1/risk-filters');
        iasoNameUrlMap.put('riskFiltersGroup', 'https://maxwebsealdesa.prev.bancomer.mx:6443/SRVS_A02/economic-groups/v1/economic-groups/');
        iaso__GBL_Rest_Services_Url__c cSetting = null;
        for(String key : iasoNameUrlMap.keySet()) {
            cSetting = new iaso__GBL_Rest_Services_Url__c();
            cSetting.name = key;
            cSetting.iaso__Url__c = iasoNameUrlMap.get(key);
            iasoCnfList.add(cSetting);
        }

        return iasoCnfList;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Método que retorna un objeto User
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearUsuario
    * @param strLastName param for create user
    * @param strProfileName param for create user
    * @param strRol param for create user
    * @return User created
    * @example crearUsuario(String strLastName, String strProfileName, String strRol) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static User crearUsuario(String strLastName, String strProfileName, String strRol) {
        lstProfile = new List<Profile>();
        userRole = new List<UserRole> ();
        Double random = Math.random();
        if(String.isNotBlank(strProfileName)) {
            lstProfile = [SELECT Id, Name FROM Profile WHERE Name = :strProfileName LIMIT 1];
        }
        if(String.isNotBlank(strRol)) {
            userRole = [SELECT Id, Name FROM UserRole WHERE Name = :strRol LIMIT 1];
        }

        final String email            = 'tstBBVA'+(Math.random()*10000)+'@bbva.test.com';
        final User usuario            = new User();
        usuario.LastName              = strLastName;
        usuario.Alias                 = String.valueOf((Math.random()*10000).round());
        usuario.Email                 = email;
        usuario.UserName              = email;
        usuario.EmailEncodingKey      = 'UTF-8';
        usuario.LanguageLocaleKey     = 'en_US';
        usuario.TimeZoneSidKey        = 'America/Mexico_City';
        usuario.LocaleSidKey          = 'en_US';
        usuario.IsActive              = true;
        if(!lstProfile.isEmpty()) {
            usuario.ProfileId         = lstProfile[0].Id;
        }
        if(!userRole.isEmpty()) {
            usuario.UserRoleId        = userRole[0].Id;
        }
        usuario.CompanyName           = 'SulAmérica';
        usuario.ID_User__c = 'Test' + email.substring(0, 3) + String.valueOf(random).substring(0, 3);
        return usuario;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto cliente
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearCuenta
    * @param strName   param for create Account
    * @param devNamTipReg   param for create Account
    * @param idParentAccount   param for create Account
    * @param strNumber param for create Account
    * @return Account created
    * @example crearCuenta(String strName, String devNamTipReg, Id idParentAccount, String strNumber) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static Account crearCuenta(String strName, String devNamTipReg, Id idParentAccount, String strNumber) {
        final Account cliente          = new Account();
        cliente.Name             = strName;
        cliente.AccountNumber    = strNumber;
        cliente.parentId = idParentAccount;
        cliente.bbva_total_debt_amount__c = 0;
        cliente.controlled_by_sponsor_type__c = '1';
        cliente.bank_id__c = '01';
        return cliente;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Analysis__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearArceAnalysis
    * @param strName   param for create arce__Analysis__c
    * @param devNamTipReg   param for create arce__Analysis__c
    * @param accountGroup   param for create arce__Analysis__c
    * @return arce__Analysis__c created
    * @example crearArceAnalysis(String strName, String devNamTipReg, id accountGroupId) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Analysis__c crearArceAnalysis(String strName, String devNamTipReg, id accountGroupId) {

        final arce__Analysis__c arceVar = new arce__Analysis__c();
        arceVar.Name = strName;
        arceVar.arce__Group__c = accountGroupId;
        if (devNamTipReg != null) {
            arceVar.RecordTypeId = getRecordTypeId('arce__Analysis__c', devNamTipReg);
        }
        arceVar.arce__Stage__c = '1';
        arceVar.arce__wf_status_id__c = '01';

        return arceVar;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Sector__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearSector
    * @param strName   param for create arce__Sector__c
    * @param sectorType   param for create arce__Sector__c
    * @param devNamTipReg   param for create arce__Sector__c
    * @return arce__Sector__c created
    * @example crearSector(String strName, String sectorType, String sectorDeveloperName, String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Sector__c crearSector(String strName, String sectorType, String sectorDeveloperName, String devNamTipReg) {
        final arce__Sector__c sector = new arce__Sector__c();
        sector.Name = strName;
        sector.arce__developer_name__c = sectorDeveloperName;
        sector.arce__analysis_template_id__c = sectorDeveloperName;
        sector.arce__analysis_section_type__c = sectorType;
        sector.arce__sector_analisis_type__c = '2';
        sector.arce__analysis_section_list__c = 's-01-100;s-01-200;s-01-300;s-01-400;s-01-500;s-01-600';
        sector.arce__active_type__c = true;
        sector.arce__unique_id__c = String.valueof(Integer.valueOf((Math.random() * 100000)));
        if(devNamTipReg != null) {
            sector.RecordTypeId = getRecordTypeId('arce__Sector__c', devNamTipReg);
        }
        return sector;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Account_has_Analysis__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      AccountHasAnalysis
    * @param sectorId   param for create arce__Account_has_Analysis__c
    * @param arceAnalysis   param for create arce__Account_has_Analysis__c
    * @param clientId   param for create arce__Account_has_Analysis__c
    * @param devNamTipReg   param for create arce__Account_has_Analysis__c
    * @return arce__Account_has_Analysis__c created
    * @example crearAccHasAnalysis(Id sectorId, Id arceAnalysisId, Id clientId, String sectorRtType) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Account_has_Analysis__c crearAccHasAnalysis(Id sectorId, Id arceAnalysisId, Id clientId, String sectorRtType) {

        final arce__Account_has_Analysis__c accHasAnalysis = new arce__Account_has_Analysis__c();
        accHasAnalysis.arce__gf_company_economic_actvy_id__c = String.valueOf((Math.random()*10000000).round());
        accHasAnalysis.arce__analysis_template_id__c = sectorRtType;
        accHasAnalysis.arce__Analysis__c = arceAnalysisId;
        accHasAnalysis.arce__Customer__c = clientId;
        accHasAnalysis.arce__enterprise_group_type__c = '1';
        accHasAnalysis.arce__client_refinanced_type__c = '1';
        accHasAnalysis.arce__client_refinanced_desc__c = 'Test de Prueba';
        accHasAnalysis.arce__sector_desc__c = 'Hoteleria';
        accHasAnalysis.arce__subsector_desc__c = 'sub Hoteleria';
        accHasAnalysis.arce__economic_activity_sector_desc__c ='Comercio';
        accHasAnalysis.arce__rating_econ_sector_tmpl_id__c = '4';
        accHasAnalysis.arce__currency_id__c = 'EUR';
        accHasAnalysis.arce__employees_number__c = 300;
        accHasAnalysis.arce__dependency_degree_cust_type__c = '1';
        return accHasAnalysis;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Financial_Statements__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearFinStatement
    * @param clientId   param for create arce__Financial_Statements__c
    * @param accHasAnalysisId   param for create arce__Financial_Statements__c
    * @param ratingId   param for create arce__Financial_Statements__c
    * @param devNamTipReg   param for create arce__Financial_Statements__c
    * @return arce__Financial_Statements__c created
    * @example crearFinStatement(Id clientId, Id accHasAnalysisId, Id ratingId, String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Financial_Statements__c crearFinStatement(Id clientId, Id accHasAnalysisId, Id ratingId, String devNamTipReg) {

        final arce__Financial_Statements__c finStatement = new arce__Financial_Statements__c();
        finStatement.arce__account_id__c = clientId;
        finStatement.arce__account_has_analysis_id__c = accHasAnalysisId;
        finStatement.arce__rating_id__c = ratingId;
        finStatement.arce__status_type__c = '2';
        if(devNamTipReg != null) {
            finStatement.RecordTypeId = getRecordTypeId('arce__Financial_Statements__c', devNamTipReg);
        }
        return finStatement;
    }


    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__rating__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearRating
    * @param devNamTipReg   param for create arce__rating__c
    * @return arce__rating__c created
    * @example crearRating(String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__rating__c crearRating(String devNamTipReg) {

        final arce__rating__c rating = new arce__rating__c();
        if(devNamTipReg != null) {rating.RecordTypeId = getRecordTypeId('arce__rating__c', devNamTipReg);}

        return rating;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__rating__c con detalle
    * ------------------------------------------------------------------------------------------------
    * @Author   Eduardo Efraín Hernandez Rendon  eduardoefrain.hernandez.contractor@bbva.com
    * @Date     Created: 2020-02-25
    * @Method:  createRatingObj
    * @param String ratingId - Unique Id of the calculated rating
    * @param String longFinalValue - Final Rating expressed in long scale
    * @param String shortFinalValue - Final Rating expressed in short scale
    * @param String ratingStatus - Status of the rating Calculated(2)/Validated(3)
    * @return arce__rating__c created
    * @example createRatingObj(String ratingId, String longFinalValue, String shortFinalValue, String ratingStatus)
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__rating__c createRatingObj(String ratingId, String longFinalValue, String shortFinalValue, String ratingStatus) {

        final arce__rating__c rating = new arce__rating__c();
        rating.arce__rating_id__c = ratingId;
        rating.arce__rating_long_value_type__c = longFinalValue;
        rating.arce__rating_short_value_type__c = shortFinalValue;
        rating.arce__status_type__c = ratingStatus;

        return rating;
    }


    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__rating_variables_detail__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearRatingVarDetails
    * @param devNamTipReg   param for create arce__rating_variables_detail__c
    * @return arce__rating_variables_detail__c created
    * @example crearRatingVarDetails(Id accHasAnalysisId, Id ratingId, String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__rating_variables_detail__c crearRatingVarDetails(Id accHasAnalysisId, Id ratingId, String devNamTipReg) {

        final arce__rating_variables_detail__c ratingVarDetails = new arce__rating_variables_detail__c();
        ratingVarDetails.arce__account_has_analysis_id__c = accHasAnalysisId;
        ratingVarDetails.arce__rating_id__c = ratingId;
        return ratingVarDetails;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__limits_typology__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearLimitTypology
    * @param strName   param for create arce__limits_typology__c
    * @param parentTypologyId   param for create arce__limits_typology__c
    * @param typoLevelId   param for create arce__limits_typology__c
    * @return arce__limits_typology__c created
    * @example crearLimitTypology(String strName, Id parentTypologyId, String typoLevelId) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__limits_typology__c crearLimitTypology(String strName, Id parentTypologyId, String typoLevelId) {

        final arce__limits_typology__c limitTyp = new arce__limits_typology__c();
        limitTyp.arce__risk_typology_level_id__c = typoLevelId;
        limitTyp.Name = strName;
        limitTyp.arce__risk_typology_parent_id__c = parentTypologyId;

        return limitTyp;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__limits_exposures__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearLimitExposures
    * @param parentExp   param for create arce__limits_exposures__c
    * @param devNamTipReg   param for create arce__limits_exposures__c
    * @param accHas   param for create arce__limits_exposures__c
    * @param limitTyp   param for create arce__limits_exposures__c
    * @return arce__limits_exposures__c created
    * @example crearLimitExposures(Id parentExp, String devNamTipReg, Id accHas, Id limitTyp) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__limits_exposures__c crearLimitExposures(Id parentExp, String devNamTipReg, Id accHas, Id limitTyp) {
        final arce__limits_exposures__c limitExp = new arce__limits_exposures__c();
        limitExp.arce__account_has_analysis_id__c = accHas;
        limitExp.arce__limits_typology_id__c = limitTyp;
        limitExp.arce__limits_exposures_parent_id__c = parentExp;
        return limitExp;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Data_Collections__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearDataCollection
    * @param strName   param for create arce__Data_Collections__c
    * @param devNamTipReg   param for create arce__Data_Collections__c
    * @param collectionType   param for create arce__Data_Collections__c
    * @return arce__Data_Collections__c created
    * @example crearDataCollection(String strName, String devNamTipReg,String collectionType) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Data_Collections__c crearDataCollection(String strName, String devNamTipReg,String collectionType) {
        final arce__Data_Collections__c dataCol = new arce__Data_Collections__c();
        dataCol.Name = strName;
        dataCol.arce__collection_table__c = collectionType;
        if(devNamTipReg != null) {dataCol.RecordTypeId = getRecordTypeId('arce__Data_Collections__c', devNamTipReg);}

        return dataCol;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__main_banks__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearMainBanks
    * @param accHasAnalysisId   param for create arce__main_banks__c
    * @param devNamTipReg   param for create arce__main_banks__c
    * @return arce__main_banks__c created
    * @example crearMainBanks(Id accHasAnalysisId, String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__main_banks__c crearMainBanks(Id accHasAnalysisId, String devNamTipReg) {

        final arce__main_banks__c mainBanks = new arce__main_banks__c();
        mainBanks.arce__account_has_analysis_id__c = accHasAnalysisId;
        if(devNamTipReg != null) {
            mainBanks.RecordTypeId = getRecordTypeId('arce__main_banks__c', devNamTipReg);
        }
        return mainBanks;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__risk_position_summary__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearRiskPositionSummary
    * @param accHasAnalysisId   param for create arce__risk_position_summary__c
    * @param devNamTipReg   param for create arce__risk_position_summary__c
    * @return arce__risk_position_summary__c created
    * @example crearRiskPositionSummary(Id accHasAnalysisId, String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__risk_position_summary__c crearRiskPositionSummary(Id accHasAnalysisId, String devNamTipReg) {

        final arce__risk_position_summary__c riskPosSummary = new arce__risk_position_summary__c();
        riskPosSummary.arce__account_has_analysis_id__c = accHasAnalysisId;
        if(devNamTipReg != null) {riskPosSummary.RecordTypeId = getRecordTypeId('arce__risk_position_summary__c', devNamTipReg);}

        return riskPosSummary;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Table_Content_per_Analysis__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearTableContentAnalysis
    * @param accHasAnalysisId   param for create arce__Table_Content_per_Analysis__c
    * @param dataColId   param for create arce__Table_Content_per_Analysis__c
    * @param devNamTipReg   param for create arce__Table_Content_per_Analysis__c
    * @param year   param for create arce__Table_Content_per_Analysis__c
    * @return arce__Table_Content_per_Analysis__c created
    * @example crearTableContentAnalysis(Id accHasAnalysisId, Id dataColId, String devNamTipReg,String year) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Table_Content_per_Analysis__c crearTableContentAnalysis(Id accHasAnalysisId, Id dataColId, String devNamTipReg,String year) {

        final arce__Table_Content_per_Analysis__c tableContAnalysis = new arce__Table_Content_per_Analysis__c();
        tableContAnalysis.arce__account_has_analysis_id__c = accHasAnalysisId;
        tableContAnalysis.arce__Data_Collection_Id__c = dataColId;
        tableContAnalysis.arce__table_content_year__c=year;
        if(devNamTipReg != null) {tableContAnalysis.RecordTypeId = getRecordTypeId('arce__Table_Content_per_Analysis__c', devNamTipReg);}
        return tableContAnalysis;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Third_Participant__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearTableContentAnalysis
    * @param devNamTipReg   param for create arce__Third_Participant__c
    * @return arce__Third_Participant__c created
    * @example crearThirdParticipant(String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Third_Participant__c crearThirdParticipant(String devNamTipReg) {

        final arce__Third_Participant__c thirdParticipant = new arce__Third_Participant__c();
        if(devNamTipReg != null) {thirdParticipant.RecordTypeId = getRecordTypeId('arce__Third_Participant__c', devNamTipReg);}

        return thirdParticipant;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto arce__Third_Participant_Details__c
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearThirdParticipantDetails
    * @param accHasAnalysisId   param for create arce__Third_Participant_Details__c
    * @param thirdPartId   param for create arce__Third_Participant_Details__c
    * @param devNamTipReg   param for create arce__Third_Participant_Details__c
    * @return arce__Third_Participant_Details__c created
    * @example crearThirdParticipantDetails(Id accHasAnalysisId, Id thirdPartId, String devNamTipReg) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Third_Participant_Details__c crearThirdParticipantDetails(Id accHasAnalysisId, Id thirdPartId, String devNamTipReg) {

        final arce__Third_Participant_Details__c thirdPartDetails = new arce__Third_Participant_Details__c();
        thirdPartDetails.arce__account_has_analysis_id__c = accHasAnalysisId;
        thirdPartDetails.arce__Third_Participant_id__c = thirdPartId;
        if(devNamTipReg != null) {thirdPartDetails.RecordTypeId = getRecordTypeId('arce__Third_Participant_Details__c', devNamTipReg);}

        return thirdPartDetails;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Method that creates products for test clases
    * ------------------------------------------------------------------------------------------------
    * @Author   Javier Soto Carrascosa javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-03-29
    * @Method:      setupProducts
    * @param void
    * @return void
    * @example setupProducts()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void setupProducts() {
        if (getSRAccounts('Arc_Gen_ProductTest').size() == 1) {
            Test.loadData(Product2.sObjectType, 'Arc_Gen_ProductTest');

            if (getSRAccounts('Arc_Gen_PricebookTestData').size() == 1 && getSRAccounts('Arc_Gen_PricebookEntryTestData').size() == 1) {
                createStandardPricebookEntries();
                Test.loadData(Pricebook2.sObjectType, 'Arc_Gen_PricebookTestData');
                Test.loadData(PricebookEntry.sObjectType, 'Arc_Gen_PricebookEntryTestData');
            }
        } else {
            Product2 prod1 = new Product2();
            prod1 = crearProduct2('testProduct', 'TP_0010', '000100030001');
            insert prod1;
            Product2 prod2 = new Product2();
            prod2 = crearProduct2('nameTest', 'familyTest', '000100030006');
            insert prod2;
            Product2 prod3 = new Product2();
            prod3 = crearProduct2('credito simple', null, '');
            insert prod3;
        }
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Method that creates a standard pricebook entry for each product.
    * ------------------------------------------------------------------------------------------------
    * @Author   José Luis García <joseluis.garcia4.contractor@bbva.com>
    * @Date     Created: 2020-06-12
    * @Method:  createStandardPricebookEntries()
    * @param void
    * @return void
    * ------------------------------------------------------------------------------------------------
    **/
    private static void createStandardPricebookEntries() {
        final List<Product2> products = [SELECT Id FROM Product2];   // NOSONAR
        final List<PricebookEntry> entries = new List<PricebookEntry>();

        for (Product2 product : products) {
            entries.add(crearPriceBook(product.Id, 0, true));
        }

        insert entries;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto Product2
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearProduct2
    * @param name   param for create Product2
    * @param family   param for create Product2
    * @return Product2 created
    * @example crearProduct2(String name, String family) {
    * ------------------------------------------------------------------------------------------------
    **/
    private static Product2 crearProduct2(String name, String family, String externalId) {
        final Product2 nuevoProducto = new Product2();
        nuevoProducto.Name = name;
        nuevoProducto.Family = family;
        nuevoProducto.IsActive = true;
        nuevoProducto.ExternalId = externalId;

        return nuevoProducto;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto PriceBookEntry
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearPriceBook
    * @param objProductID   param for create PriceBookEntry
    * @param unitPrice   param for create PriceBookEntry
    * @param active   param for create PriceBookEntry
    * @return PriceBookEntry created
    * @example crearPriceBook(ID objProductID, Integer unitPrice, Boolean active ) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static PriceBookEntry crearPriceBook(ID objProductID, Integer unitPrice, Boolean active ) {
        final PricebookEntry objPBEntry = new PricebookEntry();
        objPBEntry.PriceBook2Id = Test.getStandardPricebookId();
        objPBEntry.Product2Id=objProductID;
        objPBEntry.UnitPrice=unitPrice;
        objPBEntry.IsActive=active;
        return objPBEntry;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna profile Id
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearPriceBook
    * @param profName   param for create PriceBookEntry
    * @return profileId selected
    * @example getProfileID(String profName) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static Id getProfileID(String profName) {
        return [SELECT Id, Name FROM Profile WHERE Name =: profName ].Id;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto User
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      creaUserAdmin
    * @param profileId   param for create User
    * @param userName   param for create User
    * @return User created
    * @example creaUserAdmin(Id profileId, String userName) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static User creaUserAdmin(Id profileId, String userName) {
        final User admin = new User(
            Alias = 'User2',
            Email='adminAG2@bbva.test',
            EmailEncodingKey='ISO-8859-1',
            LastName='AmbientacionGeneral2',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = profileId,
            TimeZoneSidKey='America/Mexico_City',
            UserName= userName + '@bbva.test',
            IsActive=true
        );
        insert admin;
        return admin;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description create a template for dynamic form
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearTemplate
    * @param name -  name of the template
    * @return temp - dyfr__Template__c object
    * @example crearTemplate(name)
    * ------------------------------------------------------------------------------------------------
    **/
    public static dyfr__Template__c crearTemplate(string name) {
        final dyfr__Template__c temp = new dyfr__Template__c();
        temp.Name = name;
        return temp;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description create a tab for dynamic form
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearTab
    * @param name -  name of the tab
    * @param templateId - Id of the template object
    * @return tab - dyfr__Tab__c object
    * @example crearTab(name, templateId)
    * ------------------------------------------------------------------------------------------------
    **/
    public static dyfr__Tab__c crearTab(string name, Id templateId) {
        final dyfr__Tab__c tab = new dyfr__Tab__c();
        tab.Name = name;
        tab.dyfr__Template__c = templateId;
        return tab;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description create field config data for dynamic form
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearfieldConfigData
    * @param sectionName - name of the section
    * @param tabId - Id of the tab
    * @param mapField - name of the mapfield
    * @return fieldConfig - dyfr__Field_Config__c object
    * @example crearfieldConfigData(string sectionName, string tabId, string mapField) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static dyfr__Field_Config__c crearfieldConfigData(string sectionName, string tabId, string mapField) {
        final dyfr__Field_Config__c fieldConfig = new dyfr__Field_Config__c();
        fieldConfig.dyfr__Section_name__c = sectionName;
        fieldConfig.dyfr__Map_field__c = mapField;
        fieldConfig.dyfr__Label__c = 'Comments';
        fieldConfig.dyfr__Tab__c = tabId;
        return fieldConfig;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description - create arce__limits_exposures__c data
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @param tipoId - id of a typology
    * @param acchasID - Id of an account has analysis object
    * @param value - integer with the value of a field in arce__limits_exposures__c
    * @return limitExpo - arce__limits_exposures__c object
    * @example crearExposures(tipoId, acchasID, value)
    * ------------------------------------------------------------------------------------------------
    **/
    @TestVisible
    public arce__limits_exposures__c crearExposures(Id tipoId, Id acchasID, integer value) {
        final arce__limits_exposures__c limitExpo = new arce__limits_exposures__c();
        limitExpo.arce__limits_typology_id__c = tipoId;
        limitExpo.arce__account_has_analysis_id__c = acchasID;
        limitExpo.arce__current_approved_amount__c = value;
        limitExpo.arce__curr_apprv_uncommited_amount__c = 0;
        limitExpo.arce__curr_approved_commited_amount__c = 0;
        limitExpo.arce__current_formalized_amount__c = 0;
        limitExpo.arce__outstanding_amount__c = 0;
        limitExpo.arce__current_proposed_amount__c = 0;
        limitExpo.arce__last_approved_amount__c = 0;
        return limitExpo;
    }

    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for the assessment tab
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createAssessmentData()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void createAssessmentData() {
        final dyfr__Template__c template = arc_UtilitysDataTest_tst.crearTemplate('s-01-400');
        insert template;
        final dyfr__Tab__c tab = arc_UtilitysDataTest_tst.crearTab('Assessment', template.Id);
        tab.dyfr__Tab_Code__c = 'Generic_Assessment';
        insert tab;
        final dyfr__Field_Config__c fieldConfig = arc_UtilitysDataTest_tst.crearfieldConfigData('Peer Analysis', tab.Id, 'arce__ebitda_less_70_peer_avg_type__c');
        fieldConfig.dyfr__Important__c = true;
        fieldConfig.dyfr__Type__c = 'List';
        fieldConfig.dyfr__Read_only__c = false;
        fieldConfig.dyfr__Hidden__c = false;
        insert fieldConfig;
        final dyfr__Field_Config__c fieldConfig2 = arc_UtilitysDataTest_tst.crearfieldConfigData('Peer Analysis', tab.Id, 'arce__ebitda_less_70_peer_avg_desc__c');
        fieldConfig2.dyfr__Important__c = true;
        fieldConfig2.dyfr__Type__c = 'textArea';
        fieldConfig2.dyfr__Read_only__c = false;
        fieldConfig2.dyfr__Hidden__c = false;
        insert fieldConfig2;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for the banking relationship tab
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createBankingRelationshipDepData()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void createBankingRelationshipDepData() {
        final dyfr__Template__c template1 = arc_UtilitysDataTest_tst.crearTemplate('s-01-300');
        insert template1;
        final dyfr__Tab__c tab1 = arc_UtilitysDataTest_tst.crearTab('Banking Relationship', template1.Id);
        tab1.dyfr__Tab_Code__c = 'Generic_BankingRelationship';
        insert tab1;
        generateNoPathDependencyData(tab1);
        generatePathDependencyData(tab1);
        generateDoubleDependency(tab1);
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Generate fields without path dependency
    * ------------------------------------------------------------------------------------------------
    * @param dyfr__Tab__c tab object
    * @return void
    * @example generateNoPathDependencyData(tab)
    * ------------------------------------------------------------------------------------------------
    **/
    public static void generateNoPathDependencyData(dyfr__Tab__c tab) {
        final dyfr__Field_Config__c fieldConfig = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__cust_conc_clients_type__c');
        fieldConfig.dyfr__Important__c = true;
        fieldConfig.dyfr__Type__c = 'radio group';
        fieldConfig.dyfr__Read_only__c = false;
        fieldConfig.dyfr__Hidden__c = false;
        fieldConfig.dyfr__DeveloperName__c = 'control';
        insert fieldConfig;
        final dyfr__Field_Config__c fieldConfig2 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__cust_conc_clients_desc__c');
        fieldConfig2.dyfr__Important__c = true;
        fieldConfig2.dyfr__Type__c = 'textArea';
        fieldConfig2.dyfr__Read_only__c = false;
        fieldConfig2.dyfr__Hidden__c = false;
        fieldConfig2.dyfr__Visibility_control_field__c = 'control';
        fieldConfig2.dyfr__Visibility_control_value__c = '1';
        insert fieldConfig2;
        final dyfr__Field_Config__c fieldConfig3 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__risk_position_summary_desc__c');
        fieldConfig3.dyfr__Important__c = true;
        fieldConfig3.dyfr__Type__c = 'textArea';
        fieldConfig3.dyfr__Read_only__c = false;
        fieldConfig3.dyfr__Hidden__c = false;
        fieldConfig3.dyfr__Visibility_control_field__c = 'control';
        fieldConfig3.dyfr__Visibility_control_value__c = '1';
        insert fieldConfig3;
        final dyfr__Field_Config__c fieldConfig4 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__level_concentration_geo_desc__c');
        fieldConfig4.dyfr__Important__c = true;
        fieldConfig4.dyfr__Type__c = 'textArea';
        fieldConfig4.dyfr__Read_only__c = false;
        fieldConfig4.dyfr__Hidden__c = false;
        fieldConfig4.dyfr__Visibility_control_field__c = 'control';
        fieldConfig4.dyfr__Visibility_control_value__c = '2';
        insert fieldConfig4;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Generate fields with path dependency
    * ------------------------------------------------------------------------------------------------
    * @param dyfr__Tab__c tab object
    * @return void
    * @example generatePathDependencyData(tab)
    * ------------------------------------------------------------------------------------------------
    **/
    public static void generatePathDependencyData(dyfr__Tab__c tab) {
        final dyfr__Field_Config__c fieldConfig5 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__path__c');
        fieldConfig5.dyfr__Important__c = true;
        fieldConfig5.dyfr__Type__c = 'textArea';
        fieldConfig5.dyfr__Read_only__c = false;
        fieldConfig5.dyfr__Hidden__c = false;
        fieldConfig5.dyfr__DeveloperName__c = 'campoPath';
        insert fieldConfig5;
        final dyfr__Field_Config__c fieldConfig6 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__customer_multi_country_desc__c');
        fieldConfig6.dyfr__Important__c = true;
        fieldConfig6.dyfr__Type__c = 'textArea';
        fieldConfig6.dyfr__Read_only__c = false;
        fieldConfig6.dyfr__Hidden__c = false;
        fieldConfig6.dyfr__Visibility_control_field__c = 'campoPath';
        fieldConfig6.dyfr__Visibility_control_value__c = 'MAC';
        insert fieldConfig6;
        final dyfr__Field_Config__c fieldConfig7 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__fin_spnsr_relnshp_exprnc_desc__c');
        fieldConfig7.dyfr__Important__c = true;
        fieldConfig7.dyfr__Type__c = 'textArea';
        fieldConfig7.dyfr__Read_only__c = false;
        fieldConfig7.dyfr__Hidden__c = false;
        fieldConfig7.dyfr__Visibility_control_field__c = 'campoPath';
        fieldConfig7.dyfr__Visibility_control_value__c = 'MAC';
        insert fieldConfig7;
        final dyfr__Field_Config__c fieldConfig8 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__banking_pool_desc__c');
        fieldConfig8.dyfr__Important__c = true;
        fieldConfig8.dyfr__Type__c = 'textArea';
        fieldConfig8.dyfr__Read_only__c = false;
        fieldConfig8.dyfr__Hidden__c = false;
        fieldConfig8.dyfr__Visibility_control_field__c = 'campoPath';
        fieldConfig8.dyfr__Visibility_control_value__c = 'MAB1';
        insert fieldConfig8;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Generate fields with double dependency
    * ------------------------------------------------------------------------------------------------
    * @param dyfr__Tab__c tab object
    * @return void
    * @example generateDoubleDependency(tab)
    * ------------------------------------------------------------------------------------------------
    **/
    public static void generateDoubleDependency(dyfr__Tab__c tab) {
        final dyfr__Field_Config__c fieldConfig9 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__sector_desc__c');
        fieldConfig9.dyfr__Important__c = true;
        fieldConfig9.dyfr__Type__c = 'textArea';
        fieldConfig9.dyfr__Read_only__c = false;
        fieldConfig9.dyfr__Hidden__c = false;
        fieldConfig9.dyfr__Visibility_control_field__c = 'campoPath;control';
        fieldConfig9.dyfr__Visibility_control_value__c = 'MAC;2';
        insert fieldConfig9;
        final dyfr__Field_Config__c fieldConfig10 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__main_affiliates_desc__c');
        fieldConfig10.dyfr__Important__c = true;
        fieldConfig10.dyfr__Type__c = 'textArea';
        fieldConfig10.dyfr__Read_only__c = false;
        fieldConfig10.dyfr__Hidden__c = false;
        fieldConfig10.dyfr__Visibility_control_field__c = 'campoPath;control';
        fieldConfig10.dyfr__Visibility_control_value__c = 'MAC;1';
        insert fieldConfig10;
        final dyfr__Field_Config__c fieldConfig11 = arc_UtilitysDataTest_tst.crearfieldConfigData('CONCENTRATION', tab.Id, 'arce__fin_aggressiveness_mngmt_desc__c');
        fieldConfig11.dyfr__Important__c = true;
        fieldConfig11.dyfr__Type__c = 'textArea';
        fieldConfig11.dyfr__Read_only__c = false;
        fieldConfig11.dyfr__Hidden__c = false;
        fieldConfig11.dyfr__Visibility_control_field__c = 'campoPath;control';
        fieldConfig11.dyfr__Visibility_control_value__c = 'MAC;1';
        insert fieldConfig11;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for the basic data tab
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createBasicDataData()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void createBasicDataData() {
        final dyfr__Template__c template2 = arc_UtilitysDataTest_tst.crearTemplate('s-01-100');
        insert template2;
        final dyfr__Tab__c tab = crearTab('Basic Data', template2.Id);
        tab.dyfr__Tab_Code__c = 'Generic_BasicData';
        insert tab;
        final dyfr__Field_Config__c fieldConfig12 = crearfieldConfigData('Main Subsidiaries and affiliates', tab.Id, 'arce__mngmt_aggressiveness_type__c');
        fieldConfig12.dyfr__Important__c = true;
        fieldConfig12.dyfr__Type__c = 'List';
        fieldConfig12.dyfr__Read_only__c = false;
        fieldConfig12.dyfr__Hidden__c = false;
        insert fieldConfig12;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for the financial risk tab
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createFinancialRiskData()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void createFinancialRiskData() {
        final dyfr__Template__c template3 = arc_UtilitysDataTest_tst.crearTemplate('s-01-100');
        insert template3;
        final dyfr__Tab__c tab = arc_UtilitysDataTest_tst.crearTab('Financial Risk', template3.Id);
        tab.dyfr__Tab_Code__c = 'Generic_FinancialRisk';
        insert tab;
        final dyfr__Field_Config__c fieldConfig13 = arc_UtilitysDataTest_tst.crearfieldConfigData('Peer Analysis', tab.Id, 'arce__years_experience_mngmt_type__c');
        fieldConfig13.dyfr__Important__c = true;
        fieldConfig13.dyfr__Type__c = 'List';
        fieldConfig13.dyfr__Read_only__c = false;
        fieldConfig13.dyfr__Hidden__c = false;
        insert fieldConfig13;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for the business risk tab
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createBusinessRiskData()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void createBusinessRiskData() {
        final dyfr__Template__c template4 = arc_UtilitysDataTest_tst.crearTemplate('s-01-100');
        insert template4;
        final dyfr__Tab__c tab = arc_UtilitysDataTest_tst.crearTab('Business Risk', template4.Id);
        tab.dyfr__Tab_Code__c = 'Generic_BusinessRisk';
        insert tab;
        final dyfr__Field_Config__c fieldConfig14 = arc_UtilitysDataTest_tst.crearfieldConfigData('Peer Analysis', tab.Id, 'arce__years_experience_mngmt_type__c');
        fieldConfig14.dyfr__Important__c = true;
        fieldConfig14.dyfr__Type__c = 'List';
        fieldConfig14.dyfr__Read_only__c = false;
        fieldConfig14.dyfr__Hidden__c = false;
        insert fieldConfig14;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for the industry analysis tab
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createIndustryAnalysisData()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void createIndustryAnalysisData() {
        final dyfr__Template__c template5 = arc_UtilitysDataTest_tst.crearTemplate('s-01-100');
        insert template5;
        final dyfr__Tab__c tab = arc_UtilitysDataTest_tst.crearTab('Industry Analysis', template5.Id);
        tab.dyfr__Tab_Code__c = 'Generic_IndustryAnalysis';
        insert tab;
        final dyfr__Field_Config__c fieldConfig14 = arc_UtilitysDataTest_tst.crearfieldConfigData('Peer Analysis', tab.Id, 'arce__management_style_type__c');
        fieldConfig14.dyfr__Important__c = true;
        fieldConfig14.dyfr__Type__c = 'List';
        fieldConfig14.dyfr__Read_only__c = false;
        fieldConfig14.dyfr__Hidden__c = false;
        insert fieldConfig14;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for the Policies tab
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createPolicies()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void createPolicies() {
        final dyfr__Template__c template5 = arc_UtilitysDataTest_tst.crearTemplate('s-01-500');
        insert template5;
        final dyfr__Tab__c tab = arc_UtilitysDataTest_tst.crearTab('Policies', template5.Id);
        tab.dyfr__Tab_Code__c = 'Generic_Policies';
        insert tab;
        final dyfr__Field_Config__c fieldConfig14 = arc_UtilitysDataTest_tst.crearfieldConfigData('Peer Analysis', tab.Id, 'arce__management_style_type__c');
        fieldConfig14.dyfr__Important__c = true;
        fieldConfig14.dyfr__Type__c = 'List';
        fieldConfig14.dyfr__Read_only__c = false;
        fieldConfig14.dyfr__Hidden__c = false;
        insert fieldConfig14;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create data for accounts
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example setupAcccounts()
    * ------------------------------------------------------------------------------------------------
    **/
    public static void setupAcccounts() {
        if (getSRAccounts('Arc_Gen_AccountTestDatachild').size() == 1 && getSRAccounts('Arc_Gen_AccountTestData').size() == 1) {
            Test.loadData(Account.sObjectType, 'Arc_Gen_AccountTestData');
            Test.loadData(Account.sObjectType, 'Arc_Gen_AccountTestDataChild');
        } else {
            Account grupo1 = new Account();
            grupo1 = crearCuenta('Group1Child', null, null, 'G000001');
            insert grupo1;
            Account grupo2 = new Account();
            grupo2 = crearCuenta('Group2Child', null, null, 'G000002');
            insert grupo2;
            Account cliente1 = new Account();
            cliente1 = crearCuenta('ChildGroup1', null, grupo1.Id, 'C000001');
            insert cliente1;
            Account cliente2 = new Account();
            cliente2 = crearCuenta('Child2Group1', null, grupo1.Id, 'C000002');
            insert cliente2;
            Account cliente3 = new Account();
            cliente3 = crearCuenta('ChildGroup2', null, grupo2.Id, 'C000004');
            insert cliente3;
            Account orphan1 = new Account();
            orphan1 = crearCuenta('OrphanChild', null, null, 'C000003');
            insert orphan1;
        }
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description validate if a static resource exists for account creation
    * ------------------------------------------------------------------------------------------------
    * @Author   Javier Soto Carrascosa javier.soto.carrascosa@bbva.com
    * @Date     Created: 2019-11-25
    * @Method:      getSRAccounts
    * @param name -  Void
    * @return List<StaticResource>
    * @example getSRAccounts()
    * ------------------------------------------------------------------------------------------------
    **/
    public static List<StaticResource> getSRAccounts(string fileName) {
        return new List<StaticResource>([SELECT Id FROM StaticResource where Name=:fileName]);
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create config in arce config metadata
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return void
    * @example createArceConfig()
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__Arce_Config__mdt createArceConfig(String name, String value) {
        final arce__Arce_Config__mdt arceConfig = new arce__Arce_Config__mdt();
        arceConfig.DeveloperName = name;
        arceConfig.Label = name;
        arceConfig.arce__Config_Name__c = name;
        arceConfig.arce__Value1__c = value;

        return arceConfig;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description: Método que retorna un objeto cliente
    * ------------------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-05-22
    * @Method:      crearCuentaGrupo
    * @param strName   param for create Account
    * @param devNamTipReg   param for create Account
    * @param strNumber   param for create Account
    * @return Account created
    * @example crearCuentaGrupo(String strName, String devNamTipReg, String strNumber) {
    * ------------------------------------------------------------------------------------------------
    **/
    public static Account crearCuentaGrupo(String strName, String devNamTipReg, String strNumber) {
        final Account cliente          = new Account();
        cliente.Name             = strName;
        cliente.AccountNumber    = strNumber;
        cliente.Industry         = 'Construction';
        return cliente;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create Delegation_Wrapper mockup
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return Arc_Gen_Delegation_Wrapper
    * @example Arc_Gen_Delegation_Wrapper = crearDelegationWrapper();
    * ------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_Delegation_Wrapper crearDelegationWrapper() {
        final Arc_Gen_Delegation_Wrapper wrapper = new Arc_Gen_Delegation_Wrapper();
        final List<String> valuesSelected = new List<String>{'1', '2'};
        final List<Map<String,String>> lstPicklist = arce.Arc_Gen_GenericUtilities.getPicklistValuesLabels('arce__Analysis__c','arce__anlys_wkfl_edit_br_level_type__c', valuesSelected);
        wrapper.lstAmbits = lstPicklist;
        wrapper.sanctionAmbit = '4';
        wrapper.hasDelegation = 'NO';
        wrapper.codStatus = 200;
        wrapper.msgInfo = 'OK';
        return wrapper;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create Delegation_Wrapper mockup
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return Arc_Gen_Delegation_Wrapper
    * @example Arc_Gen_Delegation_Wrapper = crearDelegationWrapper();
    * ------------------------------------------------------------------------------------------------
    **/
    public static Map<String, String> crearMapaSaveScopeSanction(Id recordId, String sanction) {
        final Map<String, String> data = new Map<String, String>();
        data.put('recordId', recordId);
        data.put('idUserSelected', UserInfo.getUserId());
        data.put('userSelected', UserInfo.getName());
        data.put('sanction', sanction);
        data.put('descText', 'description');
        data.put('sancDate', String.valueOf(datetime.now()) );
        data.put('sancdateCometee', String.valueOf(datetime.now()));
        return data;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create Arc_Gen_CallListParticipant.Innertoreturnlistp mockup
    * ------------------------------------------------------------------------------------------------
    * @param void
    * @return Arc_Gen_CallListParticipant.Innertoreturnlistp
    * @example Arc_Gen_CallListParticipant.Innertoreturnlistp wrap = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
    * ------------------------------------------------------------------------------------------------
    **/
    public static Arc_Gen_CallListParticipant.Innertoreturnlistp createResponseLstParticipants() {
        final String sqr = ' {"messages": [' +
                    '  ],' +
                    '  "data": [' +
                    '    {' +
                    '      "id": "174916181111",' +
                    '      "participantName": {' +
                    '        "firstName": "BANQUE",' +
                    '        "middleName": "NATIONALE MAS",' +
                    '        "lastName": "Skylynde",' +
                    '        "secondLastName": "Anya"' +
                    '      },' +
                    '      "relation": {' +
                    '        "level": "03",' +
                    '        "relationType": {' +
                    '          "id": "IG"' +
                    '        },' +
                    '        "parentEconomicGroup": {' +
                    '          "id": "IV019470"' +
                    '        }' +
                    '      }' +
                    '    },' +
                    '    {' +
                    '      "id": "1111174994948",' +
                    '      "participantName": {' +
                    '        "firstName": "BANQUE",' +
                    '        "middleName": "NATIONALE MAS",' +
                    '        "lastName": "Skylynde",' +
                    '        "secondLastName": "Anya"' +
                    '      },' +
                    '      "relation": {' +
                    '        "level": "03",' +
                    '        "relationType": {' +
                    '          "id": "IG"' +
                    '        },' +
                    '        "parentEconomicGroup": {' +
                    '          "id": "IV019470"' +
                    '        }' +
                    '      }' +
                    '    }' +
                    '  ],' +
                    '  "pagination": {' +
                    '	"links": [{' +
                    '		"first": "https://test/economic-groups/v1/economic-groups/Wv2tuECK5tWrG-r8wUd65w/participants",' +
                    '		"next": "https://test/economic-groups/v1/economic-groups/Wv2tuECK5tWrG-r8wUd65w/participants?paginationKey=52781774"' +
                    '	}]' +
                    '  }' +
                    '}';
        return (Arc_Gen_CallListParticipant.Innertoreturnlistp) JSON.deserialize(sqr, Arc_Gen_CallListParticipant.Innertoreturnlistp.class);
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Set data to financial statement test
    * ------------------------------------------------------------------------------------------------
    * @param arce__Financial_Statements__c ffss
    * @param String ffssId
    * @param String adjusted
    * @param String certi
    * @param Date dateType
    * @return void
    * @example setupFFSS(ffss, '1', '1', '1', '1', 'AUDITED', Date.today());
    * ------------------------------------------------------------------------------------------------
    **/
    public static void setupFFSS(arce__Financial_Statements__c ffss, String params) {
        final Map<String, Object> mapParams = (Map<String, Object>) JSON.deserializeUntyped(params);
        ffss.arce__financial_statement_id__c = (String) mapParams.get('id');
        ffss.arce__ffss_submitted_type__c = (String) mapParams.get('submitType');
        ffss.arce__ffss_valid_type__c = (String) mapParams.get('validType');
        ffss.arce__ffss_adjusted_type__c = (String) mapParams.get('adjustedType');
        ffss.arce__ffss_certification_type__c = (String) mapParams.get('cerType');
        ffss.arce__financial_statement_end_date__c = Date.today().addDays(Integer.valueOf(mapParams.get('dateType')));
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Create a dependent value with the data of the params
    * ------------------------------------------------------------------------------------------------
    * @param Id field config id
    * @param String labels
    * @param String values
    * @return dyfr__Dependent_value__c
    * @example dyfr__Dependent_value__c dependent = crearDependentVal(fcId, labels, values);
    * ------------------------------------------------------------------------------------------------
    **/
    public static dyfr__Dependent_value__c crearDependentVal(Id fcId, String labels, String values) {
        final dyfr__Dependent_value__c depVal = new dyfr__Dependent_value__c();
        depVal.dyfr__LoV_labels__c = 'BAJO,MEDIO,ALTO';
        depVal.dyfr__LoV_values__c = '0012,0013,0014';
        depVal.dyfr__Field_Config__c = fcId;
        return depVal;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description Creates an arce__AHA_Extension__c object and associate it with the provided arce__Account_has_Analysis__c object.
    * Returns the created extension
    * ------------------------------------------------------------------------------------------------
    * @param Id arce__Account_has_Analysis__c
    * @return arce__AHA_Extension__c
    * @example arce__AHA_Extension__c ahaExt = newExtensionForAHA(ahaObj);
    * ------------------------------------------------------------------------------------------------
    **/
    public static arce__AHA_Extension__c newExtensionForAHA(arce__Account_has_Analysis__c aha) {
      final arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c();
      insert ahaExt;
      aha.arce__AHA_Extension__c = ahaExt.Id;
      update aha;
      return ahaExt;
    }
    /**
    * ------------------------------------------------------------------------------------------------
    * @Description get Projection List
    * ------------------------------------------------------------------------------------------------
    * @param Id ahaId
    * @return List<arce__Projection__c>
    * @example List<arce__Projection__c> prList = getprojectionList(ahaId);
    * ------------------------------------------------------------------------------------------------
    **/
    public static List<arce__Projection__c> getprojectionList(Id ahaId) {
        final List<arce__Projection__c> projectionList = new List<arce__Projection__c>();
        final arce__Projection__c pr1 = new arce__Projection__c();
        final arce__Projection__c pr2 = new arce__Projection__c();
        final arce__Projection__c pr3 = new arce__Projection__c();
        pr1.arce__Projection_Type__c = 'Anchor';
        pr1.arce__Scenario_Type__c = 'Base Case';
        pr1.arce__Account_has_Analysis__c = ahaId;
        projectionList.add(pr1);
        pr2.arce__Projection_Type__c = 'Projection';
        pr2.arce__Scenario_Type__c = 'Down';
        pr2.arce__Account_has_Analysis__c = ahaId;
        projectionList.add(pr2);
        pr3.arce__Projection_Type__c = 'Projection';
        pr3.arce__Scenario_Type__c = 'Up';
        pr3.arce__Account_has_Analysis__c = ahaId;
        projectionList.add(pr3);
        return projectionList;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Method to create a new arce__Bypass__c record. This record is used to bypass:
    *              - validation rules
    *              - triggers
    *              - flows
    *              - process builders
    *              - workflow rules
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        2024-08-14
    * -----------------------------------------------------------------------------------------------
    **/
    public static void enableBypass() {
        final String userId = UserInfo.getUserId();
        final arce__Bypass__c bypass = new arce__Bypass__c(
            Name = 'ARCE Bypass (Test)',
            SetupOwnerId = userId,
            arce__Bypass_Flows__c = true,
            arce__Bypass_ProcessBuilders__c = true,
            arce__Bypass_Triggers__c = true,
            arce__Bypass_ValidationRules__c = true,
            arce__Bypass_WorkflowRules__c = true
        );
        Database.insert(bypass, AccessLevel.SYSTEM_MODE);
    }
}