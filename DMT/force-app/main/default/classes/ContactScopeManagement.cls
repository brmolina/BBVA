/*****************************************************
*   @Class: contactScopeManagement
*   @Description: management of initial and automatic population of Contact.DES_Scope__c field when a Contact is created
					or when there is any new AccountContactRelation for that Contact


*   @Versions:
        v1 - 2019/01/23 - Initial version good
************************************************************************************************************************/
public without sharing class ContactScopeManagement {
    /*Declarando variable*/
    private final static String STRING_S = 'S';

    /*SINGLETON PATTERN*/
    private static ContactScopeManagement instance;
    /*SINGLETON PATTERN*/
    public static ContactScopeManagement getInstance() { //NOSONAR
        if (instance == null) {
            instance = new ContactScopeManagement();
        }
        return instance;
    }


    /*CONSTRUCTOR (PRIVATE -> SINGLETON PATTERN) */
    private ContactScopeManagement() {
    }
    /********************************************************************************************************************************
    *   @author: GlobalDesktop - APC
    *   @Method: manageContactScope
    *   @Description: management of populatingScope() depending on when it is called: before insert or after update
                        Used:
                            - (Deprecated - v1) Contact -> before insert (NOT YET)
                            - AccountContactRelation -> after update -> update Contacts

    *   @Params: lstContacts< Contact >
    *   @Params: Boolean isAfter -> to specify whether the list must be updated (currently it comes from AccountContactRelationTrigger)

    *   @Versions:
            v1 - 2019/01/23 - Initial version, only called from AccountContactRelationTrigger
    *******************************************************************************************************************************/
    public static void manageContactScope (List<AccountContactRelation> lstACR ) {
        System.debug(':::::Desktop_Utils.manageContactScope() init ');
        final List<Contact> lstContactFixed = populatingScope(lstACR); //IsCreatedByHierarchy__c false

        if(!lstContactFixed.isEmpty()) {
            System.debug(':::::reemplaza lista: ' + JSON.serialize(lstContactFixed));
            update lstContactFixed;
        }
    }
    /*****************************************************************************************************************************
    *   @author: GlobalDesktop - APC
    *   @Method: populatingScope
    *   @Description:
                        Populates Contact.DES_Scope__c field based on the DES_Country_Client__c field of the related accounts

                        Uses getRelatedCountries() which at the same time uses fixScope() to accomplish the following logic:

                        1) Contacts filtered by recordType Desktop Contact
                        2) Check the accounts related to that contact

                        3) Use Cases:
                            a) Subsidiary AND MATRIX
                                a1) countryMatrix == countryGroup -> DES_Scope__c = Global
                                a2) else -> DES_Scope__c = countryMatrix
                            b) Subsidiary AND NO MATRIX -> DES_Scope__c = acc.country
                            c) GROUP -> DES_Scope__c = Global

                        Notes:
                            External ID: Email_ExternalID__c
                            DES_Entity_Hierarchy__c S/N -> S = Matrix;
                            Account.DES_Structure_Type__c = Group / Subsidiary
                            DES_Main_Parent__c -> account Group

    *   @Params: newList< Contact >
    *   @Returns: List< Contact > with DES_Scope__c populated
    *   @Versions:
            v1 - 2019/01/23 - Initial version
    ***************************************************************************************************************************/
    private static List<Contact> populatingScope (List<AccountContactRelation> newListACR ) {
        System.debug(':::::Desktop_Utils.populatingScope() init ');
        final List<Contact> lstNewContacts = new List<Contact>();

        if(!newListACR.isEmpty()) {
            final Id rtDesktopContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Desktop Contact').getRecordTypeId(); //api Desktop_Contact
            final Set<Id> setAcrNewsId = new Set<Id>();

            for(AccountContactRelation acr : newListACR) {
                setAcrNewsId.add(acr.Id);
            }

            final List<AccountContactRelation> lstACRextended = [SELECT Id, AccountId, ContactId,
                                                                        Contact.DES_Scope__c,
	                                                                    Account.DES_Entity_Hierarchy__c,
	                                                                    Account.DES_Structure_Type__c,
	                                                                    Account.DES_Country_Client__c,
	                                                                    Account.DES_Main_Parent__c,
	                                                                    Account.DES_Main_Parent__r.DES_Country_Client__c,
	                                                                    Account.DES_Main_Parent__r.DES_Client_Matrix__r.DES_Country_Client__c,
	                                                                    Account.RecordType.Name,
                                                                        IsDirect
	                                                                     FROM AccountContactRelation
	                                                                     WHERE Id IN :setAcrNewsId
                                                                             AND record_created_hierarchy_type__c = false
                                                                             AND Contact.RecordTypeId = :rtDesktopContact
	                                                                     ];
            System.debug(':::::lstACRextended ' + JSON.serialize(lstACRextended));

            for(AccountContactRelation acr : lstACRextended) {
                Contact con;
                con = checkAccount4Contact(acr);
                con.editable_field_type__c = true;
                if(con.DES_Scope__c == null) {
                    System.debug('registro no actualiza scope -> no actualiza registro');
                } else if(con.DES_Scope__c == Label.DES_Error) {
                    System.debug('error');
                    con.addError(Label.AccountErrorBatch );
                } else {
                    lstNewContacts.add(con);
                }
            }
        }
        System.debug(':::::lstNewContacts to be returned: ' + lstNewContacts);
        return lstNewContacts;
    }
    /*******************************************************************************************************************************
    *   @author: GlobalDesktop - APC
    *   @Method: checkAccount4Contact
    *   @Description: check use cases especified in previous method (fixScope())

    *   @Params: Account acc
    *   @Params: Account contacto
    *   @Returns Contact with DES_Scope__c populated with the basic (1) value

    *   @Versions:
            v1 - 2019/01/23 - Initial version: It is public because there is an initial batch which call it (Batch_ContactScope)
            v2 - 2019/02/04 - When a contact is new and associated with Matrix or Group and it is populated with any value, it won´t be managed
            v3 - 2019/02/12 - Boolean addValue -> to check whether the row must be updated or not
    *******************************************************************************************************************************/
    private static Contact checkAccount4Contact (AccountContactRelation acr) {//, Contact contacto) {
        final Contact cont = new Contact();
        cont.Id = acr.ContactId;

		return checkAccType(acr, cont);
    }

    /**
    * @uthor Global Desktop
    * @description Method auxiliar para comprobar el tipo de cuenta
        16/05/2019 modificada la lógica, ahora entran en juego además de los grupos (rt grupo y Commercial Client),
         los supragrupos, subgrupos y grupos de gestión compartida
    */
    private static Contact checkAccType(AccountContactRelation acr, Contact cont) {
        final String scopeInicial = acr.Contact.DES_Scope__c;
    	String scopeFinal;
    	Boolean addValue;

        if(checkRTName(acr.Account.RecordType.Name)) {
            scopeFinal = 'Global';
            addValue = scopeInicial == null ? true : false;
        } else if (acr.Account.DES_Entity_Hierarchy__c == STRING_S) {
            final String pGrupo = acr.Account.DES_Main_Parent__r.DES_Country_Client__c;
            final String pMatrix = acr.Account.DES_Main_Parent__r.DES_Client_Matrix__r.DES_Country_Client__c; // informado sólo a nivel de "Grupo"

            scopeFinal = getScopeMatrix(scopeInicial, pGrupo, pMatrix, acr.IsDirect);
            addValue = pMatrix == pGrupo && acr.IsDirect == false ? false : true;
        } else {
            final String pDirectAcc = acr.Account.DES_Country_Client__c;

            scopeFinal = pDirectAcc;
            addValue = true;
        }

        return modifyCont(cont, scopeInicial, scopeFinal, addValue);
    }
    /**
    * @uthor Global Desktop
    * @description validates the recordTypeName
    * @Input RecordTypeName
    * @Output Boolean (true when rtn IN Grupo{2},Supragrupo,Subgrupo,G.Gestión Compartida)
    */
    private static Boolean checkRTName(String rtn) {
        return rtn == Label.DES_RT_NAME_COMMERCIAL_CLIENT || rtn == Label.DES_STR_TYPE_Group || rtn == Label.DES_RT_Supragroup || rtn == Label.DES_RT_Subgroup || rtn == Label.DES_STR_TYPE_Shared_Manag_Group ? true : false;
    }
    /**
    * @uthor Global Desktop
    * @description getScopeMatrix
    * @Input RecordTypeName
    * @Output String with the wished scope
    */
    private static String getScopeMatrix(String scopeInicial, String pGrupo, String pMatrix, Boolean isAcrDirect) {
        String scopeFinal;
        scopeFinal = pMatrix == pGrupo  && isAcrDirect == true ? Label.DES_SCOPE_GLOBAL : pMatrix;
        return scopeFinal = scopeInicial == null ? scopeFinal : scopeInicial;
    }
    /**
    * @uthor Global Desktop
    * @description Method auxiliar para modificar el contacto
    */
    private static Contact modifyCont(Contact cont, String scopeInicial, String scopeFinal2, Boolean addValue) {
    	String scopeFinal;
        scopeFinal = scopeFinal2;
    	if(scopeInicial != null && scopeInicial != '' && scopeInicial != scopeFinal) {
            //--Corrección incidencia MAXMIX4-2903
            if(scopeFinal == null) {
                scopeFinal = scopeInicial;
            } else {
                scopeFinal += ';' + scopeInicial;
            }
            //--Final Corrección incidencia MAXMIX4-2903
        }
    	if(addValue == true) {
            scopeFinal = Desktop_Utils.checkDuplicateString(scopeFinal, ';');
            System.debug('::::scopeFinal good: ' + scopeFinal);
            cont.DES_Scope__c = scopeFinal;
        } else {
            cont.DES_Scope__c = Label.DES_Error; // -> wont be updated in the previous method
        }
        return cont;
    }

}