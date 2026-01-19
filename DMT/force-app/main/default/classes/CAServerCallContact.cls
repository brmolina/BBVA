global with sharing class CAServerCallContact {
    public List<Contact> contactListFound {get;set;}
    public List<Account> accountListFound {get;set;}
    public List<Lead> leadListFound {get;set;}
    
    public String phoneNumber {get;set;} 

    
    // ---------------
    //Constructor
    // ---------------    
    public CAServerCallContact() {
        this.phoneNumber = apexpages.currentpage().getparameters().get('phone'); 
    }

    // ---------------  
    //public Methods
    // ---------------    

    //Realiza una búsqueda para encontrar contactos, prospetc o cliente que coincidan con el número de teléfono.    
    public void doFindPhoneNumber() {               
        String phoneno = '%' + this.phoneNumber;        
        
        /* Se comenta la query SOSL porque no se pueden utilizar wildcards al inicio de la cadena buscada, es decir no se puede buscar "*phoneNumber" por ejemplo:
            - si un contacto tiene almacenzado el teléfono con prefijo: "34666666666", si se busca en la SOSL "*666666666" no devuelve ningún resultado
        La razón está documentada en Salesforce: Asterisks match zero or more characters at the middle or end (not the beginning) of your search term.
        List<List<SObject>> searchList = [FIND :phoneno IN PHONE FIELDS RETURNING 
                                            Account (Id, Name,Client_Star_ID__c,Parent_Account_Name__c,Phone,Asset_class__c,Ariadna_Group__c,Ariadna_Group_Code__c,Ariadna_Group_Description__c), 
                                            Contact(Id,Name,AccountId,Phone,MobilePhone,OtherPhone,Internal_Extension__c,Email,Asset_class__c), 
                                            Lead(Id,Name,Company,Asset_Class__c,Phone,MobilePhone)];
                                            
        La única solución es utilizar 3 queries SOQL, una por cada tabla donde se busca.
        */

        this.accountListFound = [Select Id, Name,Client_Star_ID__c,Parent_Account_Name__c,Phone,Asset_class__c,Ariadna_Group__c,Ariadna_Group_Code__c,Ariadna_Group_Description__c, YTD_Total_Franchise__c from Account WHERE Phone like :phoneno order by YTD_Total_Franchise__c desc];
        this.contactListFound = [Select Id,Name,AccountId,Account.Name,Phone,MobilePhone,OtherPhone,Internal_Extension__c,Email,Asset_class__c from Contact WHERE Internal_Extension__c like :phoneno OR Phone like :phoneno OR HomePhone like :phoneno OR MobilePhone like :phoneno OR OtherPhone like :phoneno order by Account.YTD_Total_Franchise__c desc];        
        this.leadListFound = [Select Id,Name,Company,Asset_Class__c,Phone,MobilePhone from Lead WHERE Phone like :phoneno OR MobilePhone like :phoneno];
    }


    //Obtiene la url de Salesforce
    @RemoteAction
    global static String getUrl() {
        String finalUrl = URL.getOrgDomainURL().toExternalForm();
        return finalUrl;

    }


    //Crea un objeto del tipo “ContactDetails”, rellenando sus respectivos campos con los del objeto cuyo número de teléfono haya coincidencias.      
    @RemoteAction
    global static ContactDetails getContactName(String phoneNum) {
        ContactDetails contactDetails = new ContactDetails ();
        contactDetails.contactName = 'No';
        contactDetails.clientName = 'No';
        contactDetails.id = 'No';
        contactDetails.clientCode = 'No';
        contactDetails.numRecords = 0;
        
        if (!String.isBlank(phoneNum)){
            String phoneno = '%' + phoneNum;
            
            // Búsqueda en Contact
            List<Contact> contactList = [Select Id, Name, Account.Name, Account.Client_STAR_ID__c from Contact WHERE Internal_Extension__c like :phoneno OR Phone like :phoneno OR HomePhone like :phoneno OR MobilePhone like :phoneno OR OtherPhone like :phoneno order by Account.YTD_Total_Franchise__c desc];
            if(!contactList.isEmpty()) {
                contactDetails.contactName = contactList.get(0).Name;
                contactDetails.clientName = contactList.get(0).Account.Name;
                contactDetails.clientCode = contactList.get(0).Account.Client_STAR_ID__c;
                contactDetails.id = contactList.get(0).Id;
                contactDetails.numRecords = contactList.size();
            }else{
                // Búsqueda en Account
                List<Account> accountList = [Select Id, Name, Client_STAR_ID__c from Account WHERE Phone like :phoneno order by YTD_Total_Franchise__c desc];
                if(!accountList.isEmpty()) {
                    contactDetails.contactName = '';
                    contactDetails.clientName = accountList.get(0).Name;
                    contactDetails.clientCode = accountList.get(0).Client_STAR_ID__c;
                    contactDetails.id = accountList.get(0).Id;
                    contactDetails.numRecords = accountList.size();                    
                }else {             
                    // Búsqueda en Lead
                    List<Lead> leadList = [Select Id, Name, Company from Lead WHERE Phone like :phoneno OR MobilePhone like :phoneno];
                    if(!leadList.isEmpty()) {
                        contactDetails.contactName = leadList.get(0).Name;
                        contactDetails.clientName = leadList.get(0).Company;
                        contactDetails.id = leadList.get(0).Id;
                        contactDetails.numRecords = leadList.size();    
                    }
                }
            }
        }               
        
        return contactDetails;              
    }

            //List<Lead> listProspect = [SELECT Id FROM Lead WHERE Name like :'Prospect Pending Data%'];

        //Integer numberProspect = listProspect.size()+1;

        //Lead prospect = new Lead(LastName = 'Prospect Pending Data '+numberProspect,
        //                         Status = 'Open',
        //                         Phone = phoneClient,
        //                         Asset_Class__c = 'FI',
        //                         Company = 'Data Company',
        //                         Email = 'DataEmail@email.com');

        //insert prospect;

        //return prospect;

    //Se consulta si hay algún prospect, Client, Contact que contenga el número de teléfono. Si no se encuentran coincidencias, se crea un contacto dummy.
    @RemoteAction
    global static Contact createContact(String phoneContact){
        String phoneno = '';

        if(phoneContact.length() == 10){
            phoneno = '%' + phoneContact.substring(1, phoneContact.length());
        }else if(phoneContact.length() == 11){
            phoneno = '%' + phoneContact.substring(2, phoneContact.length());
        }else if(phoneContact.length() == 12 || phoneContact.startsWith('376')){
            phoneno = '%' + phoneContact.substring(3, phoneContact.length());
        }else if(phoneContact.length() == 13){
            phoneno = '%' + phoneContact.substring(4, phoneContact.length());     
        }else if(phoneContact.length() == 14){
            phoneno = '%' + phoneContact.substring(5, phoneContact.length());     
        }else{
            phoneno = '%' + phoneContact;
        }

        System.debug('Numero a buscar con like: '+phoneno);


        List<Account> accountList;
        List<Contact> contactList;
        List<Lead> leadList;

        if(phoneContact.length() <= 7){
            accountList = [Select Id, Name from Account WHERE Phone = :phoneContact];
            contactList = [Select Id, Name from Contact WHERE Internal_Extension__c = :phoneContact OR Phone = :phoneContact OR HomePhone = :phoneContact OR MobilePhone = :phoneContact OR OtherPhone = :phoneContact];        
            leadList = [Select Id, Name from Lead WHERE Phone = :phoneContact OR MobilePhone = :phoneContact];
        }else{
            accountList = [Select Id, Name from Account WHERE Phone like :phoneno];
            contactList = [Select Id, Name from Contact WHERE Internal_Extension__c like :phoneno OR Phone like :phoneno OR HomePhone like :phoneno OR MobilePhone like :phoneno OR OtherPhone like :phoneno];        
            leadList = [Select Id, Name from Lead WHERE Phone like :phoneno OR MobilePhone like :phoneno];
        }

        System.debug('Contact: '+ contactList.size());

        if(accountList.size() == 0 && contactList.size() == 0 && leadList.size() == 0){


        List<Account> listAccount = [SELECT Id FROM Account WHERE Name = 'Account Pending Data' limit 1];
        Account account;

        System.debug('size: '+listAccount.size());

        if(listAccount.size() == 0){
            System.debug('Cuenta nueva');
            Id stardRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Account').getRecordTypeId();
            Integer RandomNumber = Math.round(Math.random()*1000);
            account = new Account(
                Name = 'Account Pending Data',
                Type = 'Corporate',
                Sector__c = 'Asset Management',        
                BBVA_Entity__c = 'BBVA SA',
                Asset_Class__c = 'FI;FX;Cash Equity',
                Last_Trade_Date_Cash_Equity__c = date.today(),
                Last_Trade_Date_FI__c = date.today(),
                Last_Trade_Date_FX__c = date.today(),
                MTD_Total_Franchise__c = 12345,
                RecordTypeId = stardRecordType,
                Client_STAR_ID__c = '123456789' + RandomNumber            
            );    

            insert account;        
        }


         Contact contact = new Contact(
            Lastname = 'Contact Pending Data '+phoneContact,
            Email_ExternalID__c = 'ContactPending'+phoneContact+'Data@dummy.com',
            Asset_Class__c = 'FI;FX;Cash Equity',
            Phone = phoneContact
        ); 

         if(listAccount.size() == 0){
            contact.AccountId = account.Id;
         }else{
            contact.AccountId = listAccount[0].Id;
         }


         insert contact;

         System.debug('Insertamos contacto');
         return contact;


        }
      
        return null;


    }
    
    //Se consulta si hay algún prospect, Client, Contact que contenga el número de teléfono. Si encuentra coincidencias, las devuelve   
    @RemoteAction
    global static ContactDetails getRecordByPhoneNumber(String phoneNum) {        
        ContactDetails contactDetails = new ContactDetails ();
        String phoneno = '%' + phoneNum;

        List<Account> accountList;
        List<Contact> contactList;
        List<Lead> leadList;

        if(phoneNum.length() <= 7){              
            accountList = [Select Id, Name from Account WHERE Phone = :phoneNum];
            contactList = [Select Id, Name from Contact WHERE Internal_Extension__c = :phoneNum OR Phone = :phoneNum OR HomePhone = :phoneNum OR MobilePhone = :phoneNum OR OtherPhone = :phoneNum];        
            leadList = [Select Id, Name from Lead WHERE Phone = :phoneNum OR MobilePhone = :phoneNum];
         }else{
            accountList = [Select Id, Name from Account WHERE Phone like :phoneno];
            contactList = [Select Id, Name from Contact WHERE Internal_Extension__c like :phoneno OR Phone like :phoneno OR HomePhone like :phoneno OR MobilePhone like :phoneno OR OtherPhone like :phoneno];        
            leadList = [Select Id, Name from Lead WHERE Phone like :phoneno OR MobilePhone like :phoneno];
        }
        
        contactDetails.numRecords = contactList.size() + accountList.size() + leadList.size(); 
        
        if (contactDetails.numRecords == 1){         
            if (accountList.size() == 1){
                contactDetails.Id = accountList.get(0).Id;
                contactDetails.contactName = accountList.get(0).Name;
            }else if(contactList.size() == 1){
                contactDetails.Id = contactList.get(0).Id;
                contactDetails.contactName = contactList.get(0).Name;
            }else{
                contactDetails.Id = leadList.get(0).Id;
                contactDetails.contactName = leadList.get(0).Name;
            }            
        }
                
        return contactDetails; 
    }  

    //@RemoteAction
    //global static ContactDetails getRecordByPhoneNumber(String phoneNum) {        
    //    ContactDetails contactDetails = new ContactDetails ();
    //    //String phoneno = '%' + phoneNum;
                
    //    List<Account> accountList = [Select Id, Name from Account WHERE Phone = :phoneNum];
    //    List<Contact> contactList = [Select Id, Name from Contact WHERE Internal_Extension__c = :phoneNum OR Phone = :phoneNum OR HomePhone = :phoneNum OR MobilePhone = :phoneNum OR OtherPhone = :phoneNum];        
    //    List<Lead> leadList = [Select Id, Name from Lead WHERE Phone = :phoneNum OR MobilePhone = :phoneNum];
        
    //    contactDetails.numRecords = contactList.size() + accountList.size() + leadList.size(); 
        
    //    if (contactDetails.numRecords == 1){         
    //        if (accountList.size() == 1){
    //            contactDetails.id = accountList.get(0).Id;
    //            contactDetails.contactName = accountList.get(0).Name;
    //        }else if(contactList.size() == 1){
    //            contactDetails.id = contactList.get(0).Id;
    //            contactDetails.contactName = contactList.get(0).Name;
    //        }else{
    //            contactDetails.id = leadList.get(0).Id;
    //            contactDetails.contactName = leadList.get(0).Name;
    //        }            
    //    }
                
    //    return contactDetails; 
    //}     


    //@RemoteAction
    //global static Boolean Click_Button(Id caseId){
        
    //    // Your business logic
        
    //    return true;
    //}
    
    // ---------------
    // Classes
    // ---------------
    // Definición de la Wrapper Class de la respuesta
    global class ContactDetails{
        public String contactName {get;set;}
        public String clientName {get;set;}
        public String clientCode {get;set;}
        public String id {get;set;}
        public Integer numRecords {get;set;}       

    }
}