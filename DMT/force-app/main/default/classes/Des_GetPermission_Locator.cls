/**
 * @description       :
 * @author            : Global Desktop
 * @group             :
 * @last modified on  : 12-01-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('sf:CyclomaticComplexity')
global with sharing class Des_GetPermission_Locator implements arce.Arc_Gen_GetPermissions_Interface {//NOSONAR

    /**
    * @Description: String with value "Group"
    */
    final static String IRP = 'IRP';
    /**
    * @Description: String with value "Group"
    */
    final static String ARP = 'ARP';
    /**
    * @Description: String with value "Group"
    */
    final static String CRP = 'CRP';
    /**
    * @description
    * @author Global Desktop | 09-12-2021
    * @param ahasId
    * @return Boolean
    **/
    public Boolean getPermissionToEdit(Id ahasId) {
        System.debug('>>>>>>> getPermissionToEdit entra');
        final Boolean resultado = Boolean.valueOf(Arc_Gen_TabSet_service.getPermissionToEdit(ahasId));
        System.debug('>>>>>>> getPermissionToEdit' + resultado);
        return resultado;
    }

    /**
    * @description
    * @author Global Desktop | 10-03-2022
    * @param ahaId
    * @return Boolean
    **/
    public Boolean irpEnabler(Id localClientId) {
        System.debug('>>>>>>> irpEnabler' + localClientId);
        Boolean irpEnable = false;
        if(localClientId.getSObjectType().getDescribe().getName() != 'Account'){
          final Local_Client__c local = getLocalClient(localClientId);
          //if(local != null){
            final User usuario = getUser();
            System.debug('>>>>>>> local.country_id__c ' + local.country_id__c);
            final Arce_ambit_hierarchy__mdt ambito = formatAmbit(usuario.gf_user_operation_ambit_name__c);
            String ambitCountry = formatAmbitCountry(usuario.gf_user_operation_ambit_name__c);
            if(ambitCountry == 'OFC' || ambitCountry == 'CIB' || ambitCountry == 'GRM'){
                irpEnable = true;
            } else if (local.crossBorder__c && ambitCountry != local.country_id__c) {
                if (ambito.FlujoCross__c != null && ambito.FlujoCross__c.containsIgnoreCase(IRP)) {
                    irpEnable = true;
                }
            } else if (ambitCountry != local.country_id__c) {
                if (ambito.FlujoGeo__c!= null && ambito.FlujoGeo__c.containsIgnoreCase(IRP)) {
                    System.debug('>>>>>>> FlujoGeo__c');
                    irpEnable = true;
                }
            } else if (ambitCountry == local.country_id__c) {
                if (ambito.Flujo__c != null && ambito.Flujo__c.containsIgnoreCase(IRP)) {
                    irpEnable = true;
                }
            }
        }else{
            irpEnable = accountIrpEnabler(localClientId);
        }

        return irpEnable;
    }

    /**
    * @description
    * @author Global Desktop | 31-08-2022
    * @param ahaId
    * @return Boolean
    **/
    public Boolean accountIrpEnabler(Id ClientId) {
        System.debug('>>>>>>> accountIrpEnabler' + ClientId);
        Boolean irpEnable = false;
        final Account account = getClient(ClientId);
        System.debug('>>>>>>> account ' + account);
        final User usuario = getUser();
        System.debug('>>>>>>> Account.DES_Country_Client__c ' + account.DES_Country_Client__c);
        final Arce_ambit_hierarchy__mdt ambito = formatAmbit(usuario.gf_user_operation_ambit_name__c);
        String ambitCountry = formatAmbitCountry(usuario.gf_user_operation_ambit_name__c);
        if(ambitCountry == 'OFC' || ambitCountry == 'CIB' || ambitCountry == 'GRM'){
            irpEnable = true;
        } else if (account.DES_Tier__c == '00000024' && ambitCountry != account.DES_Country_Client__c) { // DES_Tier__c == BEeIG-GCB
            if (ambito.FlujoCross__c != null && ambito.FlujoCross__c.containsIgnoreCase(IRP)) {
                irpEnable = true;
            }
        } else if (ambitCountry != account.DES_Country_Client__c) {
            if (ambito.FlujoGeo__c!= null && ambito.FlujoGeo__c.containsIgnoreCase(IRP)) {
                irpEnable = true;
            }
        } else if (ambitCountry == account.DES_Country_Client__c) {
            if (ambito.Flujo__c != null && ambito.Flujo__c.containsIgnoreCase(IRP)) {
                irpEnable = true;
            }
        } 

        return irpEnable;
    }

    /**
    * @description
    * @author Global Desktop | 10-03-2022
    * @param ahaId
    * @return Boolean
    **/
    public Boolean arpEnabler(Id localClientId) {
        System.debug('>>>>>>> arpEnabler');
        Boolean arpEnable = false;
        if(localClientId.getSObjectType().getDescribe().getName() != 'Account'){
          final Local_Client__c local = getLocalClient(localClientId);
            final User usuario = getUser();
            final Arce_ambit_hierarchy__mdt ambito = formatAmbit(usuario.gf_user_operation_ambit_name__c);
            String ambitCountry = formatAmbitCountry(usuario.gf_user_operation_ambit_name__c);
            if(ambitCountry == 'OFC' || ambitCountry == 'CIB' || ambitCountry == 'GRM'){
                arpEnable = true;
            }else if (local.crossBorder__c && ambitCountry != local.country_id__c) {
                if (ambito.FlujoCross__c != null && ambito.FlujoCross__c.containsIgnoreCase(ARP)) {
                    arpEnable = true;
                }
            } else if (ambitCountry != local.country_id__c) {
                if (ambito.FlujoGeo__c!= null && ambito.FlujoGeo__c.containsIgnoreCase(ARP)) {
                    System.debug('>>>>>>> FlujoGeo__c');
                    arpEnable = true;
                }
            } else if (ambitCountry == local.country_id__c){
                if (ambito.Flujo__c != null && ambito.Flujo__c.containsIgnoreCase(ARP)) {
                    System.debug('>>>>>>> Flujo__c');
                    arpEnable = true;
                }
            }
        }else{
            arpEnable = accountArpEnabler(localClientId);
        }
        return arpEnable;
    }
    
    /**
    * @description
    * @author Global Desktop | 10-03-2022
    * @param ahaId
    * @return Boolean
    **/
    public Boolean accountArpEnabler(Id ClientId) {
        System.debug('>>>>>>> accountArpEnabler');
        Boolean arpEnable = false;
        final Account account = getClient(ClientId);
        final User usuario = getUser();
        final Arce_ambit_hierarchy__mdt ambito = formatAmbit(usuario.gf_user_operation_ambit_name__c);
        String ambitCountry = formatAmbitCountry(usuario.gf_user_operation_ambit_name__c);
        if(ambitCountry == 'OFC' || ambitCountry == 'CIB' || ambitCountry == 'GRM'){
            arpEnable = true;
        }else if (account.DES_Tier__c == '00000024' && ambitCountry != account.DES_Country_Client__c) { // DES_Tier__c == BEeIG-GCB
            if (ambito.FlujoCross__c != null && ambito.FlujoCross__c.containsIgnoreCase(ARP)) {
                arpEnable = true;
            }
        } else if (ambitCountry != account.DES_Country_Client__c) {
            if (ambito.FlujoGeo__c!= null && ambito.FlujoGeo__c.containsIgnoreCase(ARP)) {
                arpEnable = true;
            }
        } else if (ambitCountry == account.DES_Country_Client__c){
            if (ambito.Flujo__c != null && ambito.Flujo__c.containsIgnoreCase(ARP)) {
                arpEnable = true;
            }
        }
        return arpEnable;
    }

    /**
    * @description
    * @author Global Desktop | 10-03-2022
    * @param ahaId
    * @return Boolean
    **/
    public Boolean crpEnabler(Id localClientId) {
        System.debug('>>>>>>> crpEnabler');
        Boolean crpEnable = false;
        if(localClientId.getSObjectType().getDescribe().getName() != 'Account'){
          final Local_Client__c local = getLocalClient(localClientId);
          //if(local != null){
            final User usuario = getUser();
            final Arce_ambit_hierarchy__mdt ambito = formatAmbit(usuario.gf_user_operation_ambit_name__c);
            String ambitCountry = formatAmbitCountry(usuario.gf_user_operation_ambit_name__c);
            if(ambitCountry == 'OFC' || ambitCountry == 'CIB' || ambitCountry == 'GRM'){
                crpEnable = true;
            }else if (local.crossBorder__c && ambitCountry != local.country_id__c) {
                if (ambito.FlujoCross__c != null && ambito.FlujoCross__c.containsIgnoreCase(CRP)) {
                    crpEnable = true;
                }
            } else if (ambitCountry != local.country_id__c) {
                if (ambito.FlujoGeo__c!= null && ambito.FlujoGeo__c.containsIgnoreCase(CRP)) {
                    System.debug('>>>>>>> FlujoGeo__c');
                    crpEnable = true;
                }
            } else  if (ambitCountry == local.country_id__c){
                if (ambito.Flujo__c != null && ambito.Flujo__c.containsIgnoreCase(CRP)) {
                    System.debug('>>>>>>> Flujo__c');
                    crpEnable = true;
                }
            }
        }else{
            crpEnable = accountCrpEnabler(localClientId);
        }

        return crpEnable;
    }

    /**
    * @description
    * @author Global Desktop | 10-03-2022
    * @param ahaId
    * @return Boolean
    **/
    public Boolean accountCrpEnabler(Id ClientId) {
        System.debug('>>>>>>> accountCrpEnabler');
        Boolean crpEnable = false;
        final Account account = getClient(ClientId);
        final User usuario = getUser();
        final Arce_ambit_hierarchy__mdt ambito = formatAmbit(usuario.gf_user_operation_ambit_name__c);
        String ambitCountry = formatAmbitCountry(usuario.gf_user_operation_ambit_name__c);
        if(ambitCountry == 'OFC' || ambitCountry == 'CIB' || ambitCountry == 'GRM'){
            crpEnable = true;
        }else if (account.DES_Tier__c == '00000024' && ambitCountry != account.DES_Country_Client__c) { // DES_Tier__c == BEeIG-GCB
            if (ambito.FlujoCross__c != null && ambito.FlujoCross__c.containsIgnoreCase(CRP)) {
                crpEnable = true;
            }
        } else if (ambitCountry != account.DES_Country_Client__c) {
            if (ambito.FlujoGeo__c!= null && ambito.FlujoGeo__c.containsIgnoreCase(CRP)) {
                crpEnable = true;
            }
        } else  if (ambitCountry == account.DES_Country_Client__c){
            if (ambito.Flujo__c != null && ambito.Flujo__c.containsIgnoreCase(CRP)) {
                crpEnable = true;
            }
        }

        return crpEnable;
    }


    /**
    * @devuelve codigo ISO 2 del pais del ambito
    * @author Hector Vasquez | 06-13-2022 
    * @param ambitCountry 
    * @return String 
    **/
    public String formatAmbitCountry(String ambitCountry){
        String delimiter = '-';
        String country = ambitCountry.substringBefore(delimiter); //Se obtiene El codigo del pais
        country =  country.trim();
        system.debug('>>>>> country parse: ' + country);
        switch on country{  //Con el Switch transformamos a ISO 2 
            when 'C'{
                return 'CO';
            }
            when 'A'{
                return 'AR';
            }
            when 'E'{
                return 'ES';
            }
            when 'P'{
                return 'ES';
            }
            when 'M'{
                return 'MX';
            }
            when 'PE'{
                return 'PE';
            }
            when else {
                return country;
            }
        }
    }

    /**
    * @Formateo del Ambito
    * @author Global Desktop  - DSL
    * @param ambitUser 
    * @return Arce_ambit_hierarchy__mdt 
    **/
    private static Arce_ambit_hierarchy__mdt formatAmbit(String ambitUser) {
        final List<Arce_ambit_hierarchy__mdt> ambitMetadatas = new List<Arce_ambit_hierarchy__mdt>([
          SELECT Id, DeveloperName, Action__c, Ambit__c, Description__c, Level__c, Region__c, Selectables__c, SelectablesCross__c, Validate__c,
          ValidateCross__c , canRead__c, canEdit__c, canPropose__c, canValidate__c, FlujoCross__c, FlujoGeo__c, Flujo__c
          FROM Arce_ambit_hierarchy__mdt
          ORDER BY Description__c ASC LIMIT 4000
        ]);
        return DES_Arc_GBL_Workflow_Helper.gtAmbitFromLiteral(ambitUser, ambitMetadatas);
    }

    /**
    * @obtiene el local client 
    * @author Global Desktop  - DSL
    * @param ahaId 
    * @return Local_Client__c 
    **/
    private static Local_Client__c getLocalClient (String ahaId) {
         List<Local_Client__c> listLc;
         listLc = [select id, crossBorder__c, country_id__c from Local_Client__c where Id = :ahaId];
         return listLc.get(0);
    }

    /**
    * @obtiene el client 
    * @author Global Desktop  - DSL
    * @param ahaId 
    * @return Account 
    **/
    private static Account getClient (String ahaId) {
        List<Account> listC;
        listC = [select id, DES_Tier__c, DES_Country_Client__c from Account where Id = :ahaId];
        return listC.get(0);
   }

    /**
    * @Se obtiene el usuario 
    * @author Global Desktop  - DSL
    * @return User 
    **/
    private static User getUser() {
        final List<User> usuario = [Select id, DES_Country__c, gf_user_operation_ambit_name__c from User where Id = :System.UserInfo.getUserId()];
        return usuario.get(0);
   }


}