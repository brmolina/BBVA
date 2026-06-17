/**
 * @author       Accenture
 * @date         01/03/2016
 * @description  Manejador del trigger para el objeto Account. No implementar logica aquí, para ello utilizar ActivitiesUtils
 * @Revision
 *   2017/10/26 Se deja de utilizar customActivity (Activity__c) y se comentan las líneas de código que ya no aplican
 *   2018/06/11 Añadida lógica en el método assignRecordType para poner el Recordtype en las cargas de la parte de DESKTOP
 *   2018/06/14 Añadida lógica en el método assignRecordType para poner el Recordtype en las cargas antiguas de SALES del Dataloader para las contrapartidas de INTRANET
 *   2018/07/18 Añadido método setRevenueUpdateEngloba para poner el valor de la fecha de Engloba
 *   2018/07/20 Actualizada lógica en el método assignRecordType para poner el Recordtype correctamente
 *   2018/08/10 Actualizada lógica en los métodos assignRecordType y setRecordType para el nuevo tipo NO_CLIENT
 *   2019/08/21 Actualizada lógica en el método assignRecordType para las cargas de Contrapartidas de Dataloader
 * any
 */
@SuppressWarnings('sf:NcssMethodCount')
public with sharing class AccountTriggerHandler {

    private static final String NULO = '--null--';
    public static String profileName;
    private final CIB_User_Org__c userSettings = CIB_User_Org__c.getInstance();
    private static AccountTriggerHandler instance;

    public static AccountTriggerHandler getInstance() {
        if (instance == null) {
            instance = new AccountTriggerHandler();
        }
        return instance;
    }

    public String getProfileName() { //NOSONAR
        if (profileName == null) {
            profileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId()].get(0).Name;
        }
        return profileName;
    }

  /*
  * Entran t0d0s los AbacoIds, repetidos o no, si viene el campo
  * auxiliar SAL_AbacoIdNull__c = '--null--' el abacoId es null.
  */
    public void asignarAbacoIdNull(List<Account> lstAccount) {
        if (!userSettings.CIB_Is_Desktop__c) {
            for (Account acc : lstAccount) {
                if (acc.SAL_AbacoIdNull__c == NULO) {
                    acc.SER_Abaco_ID__c = null; //NOSONAR
                    acc.SAL_AbacoIdNull__c = '';
                }
            }
        }
    }

    public void assignRecordType(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        Boolean flag;
        Boolean isSystemDataloader = profileName == Label.DES_DATALOADER_PROFILE;
        Map<String,String> CNAEMapping= getCNAEMAP();

        for (Account acc : triggerNew) {

            acc.DES_Activity__c= (acc.SER_CNAE__c!='' && acc.SER_CNAE__c != null)? CNAEMapping.get(acc.SER_CNAE__c): acc.DES_Activity__c;
            acc.DES_BBVA_Segmentation__c = acc.DES_BBVA_Segmentation__c == Label.DES_Segmentation_E_BEC ? Label.DES_Segmentation_B_BEC : acc.DES_BBVA_Segmentation__c; // Como no se acepta un label duplicado, se cambia el label E_BEC por B_BEC
            if (acc.DES_Provisioning_Method__c != null && acc.DES_Provisioning_Method__c != 'ADA') {
                KSAG_Migration_Mapping.applyMappings(acc, 'Account'); // Aplica mapeos de campos durante la migración, cuando los datos no provienen del nuevo modelo (ADA)
            }
            //No actualiza de ser un prospect
            flag = isProspect(acc);

            //KSAG: se comenta esta parte dado que a priori, no se utiliza el campo DES_Data_Origin_Intranet__c
            // Si no viene de la carga de dataloader pero es un registro de la parte antigua (parte de Sales y Service)

            //    } else if (Trigger.isUpdate) {
            //         acc.DES_BBVA_Segmentation__c = oldAccounts.get(acc.Id).DES_BBVA_Segmentation__c;
            //         acc.DES_Structure_Type__c = oldAccounts.get(acc.Id).DES_Structure_Type__c;
            //     }
            // } else
            if (!flag) {
               // SI SOLO SE INSERTA 1 CLIENTE Y NO TIENE NI EL CAMPO DES_Structure_Type__c NI EL DES_BBVA_Segmentation__c RELLENOS, SE PONE AUTOMATICAMENTE BEC GROUP
                if (Trigger.isInsert && triggerNew.size() == 1 && acc.DES_BBVA_Segmentation__c == null && acc.DES_Structure_Type__c == null && !isSystemDataloader) {
                    if (acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_NEW_NO_CLIENT).getRecordTypeId()) {
                        acc.DES_Structure_Type__c = Label.DES_STR_TYPE_NO_CLIENT;
                    } else {
                        acc.DES_Structure_Type__c = acc.DES_Entity_Type__c != null ? acc.DES_Entity_Type__c : Label.DES_STR_TYPE_Subsidiary;
                        acc.DES_BBVA_Segmentation__c = Label.DES_Segmentation_B_BEC;
                    }
                }

                // Para la carga masiva via PT_CIB, Profile= Desktop Integration, Datio y ADA
                if (acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.ONB_RT_NEWCLIENT).getRecordTypeId()){
                    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.ONB_RT_NEWCLIENT).getRecordTypeId();
                } else if (acc.DES_BBVA_Segmentation__c != null && acc.DES_Structure_Type__c != null &&
                ! (acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.ONB_RT_NEWCLIENT).getRecordTypeId()) &&
                ! (acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_SALES_COUNTERPART).getRecordTypeId() && isSystemDataloader)) {
                        acc.RecordTypeId = setRecordType(acc);
                }
            }
            if (!flag && acc.DES_Provisioning_Method__c != null && acc.DES_Provisioning_Method__c.contains('ALTAMIRA')) {
                 if (Trigger.isInsert && !(acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_SALES_COUNTERPART).getRecordTypeId())) {
                    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_SALES_COUNTERPART).getRecordTypeId();
                 }
            }
        }
    }

    private Boolean isProspect(Account acc) { //NOSONAR
        Boolean result = false;

        if (((Trigger.isUpdate && (acc.DES_Provisioning_Method__c != 'Datio' || acc.DES_Provisioning_Method__c != 'ADA')) || Trigger.isInsert) &&
            acc.RecordTypeId != null && (
                acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId() ||
                acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId()
            )) {
            result = true;
            acc.Website = acc.Website_Prospect__c;
            acc.gf_cust_orig_prospect_ind_type__c = true;
            acc.DES_BBVA_Segmentation__c = acc.CIB_Commercial_Prospect__c == Label.DES_Segmentation_CIB ? Label.DES_Segmentation_C_CIB : Label.DES_Segmentation_B_BEC;
            acc.DES_Structure_Type__c = acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId() ? Label.DES_RT_Subsidiary : Label.DES_RT_Group;
        } else if (Trigger.isUpdate && (acc.DES_Provisioning_Method__c == 'Datio' || acc.DES_Provisioning_Method__c == 'ADA') &&
                   acc.old_participant_id__c == null && acc.RecordTypeId != null && acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId()) {
            acc.old_participant_id__c = acc.participant_id__c;
        }

        return result;
    }

  /*
  * Method for show error when prospect has same id fiscal on account
  */
    public void checkErrorProspect(List<Account> lAcc, Map<Id, Account> oldAccounts) { //NOSONAR
        final Map<String, Account> mAccountCheck = new Map<String, Account>();

        for (Account acc : lAcc) {
            if (acc.RecordTypeId != null &&
                (acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary').getRecordTypeId() ||
                acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId()) &&
                acc.DES_ID_Fiscal__c != oldAccounts.get(acc.Id).DES_ID_Fiscal__c &&
                acc.DES_ID_Fiscal__c != null) {

                mAccountCheck.put(acc.DES_ID_Fiscal__c, acc);
            }
        }

        if (!mAccountCheck.isEmpty()) {
            isIDFiscalProspect(mAccountCheck);
        }
    }

    private static void isIDFiscalProspect(Map<String, Account> mAcc) {
        //query solo con account
        final List<Account> lAccount = [
            SELECT Id, Name, DES_ID_Fiscal__c
            FROM Account
            WHERE DES_ID_Fiscal__c = :mAcc.keySet()
        ];

        for (Account acc : lAccount) {
            String error = Label.Error_Duplicate_ID_Fiscal
                .replace('%%name%%', '"' + acc.Name + '"')
                .replace('%%id_fiscal%%', '"' + acc.DES_ID_Fiscal__c + '"');
            mAcc.get(acc.DES_ID_Fiscal__c).addError(error);
        }
    }

    public void setRevenueUpdateEngloba(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        if (userSettings.CIB_Is_Desktop__c) {
            for (Account acc : triggerNew) {
                if (oldAccounts.get(acc.Id).DES_Revenue_Update_Engloba__c != null &&
                    oldAccounts.get(acc.Id).DES_Revenue_Update_Engloba__c != acc.DES_Revenue_Update_Engloba__c) {acc.DES_Previous_Revenue_Update_Engloba__c = oldAccounts.get(acc.Id).DES_Revenue_Update_Engloba__c;
                } else {
                    acc.DES_Previous_Revenue_Update_Engloba__c = acc.DES_Revenue_Update_Engloba__c;
                }

                if (oldAccounts.get(acc.Id).DES_RAR_EVA_RORC_Update_Engloba__c != null &&
                    oldAccounts.get(acc.Id).DES_RAR_EVA_RORC_Update_Engloba__c != acc.DES_RAR_EVA_RORC_Update_Engloba__c) {
                    acc.DES_Previous_RAR_EVA_RORC_Update_Engloba__c = oldAccounts.get(acc.Id).DES_RAR_EVA_RORC_Update_Engloba__c;
                } else {
                    acc.DES_Previous_RAR_EVA_RORC_Update_Engloba__c = acc.DES_RAR_EVA_RORC_Update_Engloba__c;
                }
            }
        }
    }

    public void setRevenueInsertEngloba(List<Account> triggerNew) {
        if (userSettings.CIB_Is_Desktop__c) {
            for (Account acc : triggerNew) {
                acc.DES_Previous_Revenue_Update_Engloba__c = acc.DES_Revenue_Update_Engloba__c;
                acc.DES_Previous_RAR_EVA_RORC_Update_Engloba__c = acc.DES_RAR_EVA_RORC_Update_Engloba__c;
            }
        }
    }
    public void updateACGlobalBanker(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        if (!System.isFuture() && !System.isBatch()) {
            futureUpdateACGlobalBanker(JSON.serialize(triggerNew),JSON.serialize(oldAccounts) );
        }
    }

        // Función que actualiza el Global Banker del account planning cuando se actualiza el Global Banker de la cuenta
    @future
    private static void futureUpdateACGlobalBanker(String listNew, String oldAccounts) {
        final List<Account> triggerNew = (List<Account>) JSON.deserialize(listNew, List<Account>.class);
        final Map<Id, Account> oldMap = (Map<Id, Account>) JSON.deserialize(oldAccounts, Map<Id, Account>.class);

        final List<Id> ids = new List<Id>();
        for (Account acc : triggerNew) {
            Account oldAccount = oldMap.get(acc.Id);
            if (oldAccount.DES_Global_Banker_Ref__c != acc.DES_Global_Banker_Ref__c) {
                ids.add(acc.Id);
            }
        }

        List<Account> updatedAccounts = [
            SELECT Id, DES_Global_Banker_Ref__r.DES_User__c
            FROM Account
            WHERE Id IN :ids
        ];

        Map<Id, Id> accountToUserMap = new Map<Id, Id>();
        for (Account acc : updatedAccounts) {
            accountToUserMap.put(acc.Id, acc.DES_Global_Banker_Ref__r.DES_User__c);
        }

        List<acpl__Account_Planning__c> accPlanList = [
            SELECT Id,
                  acpl__proposal_manager_id__c,
                  acpl__participant_id__c,
                  acpl__gf_ap_status_type_name__c,
                  acpl__gf_ap_indvi_lock_edit_ind_type__c
            FROM acpl__Account_Planning__c
            WHERE acpl__participant_id__c IN :ids
        ];

        List<acpl__Account_Planning__c> accountPlansToUpdate = new List<acpl__Account_Planning__c>();
        for (acpl__Account_Planning__c accPlan : accPlanList) {
            if (accountToUserMap.containsKey(accPlan.acpl__participant_id__c) && accPlan.acpl__gf_ap_status_type_name__c == Label.DES_IN_PROGRESS && accPlan.acpl__gf_ap_indvi_lock_edit_ind_type__c == true) {
                accPlan.acpl__proposal_manager_id__c = accountToUserMap.get(accPlan.acpl__participant_id__c);
                accountPlansToUpdate.add(accPlan);
            }
        }

        if (!accountPlansToUpdate.isEmpty()) {
            update accountPlansToUpdate;
        }
    }


    public void updateAbacoIdNull(Map<Id, Account> mapAccounts) {
        if (!userSettings.CIB_Is_Desktop__c) {
            for (String idAccount : mapAccounts.keySet()) {
                if (mapAccounts.get(idAccount).SAL_AbacoIdNull__c == NULO) {
                    mapAccounts.get(idAccount).SER_Abaco_ID__c = null; //NOSONAR
                    mapAccounts.get(idAccount).SAL_AbacoIdNull__c = '';
                }
            }
        }
    }

    // Determines the appropriate RecordTypeId for a given Account based on segmentation and structure.
    // Returns the Id of the selected Record Type.
    private static Id setRecordType(Account acc) {
        Id recordType;

        // Case 1: LOCAL segmentation
        if (acc.DES_BBVA_Segmentation__c == Label.DES_Segmentation_L_Local) {
            // Subcase: If the structure is a Subsidiary, assign Local Subsidiary record type
            if (acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Subsidiary) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_ARCE_LOCAL_SUBSIDIARY).getRecordTypeId();
            } else {
                // Otherwise, assign Local Group record type
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_ARCE_LOCAL_GROUP).getRecordTypeId();
            }

        // Case 2: NBC segmentation
        } else if (acc.DES_BBVA_Segmentation__c == Label.DES_Segmentation_NBC) {
            // Assign NBC client record type
            recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_CLIENT_NBC).getRecordTypeId();

        // Case 3: RecordType is NEW COMMERCIAL CLIENT or NIF
        } else if (
            acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get(Label.DES_RT_NAME_NEW_COMMERCIAL_CLIENT).getRecordTypeId() ||
            acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_STR_TYPE_NIF).getRecordTypeId()
        ) {
            // Subcase: If entity is Subsidiary, assign Subsidiary Commercial Client record type
            if (acc.DES_Entity_Type__c == Label.DES_STR_TYPE_Subsidiary) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary_Commercial_Client).getRecordTypeId();
            }
            
            // Default: Assign BEC Manually Group record type
            else {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName()
                    .get(Label.DES_RT_BEC_Manually_Group).getRecordTypeId();
            }

        // Case 4: Already has BEC Manually Group record type — keep it
        } else if (
            acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_BEC_Manually_Group).getRecordTypeId()
        ) {
            recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_BEC_Manually_Group).getRecordTypeId();

        // Case 5: BEC segmentation
        } else if (acc.DES_BBVA_Segmentation__c == Label.DES_Segmentation_B_BEC) {
            // Subcase: If structure type is a group type or already commercial client, assign Commercial Client record type
            if (
                acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Supragroup || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Group || acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Subgroup ||
                acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Shared_Manag_Group || (acc.RecordType != null && acc.RecordType.Name == Label.DES_RT_NAME_COMMERCIAL_CLIENT)
            ) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_NAME_COMMERCIAL_CLIENT).getRecordTypeId();
            } else {
                // Otherwise, assume Subsidiary Commercial Client
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary_Commercial_Client).getRecordTypeId();
            }

        // Case 6: CIB segmentation
        } else if (acc.DES_BBVA_Segmentation__c == Label.DES_Segmentation_C_CIB) {
            // Match the structure type to the corresponding record type
            if (acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Supragroup) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Supragroup).getRecordTypeId();
            } else if (acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Group) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Group).getRecordTypeId();
            } else if (acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Subgroup) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subgroup).getRecordTypeId();
            } else if (acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Shared_Manag_Group) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Shared_Management_Group).getRecordTypeId();
            } else if (acc.DES_Structure_Type__c == Label.DES_STR_TYPE_Subsidiary) {
                recordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.DES_RT_Subsidiary_Commercial_Client).getRecordTypeId();
            }
        }
        return recordType;
    }


    public void ponerParentIdNull(Map<Id, Account> newAccounts, Map<Id, Account> oldAccounts) {
        if (!userSettings.CIB_Is_Desktop__c) {
            for (String idAccount : newAccounts.keySet()) {
                if (newAccounts.get(idAccount).SAL_LGT_ParentId_Null__c == NULO) {
                    newAccounts.get(idAccount).ParentId = null; //NOSONAR
                    newAccounts.get(idAccount).SAL_LGT_ParentId_Null__c = '';
                }
            }
        }
    }

    /**
     * @description Delegates prospect ID generation and remote service callout to ProspectService.
     *              Sets gf_customer_prospect_id__c on newly inserted Prospect accounts
     *              and enqueues the async callout job via DES_ProspectCreateQueueable.
     * @param newAccounts Trigger.newMap from the after-insert Account trigger context.
     */
    public void generateProspectId(Map<Id, Account> newAccounts) {
        DES_ProspectService.generateProspectId(newAccounts);
    }

    /**
     * @description Delegates Global Banker AccountTeamMember management to ProspectService.
     *              On insert: creates an AccountTeamMember with the Global Banker role when
     *              DES_Global_Banker_Ref__c is populated on a Prospect account.
     *              On update: creates, replaces, or deletes the AccountTeamMember record
     *              depending on whether the Global Banker was assigned, changed, or removed.
     * @param triggerNew   List of Account records from Trigger.new.
     * @param oldAccounts  Map from Trigger.oldMap, or null on insert.
     */
    public void assignAccountTeamMember(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        DES_ProspectService.assignAccountTeamMember(triggerNew, oldAccounts);
    }

    /**
     * @description Delegates Prospect Subsidiary to Prospect Group relationship creation.
     * @param triggerNew List of Account records from Trigger.new (after insert).
     */
    public void createProspectAccountRelationship(List<Account> triggerNew) {
        DES_ProspectService.createProspectAccountRelationship(triggerNew);
    }

    /**
     * @description Delegates Prospect Subsidiary country inheritance from parent account to ProspectService.
     * @param triggerNew List of Account records from Trigger.new (before insert).
     */
    public void populateProspectSubsidiaryCountryFromParent(List<Account> triggerNew) {
        DES_ProspectService.populateProspectSubsidiaryCountryFromParent(triggerNew);
    }

    /**
     * @description Delegates Prospect Subsidiary g_customer_id__c generation using country-entific prefix to ProspectService.
     * @param triggerNew  List of Account records from Trigger.new.
     * @param oldAccounts Map from Trigger.oldMap, or null on insert.
     */
    public void applyProspectCountryEntificPrefix(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        DES_ProspectService.applyProspectCountryEntificPrefix(triggerNew, oldAccounts);
    }

    /*
* _____________________________________________________________________________
* @Description Method para generar identificador a nivel prospect
* _____________________________________________________________________________
* @Author Antonio Lozano pedroantonio.lozano@bbva.com
* @Date   2025-09-03
* @param  newAccounts: lista de cuentas
* @return null
* @example newAccounts
* _____________________________________________________________________________
**/
    public  void generateIdProspectGroup(List<Account> newAccounts) {
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group').getRecordTypeId();
        List<Account> prospectGroups = new List<Account>();
        Integer countGroup = 0;
        Integer countSubsidiary = 0;
        Account refAccount = new Account();
        for (Account acc : newAccounts) {
            if ((acc.RecordTypeId == groupRtId && String.isBlank(acc.des_group_code__c))) {
                prospectGroups.add(acc);
            }
        }
        if (!prospectGroups.isEmpty()) {
            List <Account> lastProspectGroup = new List<Account>();
            lastProspectGroup = [SELECT Id, des_group_code__c FROM Account WHERE RecordTypeId = :groupRtId AND des_group_code__c LIKE 'GP%' ORDER BY des_group_code__c DESC LIMIT 1];
            if (!lastProspectGroup.isEmpty()) {
                refAccount = lastProspectGroup.get(0);
                countGroup = Integer.valueOf(refAccount.des_group_code__c.replaceAll('[^0-9]',''));
            }
            for (Account accPG : prospectGroups) {
                countGroup++;
                accPG.des_group_code__c = 'GP' + String.valueOf(countGroup).leftPad(13, '0');
            }
        }
    }

        public Map<String,String> getCNAEMAP(){
        Map<String,String> CNAEMapping= new Map<String,String>();

        List<ONB_CNAE__mdt> metadataList = [
        SELECT CNAE_Code__c, DES_Acitvity_Code__c
        FROM ONB_CNAE__mdt  ];

        // Llenamos el mapa iterando sobre los resultados de la consulta
        for (ONB_CNAE__mdt meta : metadataList) {
            // Put(Clave, Valor)
            CNAEMapping.put(meta.CNAE_Code__c, meta.DES_Acitvity_Code__c);
        }
        return CNAEMapping;
    }

    /**
     * _______________________________________________________________________________________
     * @description Delegates after-insert HPG notification for newly created Prospect Groups
     *              to DES_DMT_ProspectUtils. Only fires for Prospect Group accounts
     *              with DES_Group_Code__c populated.
     * _______________________________________________________________________________________
     * @param newAccounts  Trigger.new from the after-insert Account trigger context.
     * _______________________________________________________________________________________
     */
    public void callCreateProspect(List<Account> newAccounts) {
        DES_DMT_ProspectUtils.callCreateProspect(newAccounts);
    }
	
    /**
     * __________________________________________________________________________________________________________
     * @description Delegates Prospect Group and Prospect Subsidiary HPG sync logic to DES_DMT_ProspectUtils.
     *              Skipped when DES_Prospect_Status_Funnel__c = 'Identify'.
     *              - POST (DES_PostCreateProspect) if not yet synced to HPG (DES_Prospect_Sync_HPG__c = false).
     *              - PUT  (DES_PutEditProspect)    if already synced and Name, DES_Country_Client__c,
     *                DES_Main_Parent__c or g_golden_customer_id__c have changed.
     * __________________________________________________________________________________________________________
     * @param newAccounts  Trigger.new from the after-update Account trigger context.
     * @param oldAccounts  Trigger.oldMap from the after-update Account trigger context.
     * __________________________________________________________________________________________________________
     */
    public void callCreateEditProspect(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        DES_DMT_ProspectUtils.callCreateEditProspect(newAccounts, oldAccounts);
    }

    public void saveInactiveDate(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        System.debug('Entro');
        if (Trigger.isBefore && Trigger.isUpdate) {

            for (Account acc : triggerNew) {

                Account oldAcc = oldAccounts.get(acc.Id);

                // Activo -> Inactivo
                if (oldAcc.gf_prtcpt_act_status_ind_type__c == true && acc.gf_prtcpt_act_status_ind_type__c == false) {
                    acc.DES_Date_Inactivity__c = Date.today();
                }

                // Inactivo -> Activo
                if (oldAcc.gf_prtcpt_act_status_ind_type__c == false && acc.gf_prtcpt_act_status_ind_type__c == true) {
                    acc.DES_Date_Inactivity__c = null;
                    acc.DES_Visible__c = true;
                }
            }
        }
    }

    //Proceso para calcular la visibilidad de las cuentas que se llama una vez finalizado la carga de usuarios diaria.
    public static void recalculateVisibility(List<Account> accs) {
        DES_Visibility_Configuration__mdt config = getVisibilityConfiguration();
        Set<Id> ignoredRecordTypes = buildIgnoredRecordTypeSet(config);

        for (Account acc : accs) {
            if (acc.gf_prtcpt_act_status_ind_type__c == false) {
                // Si el RecordType está exento, siempre visible
                Boolean isIgnoredRecordType = ignoredRecordTypes.contains(acc.RecordTypeId);

                // Lógica de días de visibilidad (configurable vía metadatos)
                Boolean dateOk = config != null &&
                    acc.DES_Date_Inactivity__c != null &&
                    acc.DES_Date_Inactivity__c.addDays((Integer) config.DES_Visibility_Days__c) > Date.today();

                acc.DES_Visible__c = isIgnoredRecordType || dateOk;
            }
        }
    }

    private static DES_Visibility_Configuration__mdt getVisibilityConfiguration() {
        List<DES_Visibility_Configuration__mdt> configs = [
            SELECT DES_Visibility_Days__c, DES_Ignored_Record_Types__c
            FROM DES_Visibility_Configuration__mdt
            LIMIT 1
        ];
        
        if (!configs.isEmpty()) {
            return configs.get(0);
        }
        return null;
    }

    private static Set<Id> buildIgnoredRecordTypeSet(DES_Visibility_Configuration__mdt config) {
        Set<Id> ignoredRecordTypes = new Set<Id>();
        
        if (config == null || String.isBlank(config.DES_Ignored_Record_Types__c)) {
            return ignoredRecordTypes;
        }
        
        List<String> recordTypeNames = config.DES_Ignored_Record_Types__c.split(',');
        for (String rtName : recordTypeNames) {
            String trimmedName = rtName.trim();
            if (String.isNotBlank(trimmedName)) {
                Id rtId = getRecordTypeId(trimmedName);
                if (rtId != null) {
                    ignoredRecordTypes.add(rtId);
                }
            }
        }
        
        return ignoredRecordTypes;
    }

    private static Id getRecordTypeId(String developerName) {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
    }

    /**
    * _____________________________________________________________________________
    * @Description Method to auto-populate Industry, Sector and Subsector fields
    *              based on DES_Activity__c value using DES_Activity_Automation__mdt
    * _____________________________________________________________________________
    * @Author Jose Carlos Ortiz
    * @Date   2026-05-04
    * @param  triggerNew: list of Account records
    * @param  oldAccounts: map of old Account records (for update context)
    * @return null
    * _____________________________________________________________________________
    **/
    public void autoPopulateIndustrySectorSubsector(List<Account> triggerNew, Map<Id, Account> oldAccounts) {
        Map<String, Schema.RecordTypeInfo> rtInfos = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Set<Id> allowedRtIds = new Set<Id>{
            rtInfos.get('DES_Prospect_Desktop').getRecordTypeId(),
            rtInfos.get('Prospect_Group').getRecordTypeId(),
            rtInfos.get('DES_Prospect_Group_Desktop').getRecordTypeId(),
            rtInfos.get('Prospect_Subsidiary').getRecordTypeId()
        };

        Set<String> activityValues = new Set<String>();
        
        // Collect activity values that are present and changed (or on insert)
        for (Account acc : triggerNew) {
            if (!allowedRtIds.contains(acc.RecordTypeId)) {
                continue;
            }
            if (String.isNotBlank(acc.DES_Activity__c)) {
                if (oldAccounts == null || acc.DES_Activity__c != oldAccounts.get(acc.Id).DES_Activity__c) {
                    activityValues.add(acc.DES_Activity__c);
                }
            }
        }
        
        if (activityValues.isEmpty()) {
            return;
        }
        
        // Chunking parameters
        Integer CHUNK_SIZE = 200; // safe chunk size to avoid SOQL IN limits and large binds
        
        // Accumulate maps from all chunks
        Map<String, DES_Activity_Industry_Automation__mdt> industryMap = new Map<String, DES_Activity_Industry_Automation__mdt>();
        Map<String, DES_Activity_Sector_Automation__mdt> sectorMap = new Map<String, DES_Activity_Sector_Automation__mdt>();
        Map<String, DES_Activity_Subsector_Automation__mdt> subsectorMap = new Map<String, DES_Activity_Subsector_Automation__mdt>();
        
        List<String> activitiesList = new List<String>();
        activitiesList.addAll(activityValues);
        
        for (Integer i = 0; i < activitiesList.size(); i += CHUNK_SIZE) {
            Integer chunkEnd = Math.min(i + CHUNK_SIZE, activitiesList.size());
            List<String> chunk = new List<String>();
            for (Integer j = i; j < chunkEnd; j++) {
                chunk.add(activitiesList[j]);
            }
            
            // Query industry metadata for this chunk
            for (DES_Activity_Industry_Automation__mdt md : [
                SELECT ActivityValue__c, IndustryValue__c
                FROM DES_Activity_Industry_Automation__mdt
                WHERE ActivityValue__c IN :chunk
            ]) {
                if (md != null && String.isNotBlank(md.ActivityValue__c)) {
                    industryMap.put(md.ActivityValue__c, md);
                }
            }
            
            // Query sector metadata for this chunk
            for (DES_Activity_Sector_Automation__mdt md : [
                SELECT ActivityValue__c, SectorValue__c
                FROM DES_Activity_Sector_Automation__mdt
                WHERE ActivityValue__c IN :chunk
            ]) {
                if (md != null && String.isNotBlank(md.ActivityValue__c)) {
                    sectorMap.put(md.ActivityValue__c, md);
                }
            }
            
            // Query subsector metadata for this chunk
            for (DES_Activity_Subsector_Automation__mdt md : [
                SELECT ActivityValue__c, SubsectorValue__c
                FROM DES_Activity_Subsector_Automation__mdt
                WHERE ActivityValue__c IN :chunk
            ]) {
                if (md != null && 
                    String.isNotBlank(md.ActivityValue__c)) {
                    subsectorMap.put(md.ActivityValue__c, md);
                }
            }
        }
        
        // Populate Account fields using the corresponding metadata when present and non-empty.
        for (Account acc : triggerNew) {
            if (!allowedRtIds.contains(acc.RecordTypeId)) {
                continue;
            }
            if (String.isNotBlank(acc.DES_Activity__c)) {
                if (oldAccounts == null || 
                    acc.DES_Activity__c != oldAccounts.get(acc.Id).DES_Activity__c) {
                    String activity = acc.DES_Activity__c;
                    
                    // Industry: if metadata exists use value, otherwise set blank
                    DES_Activity_Industry_Automation__mdt indMd = industryMap.get(activity);
                    if (indMd != null && 
                        String.isNotBlank(indMd.IndustryValue__c)) {
                        acc.Industry = indMd.IndustryValue__c;
                    } else {
                        acc.Industry = '';
                    }
                    
                    // Sector: keep previous behavior (only set when metadata exists)
                    DES_Activity_Sector_Automation__mdt secMd = sectorMap.get(activity);
                    if (secMd != null && 
                        String.isNotBlank(secMd.SectorValue__c)) {
                        acc.DES_AGGR_Sector__c = secMd.SectorValue__c;
                    }
                    
                    // Subsector: keep previous behavior (only set when metadata exists)
                    DES_Activity_Subsector_Automation__mdt subMd = subsectorMap.get(activity);
                    if (subMd != null &&
                        String.isNotBlank(subMd.SubsectorValue__c)) {
                        acc.Subsector__c = subMd.SubsectorValue__c;
                    }
                }
            }
        }
    }
  }