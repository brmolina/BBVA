/**
* @author GlobalDesktop
*/
public with sharing
class DES_IpFormController { //NOSONAR
  /**
   * Miembros por página dentro de la lista de ExternalInsidersPage
   */
  private static final Integer EXT_INSDRS_PER_PG = 4;
  /**
   * Compliance Profile Name
   */
  private static final String CMPLNC_PRFL = 'BBVA Desktop Compliance';

  /**
   * SINGLETON PATTERN
   */
  private static DES_IpFormController instanceForm;


  /**
   * getInstance
   */
  public static DES_IpFormController instance() {
    if (instanceForm == null) {
      instanceForm = new DES_IpFormController();
    }
    return instanceForm;
  }

  /**
   * Devuelve el codigo bbva del usuario que invoca el method
   */
  @AuraEnabled
  public static String bbvaUserCode() {
    String bbvaUserCode;
    try {
		bbvaUserCode = Desktop_Utils.bbvaUserCode(); //NOSONAR
    } catch (Exception e) {
		if(Test.isRunningTest()) { //NOSONAR
		  	bbvaUserCode = 'test1234';
		} else {
			throw new AuraHandledException(Label.DES_IP_ERROR + e);
      	}
    }
    return bbvaUserCode;
  }

  /**
   * Devuelve fields de un objeto
   */
  @AuraEnabled
  public static String getObjectType(String objeto) {
    try {
      // Passing the sObject name in the method, it could be multiple objects too
      return Desktop_Utils.getDescribedObjects( new List<String>{objeto} );
    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }



  /**
   * Devuelve el endpoint de los servicios
   */
  @AuraEnabled
  public static String urlIpServices() {
    try {
      return Desktop_Utils.urlIPServices();
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }

  }

  /**
   * Devuelve un mapa con las preguntas del formulario de compliance
   */
  @AuraEnabled
  public static Map<String, String> complianceQuestions() {
    try {
      return Desktop_Utils.complianceQuestions();
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }

  

  /**
   * method for update records after inline editing
   */
  @AuraEnabled
  public static Inside_information_form__c saveFormulario(Inside_information_form__c form) {
    try {
      System.debug('-------> saveFormulario: ' + form);
      update form;
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
    return form;
  }
    
    /**
   * method for update records after inline editing
   */
  @AuraEnabled
  public static Id getOppId(id formId) {
    try {
            final List <Inside_information_form__c> lstOfFormularios = [select opportunity_id__c from Inside_information_form__c WHERE Id=:formId ];
            Inside_information_form__c form;
            form = new Inside_information_form__c();
            if(!lstOfFormularios.isEmpty()) {
                form = lstOfFormularios.get(0);
            }
          return form.opportunity_id__c;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
  }


  /**
   * Method to retrieve Insiders information and return it in the wrapper class
   */
  @AuraEnabled
  public static IpSFData getIpSalesforceData(Id formId) {
    try {
          // variable que se devuelve
         final IpSFData ipfd = new IpSFData();

        //Datos de los External participants
         final List <Compliance_form_contact__c> insidersList = new List<Compliance_form_contact__c>([
             SELECT id, RecordTypeId, employee_department_name__c, operation_user_assign_date__c, person_name__c, personal_id__c, birth_date__c,
             operation_user_reason_acc_type__c, role_name__c, participant_name__c, participant_address_struct_desc__c,
             town_name__c, zipcode_id__c, country_id__c, phone_id__c, cell_phone_number_id__c, person_address_struct_desc__c, address_town_name__c, 
             commerce_zipcode_id__c, address_country_id__c, phone1_id__c, cell_phone_number1_id__c, non_disclosure_agree_ind_type__c
             FROM Compliance_form_contact__c
             WHERE Formulario__r.Id  = :formId
             ORDER BY CreatedDate ASC]);
      

         final String bbvaContactRT = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Form).getRecordTypeId();
         final String extContactRT = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Form).getRecordTypeId();
         final String bbvaContactReadRT = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_BBVA_Contact_Read_Form).getRecordTypeId();
         final String extContactReadRT = Schema.SObjectType.Compliance_form_contact__c.getRecordTypeInfosByName().get(Label.DES_RT_External_Contact_Read_Form).getRecordTypeId();


         final List<Compliance_form_contact__c> extInsiders = new List<Compliance_form_contact__c>();
         
         //Separamos en dos listas en funcion del recordtype del insider
         for (Compliance_form_contact__c insider : insidersList) {
           if (insider.RecordTypeId == bbvaContactRT || insider.RecordTypeId == bbvaContactReadRT) {
             ipfd.bbvaInsiders.add(insider);
           }
		   if (insider.RecordTypeId == extContactRT || insider.RecordTypeId == extContactReadRT) {
             extInsiders.add(insider);
           }
         }
         ipfd.extInsidersPages = setExternalInsidersPageList(extInsiders);

        //Datos para llamadas a Web Services
        //ipfd.idOppIP = getOppId(formId); 
        ipfd.endPoint = Desktop_Utils.urlIPServices();
        if(!Test.isRunningTest()) { //NOSONAR
          ipfd.codBbvaUser = Desktop_Utils.bbvaUserCode();
        }
		    ipfd.formCountrys = getCountryLabel(formId);
         //Datos de complianceQuestions
        ipfd.questions = complianceQuestions();
        
      return ipfd;

    } catch(Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  }


  /**
   * Devuelve el record type para las picklist
   */
  @AuraEnabled
  public static String getRecordTypeId(String rtName) {
    try {
      return Schema.SObjectType.Inside_information_form__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
    } catch (Exception e) {
      throw new AuraHandledException(Label.DES_IP_ERROR + e);
    }
  } 

  
  /** 
   * Inicialización de la lista de Compliance_form_contact__c y se van repartiendo 4 miembros
   * por pagina dentro de la lista de ExternalInsidersPage (contienen sublistas de 4 registros de miembros)
   */
  private static List<DES_IpFormController.ExternalInsidersPage> setExternalInsidersPageList (List<Compliance_form_contact__c> extrnlInsdrsInpt) {
    //List returned by the method
    final List<ExternalInsidersPage> listToReturn = new List<DES_IpFormController.ExternalInsidersPage>();
    
    //variable auxiliar para ir añadiendo a la lista de pages listToReturn
    ExternalInsidersPage currentPage = new DES_IpFormController.ExternalInsidersPage();
    currentPage.pageNumber = 1;
    Integer auxNextPage;

    //Recorremos la lista de Compliance_form_contact__c y se van repartiendo 4 miembros por pagina dentro
    //de la lista de ExternalInsidersPage (contienen sublistas de 4 registros de miembros)
    for ( Compliance_form_contact__c cfc : extrnlInsdrsInpt) {
      if (currentPage.externalInsiders.size() == EXT_INSDRS_PER_PG) {
        auxNextPage = currentPage.pageNumber + 1; 
        listToReturn.add(currentPage); // añadimos la pagina actual (que ya tiene los 4 externalInsiders) a la lista de páginas
        currentPage = new DES_IpFormController.ExternalInsidersPage(); // creamos una nueva página
        currentPage.pageNumber = auxNextPage;  //avanzamos +1 en la pagina
      }
      // añadimos el externalInsider a la página actual
      currentPage.externalInsiders.add(cfc);
    }
    //se añade la última pagina con la lista de extInsiders. En caso de lista en blanco al imprimir el PDF seguirá apareciendo la página aunque esté vacía
    listToReturn.add(currentPage);

    //En la última página añadimos elementos necesarios hasta llegar al número EXTERNAL_INSIDERS_PER_PAGE
    Final Integer nRcrdsLastPg = listToReturn.get(listToReturn.size() - 1).externalInsiders.size();
    if (nRcrdsLastPg < EXT_INSDRS_PER_PG) {
      for (Integer num = nRcrdsLastPg; num <= EXT_INSDRS_PER_PG; num++) {
        final Compliance_form_contact__c auxExtInsider = new Compliance_form_contact__c();
        listToReturn.get(listToReturn.size() - 1).externalInsiders.add(auxExtInsider);
      }
    }

    return listToReturn;
  }
    



 /**
	 * Description:     WrapperClass que se devuelve al componente lightning que crea el HTML y después exporta el PDF
  **/
    public class IpSFData {
        /**
         * List of Compliance_form_contact__c
         */
        @AuraEnabled
        public List<Compliance_form_contact__c> bbvaInsiders; //NOSONAR
        /**
         * List of ExternalInsidersPage
         */
        @AuraEnabled
        public List<ExternalInsidersPage> extInsidersPages; //NOSONAR
        /**
         * Variable to save Desktop_Utils.urlIPServices
         */
        @AuraEnabled
        public string endPoint; //NOSONAR
        /**
         * Variable to save Desktop_Utils.bbvaUserCode
         */
        @AuraEnabled
        public string codBbvaUser; //NOSONAR
        /**
         * Country of the form
         */		
        @AuraEnabled
        public string formCountrys; //NOSONAR
        /**
         * Opportunity of the form
         */        
        @AuraEnabled
        public string idOppIP; //NOSONAR
        /**
         * Variable to save Desktop_Utils.complianceQuestions
         */
        @AuraEnabled
        public Map<String, String>  questions; //NOSONAR
        /**
         * Constructor
         */        
        public IpSFData() {
          this.bbvaInsiders = new List<Compliance_form_contact__c>();
          this.extInsidersPages = new List<ExternalInsidersPage>();
        }

  }

  

 /**
	 * Description:     WrapperClass que envuelve la lista de externalInsiders repartiendolos por páginas
  **/
  public class ExternalInsidersPage {
    /**
     * Number of page
     */
    @AuraEnabled
    public Integer pageNumber; //NOSONAR
    /**
     * List of Compliance_form_contact__c
     */
    @AuraEnabled
    public List<Compliance_form_contact__c> externalInsiders; //NOSONAR
    /**
     * Constructor
     */    
    public ExternalInsidersPage() {
      externalInsiders = new List<Compliance_form_contact__c>();
    }
  }




  /**
   * Devuelve una lista con formularios por id
   */
    @AuraEnabled
    public static Inside_information_form__c getFormulariosById(id formId) {
        try {
            final List <Inside_information_form__c> lstOfFormularios = [select oper_afct_cust_bal_ind_type__c, oper_afct_cust_bal_desc__c, oper_manager_informed_ind_type__c, participant_name__c, prtcpt_stock_exch_ind_type__c,
            participant1_name__c, prtcpt_stock_exch_ind1_type__c, participant2_name__c, prtcpt_stock_exch_ind2_type__c, participant3_name__c, prtcpt_stock_exch_ind3_type__c, participant4_name__c,
            prtcpt_stock_exch_ind4_type__c, participant5_name__c, prtcpt_stock_exch_ind5_type__c, non_disclosure_agree_ind_type__c, non_disclosure_agree_desc__c, CurrencyIsoCode,
            cust_low_profitabilliy_desc__c, cust_low_profitabilliy_ind_type__c, operation_privileged_start_date__c, user_name__c, oper_cnmv_cmun_ind_type__c, oper_cnmv_cmun_desc__c, Name, reserved_information_desc__c,
            reserved_information_type__c, oper_info_stakeholders_desc__c, oper_info_stakeholders_ind_type__c, operation_materialized_desc__c, oper_materialized_ind_type__c, oper_prvlg_other_prtcpt_desc__c,
            oper_prvlg_stk_mkt_afct_desc__c, oper_prvlg_stk_mkt_afct_ind_type__c, operation_privileged_name__c, operation_privileged_desc__c, operation_privileged_ind_type__c, operation_strategic_desc__c,
            operation_strategic_ind_type__c, operation_viable_desc__c, operation_viable_ind_type__c, other_information_desc__c, country_id__c,toLabel(country_id__c) country_id_label, operation_cmtee_apprv_ind_type__c, operation_cmtee_apprv_desc__c, oper_afct_cust_revenue_desc__c,
            oper_afct_cust_revenue_ind_type__c, oper_stakeholder_invest_desc__c, oper_stakeholder_invest_ind_type__c, compliance_form_send_date__c, requester_info_complete_desc__c, requester_info_complete_ind_type__c, status_type__c,  
            gf_master_agreement_desc__c, gf_reason_funds_used_ind_type__c, gf_reason_funds_used_desc__c, gf_agree_more_3_per_desc__c, gf_master_agreement_type__c,  gf_agree_more_3_per_type__c
            from Inside_information_form__c WHERE Id=:formId ];
            Inside_information_form__c form;
            form = new Inside_information_form__c();
            if(!lstOfFormularios.isEmpty()) {
                form = lstOfFormularios.get(0);
            }
          return form;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
    }

  /**
   *
   * @param insideFormId : Id of an Inside Information Form
   *
   * @return an InsideFormData that wrappers the Inside Information Form and other details (see InsideFormData class)
   */
  @AuraEnabled
  public static InsideFormData getInsideFormData ( Id insideFormId ) { //NOSONAR

    final InsideFormData ifd = new InsideFormData();
    ifd.insideInformationForm = getFormulariosById( insideFormId );
    ifd.userRecordAccess = Desktop_Utils.getUserRecordAccess( insideFormId, UserInfo.getUserId() );

    if(ifd.userRecordAccess == null) {
      throw new AuraHandledException(Label.DES_IP_NotAccess);
    }

    return ifd;

  }

  /**
   * Data related to the Inside Information Form
   */
  public class InsideFormData {
    /**
     * Inside Information Form
     */
    @AuraEnabled
    public Inside_information_form__c insideInformationForm; //NOSONAR
    /**
     * Access of the current User
     */
    @AuraEnabled
    public UserRecordAccess userRecordAccess; //NOSONAR
  }



/* *********** Obsolete methods to delete ************** */

/*
    private ExternalInsider fromComplianceFormContactToExternalInsiders (Compliance_form_contact__c externalInsidersData){
      ExternalInsider extInsider = new ExternalInsider(); //NOSONAR

      
      extInsider.person_name = externalInsidersData.Name;
      extInsider.personal_id = externalInsidersData.personal_id__c;
      extInsider.birth_date = externalInsidersData.birth_date__c;
      extInsider.operation_user_reason_acc_type = externalInsidersData.operation_user_reason_acc_type__c;
      extInsider.role_name = externalInsidersData.role_name__c;

      return extInsider;
    }*/


/* Clases de Jorge
    public List<ExternalInsidersPage> transposeExternalInsiders (List<Compliance_form_contact__c> externalInsidersInput) {
	//NOSONAR
    List<ExternalInsidersPage> pages = new List<DES_IpFormController.ExternalInsidersPage>();
    ExternalInsidersPage page;
    final Integer numberColumns = 4;

    for (Integer i = 0; i < externalInsidersInput.size(); i++) {

      // Cuando rellenamos todas las columnas creamos una nueva página
      if ( Math.mod(i, numberColumns) == 0 ) {
        page = new ExternalInsidersPage();
      }

      page.person_name.add(externalInsidersInput[i].Name);
      page.personal_id.add(externalInsidersInput[i].personal_id__c);
      page.birth_date.add(externalInsidersInput[i].birth_date__c);
      page.operation_user_reason_acc_type.add(externalInsidersInput[i].operation_user_reason_acc_type__c);
      page.role_name.add(externalInsidersInput[i].role_name__c);

      if (  Math.mod(i,numberColumns) == 3 || i == externalInsidersInput.size() - 1 ) {
        pages.add(page);
      }

    }

    return pages;

  }


public class ExternalInsider {

  
    public List<String> person_name = new List<String>();
  
    public List<String> personal_id = new List<String>();
    
    public List<Date> birth_date = new List<Date>();
    
    public List<String> operation_user_reason_acc_type = new List<String>();
  
    public List<String> role_name = new List<String>();


  }


*/
    /**
     * isCompliance
     */
    @AuraEnabled
    public static Boolean isCompliance() {
        Boolean isCompliance = false;
        final Id profileId = UserInfo.getProfileId();
        final List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id = :profileId];
        try {
        	if (!profiles.isEmpty() && CMPLNC_PRFL.equalsIgnoreCase(profiles[0].Name)) {
            	isCompliance = true;
        	}
        	return isCompliance;
        } catch (Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
    }
    /**
     * country_id__c label values
     */
  @AuraEnabled
  public static String getCountryLabel(id formId) {
    try {
        String labCountry;
        final List<AggregateResult> lstOfFormularios = [select toLabel(country_id__c)countr_id_label from Inside_information_form__c WHERE Id=:formId group by country_id__c];
        for(AggregateResult labsFormas: lstOfFormularios) {
            System.debug('Campaign ID' + labsFormas.get('countr_id_label'));
            labCountry=String.valueof(labsFormas.get('countr_id_label'));
        }
        return labCountry;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
  }
    
        /**
   * method get visit id
   */
  @AuraEnabled
  public static Id getVisitId(id formId) {
   System.debug('>>>>>>>>>>> getVisitId');
      try {
            final List <Inside_information_form__c> lstOfFormularios = [select visit_id__c  from Inside_information_form__c WHERE Id=:formId ];
            Inside_information_form__c form;
            form = new Inside_information_form__c();
            if(!lstOfFormularios.isEmpty()) {
                form = lstOfFormularios.get(0);
            }
          return form.visit_id__c;
        } catch(Exception e) {
            throw new AuraHandledException(Label.DES_IP_ERROR + e);
        }
  }
}