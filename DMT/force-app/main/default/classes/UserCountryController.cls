/* Esta clase se crea con los atributos "WITHOUT SHARING" porque si no los usuraios al lanzar la query sobre la tabla LOGINGEO no devuelve resultados */
global without sharing class UserCountryController {

    // ---------------
    //Constructor
    // ---------------    
    public UserCountryController(CAServerCallContact controller) {

    }

    // ---------------  
    //public Methods
    // ---------------
        
   
    // ---------------  
    //private Methods
    // ---------------



    // ---------------  
    //Remote Action Methods
    // ---------------     

    //metodo que obtiene el país al que pertenece la IP del usuario.             
    @RemoteAction
    global static String getUserCountry() {
        String resp = '';        
        
        List<LoginHistory> loginInfo = [SELECT UserId, LoginTime, SourceIp, LoginUrl, CountryIso, Status , LoginGeo.Country, LoginGeo.CountryIso from LoginHistory where UserId = :UserInfo.getUserId() order by LoginTime Desc limit 1];
        if (!loginInfo.isEmpty()){
                resp = loginInfo.get(0).LoginGeo.CountryIso;
        }
        
        system.debug(Logginglevel.INFO,'>>>>>>>  getUserCountry()  user: '+ UserInfo.getUserId() + ' - Country: ' + resp);                                  
        return resp;              
    }


    //metodo que obtiene el prexix del usuario.
    @RemoteAction
    global static String getUserPrefix() {
        String resp = '';  

        List<User> lst_User = [SELECT Id, Prefix__c from User where Id = :UserInfo.getUserId() limit 1];      
        
        
        if (!lst_User.isEmpty()){
                resp = lst_User.get(0).Prefix__c;
        }
        
        System.debug(Logginglevel.INFO,'>>>>>>>  getUserPrefix()  user: '+ UserInfo.getUserId() + ' - Locale: ' + resp);                                  
        return resp;              
    }            
       

}