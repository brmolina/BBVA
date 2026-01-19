/****
*   @author: GlobalDesktop - APC
*   @Class: CreateContactFormController
*   @Description:
*   @Versions:
        v1 - 2019/02/XX - Initial version
**/
public with sharing class CreateContactFormController {

	/* pattern */
	private static CreateContactFormController instance;

	/*
    * @author Global Desktop
    * Description: constructor
    */
	private CreateContactFormController() {
		system.debug('Constructor CreateContactFormController');
	}

	/**
	* @author Global Desktop
	* @description Singleton pattern
	*/
    public static CreateContactFormController getInstance() { //NOSONAR
        if (instance == null) {
            instance = new CreateContactFormController();
        }
        return instance;
    }

    /*
    * @author Global Desktop
    * Description: handleInitValues
    */
    @AuraEnabled
    public static WrResponse handleInitValues(String idAccount) {
    	try {
            System.debug(':::::handleInitValues INIT:::');

            final Boolean isGMProfile = isGMProfile();

            String idAcc;
            if(idAccount == null) {
                idAcc = null;
            } else {
                idAcc = getDefaultAccount(idAccount);
            }

            final WrResponse response = new WrResponse(idAcc, isGMprofile);
            return response;
        } catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }

     /*
    * @author Global Desktop
    * Description: getDefaultAccount
    */
    private static String getDefaultAccount(String idAccount) {
        String idAcc;
        if(idAccount == null) {
            idAcc = null;
        } else {
            final String sQuery =  'SELECT Id FROM Account WHERE Id = :idAccount ';
            final List<Account> lstAccount = Database.query(sQuery);
            System.debug('::::result query: ' + lstAccount);

            idAcc = lstAccount.isEmpty() ? null : lstAccount[0].Id;
        }
        return idAcc;
    }
     /*
    * @author Global Desktop
    * Description: isGMProfile == BBVA Desktop GM Click To Dial and the old Sales Profiles
    */
    private static Boolean isGMProfile() {
        // Id profileId= userinfo.getProfileId();
        Boolean isGMProfile;
        final List<String> lstProfilesGM = new List<String> {'BBVA Desktop GM Click To Dial', 'Sales Corporates',
                                                'Sales Internal Networks','Sales Cash Equity', 'Sales Equity Derivatives',
                                                'Sales Flow FI & FX', 	'Sales Structured FI Investors', 'Sales Business Line Cash Equity',
                                                'Sales Business Line Corporates', 'Sales Business Line Equity Derivatives',
                                                'Sales Business Line Flow FI & FX', 'Sales Business Line Internal Networks',
                                                'Sales Business Line Structured FI Investors'
                                                };
        final List<Profile> lstProfiles = [Select Id from Profile where name IN :lstProfilesGM];
        System.debug(':::::lstProfiles:::' + lstProfiles);
        if(!lstProfiles.isEmpty()) {
            isGMProfile = checkProfile(lstProfiles);
        } else {
            isGMProfile = false;
        }
        System.debug(':::::isGMProfile:::' + isGMProfile);
        return isGMProfile;
    }
    /*
    * @author Global Desktop
    * Description: checkProfile
    */
    private static Boolean checkProfile(List<Profile> lstProfiles) {
        final Id profileId= userinfo.getProfileId();
        Boolean isGMProfile;
        isGMProfile = false;
        for(Profile profile : lstProfiles) {
            if(profile.Id == profileId) {
                isGMProfile = true;
                break;
            }
        }
        return isGMProfile;
    }
    /*
    * @author Global Desktop
    * Description: getContactData
    */
    @AuraEnabled
    public static WrapperContact getContactData(String idContact) {
    	try {
	        Contact con;
	        final String sQuery =  'SELECT FirstName, LastName, Email_ExternalID__c, OwnerId, Phone, MobilePhone FROM Contact WHERE Id = :idContact ';
	        final List<Contact> lstContacts = Database.query(sQuery);
	        System.debug('::::result query: ' + lstContacts);
	        if(lstContacts.isEmpty()) {
	            con = new Contact();
	        } else {
	            con = lstContacts[0];
	        }
            final Boolean editable = getWritable(con);

	        // return con;
            WrapperContact resp = new WrapperContact(con, editable);
            return resp;
        } catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
    }

    /*
    * @author Global Desktop
    * Description: createContact
    */
    @AuraEnabled
    public static WrResponse createContact(String attributes, String dmlOption, String oldContact) {
        WrResponse response; //NOSONAR
        try {
            final Contact newContact = (Contact)JSON.deserialize(attributes, Contact.class);
            System.debug(':::newContact : ' + newContact);

            Database.SaveResult result;
            if(dmlOption == Label.DES_INSERT) {
                result = NewContactDML.createContact(newContact);//with sharing to be able to change the owner
            } else if(dmlOption == Label.DES_UPDATE) {
                result = UpdateContactDML.updateContact(newContact, oldContact);//without sharing with programmatic share to be able to change the owner
            }
            System.debug(':::database result:: ' + result);
            if(result != null && result.isSuccess()) {
                System.debug(':::::result.isSuccess true');
                final Contact conBDD = [SELECT name FROM Contact WHERE id =: result.getId()];
                response = new WrResponse(true, 'ok', 'Registro actualizado', result.getId(), conBDD.Name);
            } else {
                // response = new WrResponse(false, 'errorResult', JSON.serialize(result.getErrors()), null, null);
                final String error = fixDisplayErrors(JSON.serialize(result.getErrors()));
                System.debug(':::::error' +JSON.serialize(result.getErrors() ));
                response = new WrResponse(false, 'ErrorResult', error, null, null);
            }
        } catch(DMLException exc) {
            System.debug('::::DMLException: ' + exc.getMessage());
            final String error = fixDisplayErrors(exc.getMessage());
            response = new WrResponse(false, 'DML', error, null, null);
            if(error.contains('duplicate value found')) {
                response = getDuplicateRow(error);
            }
        }
        System.debug(':::response de server a client:: ' + JSON.serialize(response));
        return response;
    }

    /*
    * @author Global Desktop
    * Description: currentDomain
    */
    @AuraEnabled
	public static String currentDomain() {
		try {
			String stringReturn;
			System.debug('::::URL.getOrgDomainURL().toExternalForm() : ' + URL.getOrgDomainURL().toExternalForm());
			if(URL.getOrgDomainURL().toExternalForm().contains('.cs')) {
				stringReturn = URL.getOrgDomainURL().toExternalForm().split('.cs')[0];
			} else {
				stringReturn = URL.getOrgDomainURL().toExternalForm().split('.my')[0];
			}
			return stringReturn;
		} catch(Exception exc) {
			throw new AuraHandledException(Label.DES_Error + exc);
		}
	}
    /*
    * @author Global Desktop
    * Description: getWritable: checks wheter the
    */
    private static Boolean getWritable(Contact contact) {
        Boolean isWritable=false;

        final Id userId = UserInfo.getUserId();
        final List<GroupMember> contactGroup = [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Edit_Permissions_Desktop_ContactsGroup'];
        //final boolean ownerIsActive =[SELECT Id,owner.isActive from Contact WHERE Id =: contact.Id].owner.isActive;
        final boolean ownerIsActive;
        if(contact.id!=null){
            ownerIsActive =[SELECT Id,owner.isActive from Contact WHERE Id =: contact.Id].owner.isActive;}
        final Id automaticLoad =[SELECT Id FROM User WHERE Name='Automatic Load' ].Id;
        //isWritable = false;
        if(contact.id != null && (userId == contact.ownerId ||contact.ownerId==automaticLoad || !ownerIsActive)) {
            isWritable = true;
        }else {
            for(GroupMember gMember : contactGroup) {
                if(gMember.UserOrGroupId == userId) {
                    isWritable = true;
                    break;
                }
            }
        }
        return isWritable;
    }

    /*
    * @author Global Desktop
    * Description: fixDisplayErrors
    */
    private static String fixDisplayErrors(String cadena) { //NOSONAR
        String fixed;
        fixed = cadena;

        if(fixed.contains('_EXCEPTION')) {
            fixed = fixed.replaceAll('([A-z.\\s:;0-9\\_"]*_EXCEPTION,\\s)(.*?\\.)(\\:.*)' , '$2');
        }
        if(fixed.contains('_VALUE')) {
            fixed = fixed.replaceAll('([A-z.\\s:;0-9"},]*_VALUE,\\s)(.*[0-9A-z]{15})(.*)' , '$2');
        }
        // Se comenta ya que al ocultarse el owner no es necesaria la comprobación
        /*if(fixed.contains('_REFERENCE_KEY, Owner')) {
            fixed = 'The owner cannot be blank.';
        }*/
        if(fixed.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Phone or Email')) {
            fixed = 'Phone or Email must be completed.';
        }
        if(fixed.contains('DUPLICATE_VALUE, This contact already has a relationship with this client.')) {
            fixed = ' This contact already has a relationship with this client.';
        }
        if(fixed.contains('You do not have permissions to edit the current contact')) {
            fixed = 'You do not have permissions to edit the current contact.';
        }
        if(fixed.contains('Scope field must be fulfilled')) {
            fixed = 'Scope field must be fulfilled.';
        }
        if(fixed.contains('The contact name can not be edited here, please click on "Edit" button')) {
            fixed = 'The contact name can not be edited here, please click on "Edit" button.';
        }
        System.debug(':::string a sustituir: ' + cadena);
        System.debug(':::string fixed : ' + fixed);
        return fixed;
    }

    /*
    * @author Global Desktop
    * Description: getDuplicateRow
    */
    private static WrResponse getDuplicateRow(String error) {
        // String idDuplicated = error.replaceAll('' , '');
        final String idDuplicated = error.substring(error.length() - 18);
        System.debug(':::idDuplicated ' + idDuplicated);
        WrResponse response;
        final String errDuplicated = 'Duplicado';
        String errDescription = '';
        errDescription = 'It seems that the contact already exists in Global Desktop (duplicated email): ';
        if (idDuplicated.containsWhitespace()) {
            errDescription += 'There was a problem retrieving the duplicate contact data';
            response = new WrResponse(false, errDuplicated, errDescription, null, null, null, null, null, null, null);
        } else {
            final Contact con = [SELECT Id, Name, OwnerId, Owner.Name, Owner.Department, AccountId, Account.Name FROM Contact WHERE Id = :idDuplicated];
            System.debug(':::con duplicado ' + con);
            response = new WrResponse(false, errDuplicated, errDescription, con.Id, con.Name, con.AccountId, con.Account.Name, con.OwnerId, con.Owner.Name, con.Owner.Department);
        }
        return response;
    }


    /*
    * @author Global Desktop
    * Description: WrResponse
    */
    public class WrResponse {
    	/* get & set */
        @AuraEnabled
        public Boolean success { get;set; }
        /* get & set */
        @AuraEnabled
        public String type { get;set; }
        /* get & set */
        @AuraEnabled
        public String bodyText { get;set; }
        /* get & set */
        @AuraEnabled
        public Id rowId { get;set; }
        /* get & set */
        @AuraEnabled
        public String rowName { get;set; }
        /* get & set */
        @AuraEnabled
        public Id accId { get;set; }
        /* get & set */
        @AuraEnabled
        public String accName { get;set; }
        /* get & set */
        @AuraEnabled
        public Id ownId { get;set; }
        /* get & set */
        @AuraEnabled
        public String ownName { get;set; }
        /* get & set */
        @AuraEnabled
        public String ownDepartment { get;set; }
        /* get & set */
        @AuraEnabled
        public Boolean isGMProfile { get;set; }

        /* Constructor */
        public WrResponse(Boolean isSuccess, String type, String body, Id fileId, String name) {
            this.success = isSuccess;
            this.type = type;
            this.bodyText = body;
            this.rowId = fileId;
            this.rowName = name;
        }

        /* Constructor */
        public WrResponse(Boolean isSuccess, String type, String body, Id fileId, String name, Id accId, String accName, Id ownerId, String ownerName, String ownerDep) {
            this.success = isSuccess;
            this.type = type;
            this.bodyText = body;
            this.rowId = fileId;
            this.rowName = name;
            this.accId = accId;
            this.accName = accName;
            this.ownId = ownerId;
            this.ownName = ownerName;
            this.ownDepartment = ownerDep;
        }

        /* Constructor */
        public WrResponse(String accId, Boolean isGM) {
            this.accId = accId;
            this.isGMProfile = isGM;
        }
    }
    /*
    * @author Global Desktop
    * Description: WrResponse
    */
    public class WrapperContact {
    	/* get & set */
        @AuraEnabled
        public Contact contact { get;set; }
        /* get & set */
        @AuraEnabled
        public Boolean canEdit { get;set; }

        /* Constructor */
        public WrapperContact(Contact con, Boolean editable) {
            this.contact = con;
            this.canEdit = editable;
        }
    }

}