/*
* @author Global Desktop
* @description Formulario y redireccion de oportunidades y visitas en grupo
*/
public with sharing class NewOppFormGroupsCnt {

    /*
    * supraGrupo
    */
    static final String SUPRAGRUPO = 'SupraGroup';
    /*
    * subGrupo
    */
    static final String SUBGRUPO = 'SubGroup';
    /*SINGLETON PATTERN*/
    private static NewOppFormGroupsCnt instance;
    /*Private constructor*/
    private NewOppFormGroupsCnt() {
    }
    /*SINGLETON PATTERN*/
    public static NewOppFormGroupsCnt getInstance() { //NOSONAR
        if (instance == null) {
            instance = new NewOppFormGroupsCnt();
        }
        return instance;
    }
    /*
    * @author Global Desktop
    * @description Recupera el client id deacuerdo a algunas validaciones.
    */
    public static List<String> getValidadMatrix(String clientId) {
            List<String> valClient= new List<String>();
            valClient.add(clientId);
            final Id rtGrupo      = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Group').getRecordTypeId();
            final Id rtGrupo2     = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Commercial Client').getRecordTypeId();
            System.debug('subGrupo----->'+SUBGRUPO);
            System.debug('rtGrupo----->'+rtGrupo);
            System.debug('rtGrupo2----->'+rtGrupo2);

            List<dwp_acmh__GBL_Account_Relationship__c> lstCuentaRel;
            lstCuentaRel = new List<dwp_acmh__GBL_Account_Relationship__c>();

            final List<Account> lstCuenta = [select id,recordtypeid,DES_Structure_Type__c from Account where id =:clientId];
            if(!lstCuenta.isEmpty() && lstCuenta[0].DES_Structure_Type__c==SUPRAGRUPO) {
                lstCuentaRel=[select id,dwp_acmh__Child_Account__c from dwp_acmh__GBL_Account_Relationship__c where dwp_acmh__Parent_Account__c=:clientId and (dwp_acmh__Child_Account__r.recordtypeid=:rtGrupo or dwp_acmh__Child_Account__r.recordtypeid=:rtGrupo2)];

                if(!lstCuentaRel.isEmpty()) {
                    for (dwp_acmh__GBL_Account_Relationship__c lstCuentas1 : lstCuentaRel) {
                        valClient.add(lstCuentas1.dwp_acmh__Child_Account__c);
                    }
                }
            } else if (!lstCuenta.isEmpty() && lstCuenta[0].DES_Structure_Type__c==SUBGRUPO) {
                lstCuentaRel=[select id,dwp_acmh__Parent_Account__c from dwp_acmh__GBL_Account_Relationship__c where dwp_acmh__Child_Account__c =:clientId and (dwp_acmh__Parent_Account__r.recordtypeid=:rtGrupo or dwp_acmh__Parent_Account__r.recordtypeid=:rtGrupo2 )];

                if(!lstCuentaRel.isEmpty()) {
                    for (dwp_acmh__GBL_Account_Relationship__c lstCuentas2 : lstCuentaRel) {
                        valClient.add(lstCuentas2.dwp_acmh__Child_Account__c);
                    }
                }
            }
            return valClient;
    }
    /*
    * @author Global Desktop
    * @description Recupera los paises de las filiales relacionadas al grupo.
    */
    @AuraEnabled
    public static List<String> getRelatedCountries(String clientId) {
        try {

           List<String>   varclientId=  new List<String>();
           varclientId         = NewOppFormGroupsCnt.getValidadMatrix(clientId);

           final List<AggregateResult> relatedFilial = [SELECT  participant_child_id__r.DES_Country_Client__c
                                                                FROM DES_Subsidiary_Group_Relation__c
                                                                WHERE participant_parent_id__c  IN :varclientId
                                                                GROUP BY participant_child_id__r.DES_Country_Client__c];
            final List<String> countryList = new List<String>();
            final Schema.DescribeFieldResult fieldResult = Account.DES_Country_Client__c.getDescribe();
            final List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
            final Map<String,String> mapValueLabel = new Map<String,String>();
            for( Schema.PicklistEntry v : values) {
                mapValueLabel.put(v.getValue(),v.getLabel());
            }

            for(AggregateResult gsm : relatedFilial) {
                String labelCountry;
                labelCountry = mapValueLabel.get(String.valueOf(gsm.get('DES_Country_Client__c')));
                countryList.add(labelCountry);
            }
            countryList.sort();
            return countryList;
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }


    /*
    * @author Global Desktop
    * @description Recupera las filiales relacionadas al grupo.
    */
    @AuraEnabled
    public static String getRecords(String clientId, String selectedValue) {
        try {

            List<String>   varclientId=  new List<String>();
            varclientId         = NewOppFormGroupsCnt.getValidadMatrix(clientId);

            final Map<String,String> mapContryCodes= GroupGeographyCnt.helperCreateMapCountryCodes('LABEL');
            final String countryDevName = mapContryCodes.get(selectedValue);

            final List<DES_Subsidiary_Group_Relation__c> relSubsidiaries = [SELECT Id, participant_child_id__c, participant_child_id__r.Name
                                                                            FROM DES_Subsidiary_Group_Relation__c
                                                                            WHERE participant_parent_id__c IN :varclientId
                                                                            AND participant_child_id__r.DES_Country_Client__c = :countryDevName
                                                                            AND participant_child_id__r.gf_prtcpt_act_status_ind_type__c = true];

			final List<String> orderList = new List<String>();
            for(DES_Subsidiary_Group_Relation__c gsm : relSubsidiaries) {
				String union = gsm.participant_child_id__r.Name + '&&' + gsm.participant_child_id__c;
	    		orderList.add(union);
			}
			orderList.sort();
	    	final List<WrapperClass> listWrapper = new List<WrapperClass>();
	    	for(String name : orderList) {
				String[] campos= name.split('&&');
	    		listWrapper.add(new WrapperClass(campos[0],campos[1]));
            }

            return JSON.serialize(listWrapper);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

 /*
    * @author Global Desktop
    * @description Recupera la matriz del grupo
    */
    @AuraEnabled
    public static String getRelatedMatrix(String clientId) {
        try {

            final List<Account> lstParent = [SELECT Id, DES_Client_Matrix__c,DES_Client_Matrix__r.name
                                            FROM Account
                                            WHERE id = :clientId
                                            LIMIT 1];

            final WrapperClass listWrapper = new WrapperClass();

            if(!lstParent.isEmpty() && lstParent[0].DES_Client_Matrix__c!=null) {
                listWrapper.matrixName=lstParent[0].DES_Client_Matrix__r.name;
                listWrapper.idMatrix  =lstParent[0].DES_Client_Matrix__c;
            }

            return JSON.serialize(listWrapper);
        } catch (Exception exc) {
            throw new AuraHandledException(Label.DES_Error + exc);
        }
    }

    /*
    * @author Global Desktop
    * @description construye la lista wrapper que devuelve la informacion al componente lightning
    */
    public class WrapperClass{
        //Nombre de la matrix
        private String matrixName; //NOSONAR
        //URL de la matriz
        private String idMatrix; //NOSONAR
        /**
        * @author Global Desktop
        * @description Construye la clase wrapper
        */
    	public WrapperClass(String nameIn, String idMatrixIn) {
    		this.matrixName = nameIn;
    		this.idMatrix = idMatrixIn ;
        }
        /**
        * @author Global Desktop
        * @description Construye la clase wrapper
        */
        public WrapperClass() {
        }
    }



}