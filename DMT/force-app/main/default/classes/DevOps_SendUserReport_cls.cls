/**
* @author       Victor Velandia
* Project:      BBVA
* Description:  Schedulable encargado de llamar DevOps_SendUserReport_cls
*
* -----------------------------------------------------------------------------
*             No.     Date            Author                  Description
*             -----   ----------      --------------------    -----------------
* @version    1.0     2020-04-13      Victor Velandia (VV)    Clase Initial
*******************************************************************************/
public with sharing class DevOps_SendUserReport_cls {

  /**
  * description: strGeneratedCSVFile
  * @author Victor Velandia
  */
  public String strGeneratedCSVFile {get;set;}
  /*
  * description: lstQueryUsers
  * @author Victor Velandia
  */
  public list<user> lstQueryUsers {get;set;}
  /**
  * description: Controller DevOps_SendUserReport_cls
  * @author Victor Velandia
  */
  public void DevOps_SendUserReport_cls() {
    this.strGeneratedCSVFile = '';
  }
  /**
  * description: loginHistoryByUser
  * @author Victor Velandia
  */



  public void loginHistoryByUser() {

    //Set de Ids para guardar los Ids de los Usuarios
    set<Id> setIds = new set<Id>();
    
    //Set de string para guardar las fechas por dias
    set<String> setStringDtXTd = new set<String>();
    
    list<LoginHistory> lstLoginHistory = new list<LoginHistory>();
    Map<string, list<Datetime>> mapLoginbyUsers = new Map<string, list<Datetime>>();
    map<string, set<string>> mapFrecUserByLogin = new map<string, set<string>>();
    Map<Id,Profile> mapLicenseId = new Map<id,profile>([SELECT Id,UserLicenseId FROM Profile where UserLicenseId  in (SELECT Id FROM UserLicense where name ='Salesforce')]);

    lstQueryUsers = [SELECT id,
                            ID_User__c,
                            Name,
                            username,
                            CreatedDate,
                            IsActive,
                            Department,
                            Profile.Name,
                            Profile.UserLicense.Name,
                            LastLoginDate
                        FROM User
                        WHERE IsActive = true
						AND id != '0054H000007ZqlNQAS' 
                        AND Profile.Name != null
                        AND profile.name NOT IN ('System Dataloader',
                                                 'System Administrator',
                                                 'Service Integration Remedy',
                                                 'Desktop Integration') 
                    ];
    for(user objUsers : lstQueryUsers) {
      setIds.add(objUsers.Id);
    }
    
    //Lista de login history ordenada por el campo logintime
    lstLoginHistory = [SELECT UserId,
                              Browser,
                              Status,
                              LoginTime,
                              Application
                          FROM LoginHistory
                          WHERE UserId =:setIds
                           AND LoginTime = LAST_N_Days:1 
                          ORDER BY LoginTime desc
                      ];
    //recorro la list para obtener el numero de login que ha realizado el usuario
    for ( LoginHistory objLoginbyUser : lstLoginHistory ) {
      if ( objLoginbyUser.Application == 'Browser' && objLoginbyUser.Status == 'Success' ) {
        
        //Calculamos el primer valor del login de user
        if ( !mapLoginbyUsers.containsKey(objLoginbyUser.UserId) ) {
          mapLoginbyUsers.put(objLoginbyUser.UserId, new list<Datetime>{ objLoginbyUser.LoginTime });
       
        //Agregamos un valor adicional si el usuario a iniciado sesion varias veces
        } else if ( mapLoginbyUsers.get(objLoginbyUser.UserId).size() < 2 ) {
          list<Datetime> lstUserbyLoginTMP = new list<Datetime>();
          lstUserbyLoginTMP = mapLoginbyUsers.get(objLoginbyUser.UserId);
          lstUserbyLoginTMP.add(objLoginbyUser.LoginTime);
          mapLoginbyUsers.put(objLoginbyUser.UserId, lstUserbyLoginTMP);
        }
        
        //Recorro la list lstLoginHistory para obtener la frecuencia de Usuarios
        if ( objLoginbyUser.loginTime >= system.Now().addMonths(-1) ) {
          if ( !mapFrecUserByLogin.containsKey( objLoginbyUser.UserId ) ) {
            mapFrecUserByLogin.put( objLoginbyUser.UserId, new set<string>{String.valueOf(Date.valueOf( objLoginbyUser.LoginTime ))} );
          } else {
            set<string> setUserbyLoginTMP = new set<string>();
            setUserbyLoginTMP = mapFrecUserByLogin.get( objLoginbyUser.UserId );
            setUserbyLoginTMP.add( string.valueOf(date.valueOf(objLoginbyUser.LoginTime)) );
            mapFrecUserByLogin.put( objLoginbyUser.UserId, setUserbyLoginTMP );
          }
        }
      }
    }

    //Se crea cabecera para el CSV
    String strFileRow = '';
    strGeneratedCSVFile = '';
    strFileRow = strFileRow + ',' + 'ID';
    strFileRow = strFileRow + ',' + 'ID User';
    strFileRow = strFileRow + ',' + 'ACTIVO';
    strFileRow = strFileRow + ',' + 'USER LICENCIA';
    strFileRow = strFileRow + ',' + 'DEPARTAMENTO';
    strFileRow = strFileRow + ',' + 'FECHA DE CREACION';
    strFileRow = strFileRow + ',' + 'ULTIMO LOGINS';
    strFileRow = strFileRow + ',' + 'TIEMPO ENTRE LOS DOS ULTIMOS LOGIN DIAS';
    strFileRow = strFileRow + ',' + 'FRECUENCIA DE LOGIN MENSUAL';
    strFileRow = strFileRow + ',' + 'DIAS SIN CONEXION DESDE ULTIMO LOGIN';
    strFileRow = strFileRow.replaceFirst(',','');
    strGeneratedCSVFile = strGeneratedCSVFile + strFileRow + '\n';

    string strdays;
    String strTimeMin;
    String strTimeHours;
    String strDepartament;
    String strFrecuency;
    String strDaysHourMin;
    String strTimTwoLasLogDay;
    Integer strTimeSeg;
    Integer intDaysLastLogin;
    Date dtLastDateLogin;
    Date dtToday;
    dtToday = system.today();
      
    //Recorre para almacenar los datos en el CSV
    for (user objUser: lstQueryUsers) {

      if ( !mapLoginbyUsers.containsKey(objUser.id) ) {
        strTimTwoLasLogDay = string.valueOf('No Login');
      } else if ( mapLoginbyUsers.get(objUser.id).size() == 1 ) {
        strTimTwoLasLogDay = String.valueOf('N/A');
      } else {
        Long milisecons = mapLoginbyUsers.get(objUser.id).get(0).getTime() - mapLoginbyUsers.get(objUser.id).get(1).getTime();
        //Calcula el tiempo entre los dos ultimos logins por dia para el Usuario
        strTimTwoLasLogDay = String.valueOf( milisecons / ( 3600*24*1000 ));
      }

      //igualo la fecha del ultimo login a la fecha de cración si nunca ha habido un loggin. 
      if (objUser.LastLoginDate == null) {
          dtLastDateLogin = objUser.CreatedDate.date();
      } else {
          dtLastDateLogin = objUser.LastLoginDate.Date();
      }
        
      //Calcula la frecuencia con la que se ha logeado el Usuario
      strFrecuency = mapFrecUserByLogin.containsKey( objUser.id )? String.valueOF( mapFrecUserByLogin.get(objUser.id).size() ): '0';
      
      //Calcula el numero de dias que no ha tenido conexion el Usuario
      intDaysLastLogin = dtLastDateLogin != null ? dtLastDateLogin.daysBetween( dtToday ): 0;
      strdays = String.valueOf( intDaysLastLogin ) != null ? String.valueOf( intDaysLastLogin ) : '0';
        
      //Departament del Usuario
      strDepartament = objUser.Department != null ? objUser.Department : '';
      
      //Inserta la cabecera de las columnas para crear el CSV
      strFileRow = '';
      strFileRow = strFileRow + ',' + objUser.id;
      strFileRow = strFileRow + ',' + objUser.ID_User__c;
      strFileRow = strFileRow + ',' + objUser.IsActive;
      strFileRow = strFileRow + ',' + objUser.Profile.UserLicense.Name;
      strFileRow = strFileRow + ',' + strDepartament;
      strFileRow = strFileRow + ',' + objUser.CreatedDate;
      strFileRow = strFileRow + ',' + objUser.LastLoginDate;
      strFileRow = strFileRow + ',' + strTimTwoLasLogDay;
      strFileRow = strFileRow + ',' + strFrecuency;
      strFileRow = strFileRow + ',' + strdays;
      strFileRow = strFileRow.replaceFirst(',','');
      strGeneratedCSVFile = strGeneratedCSVFile + strFileRow + '\n';

    }
    system.debug('--->>> strTimTwoLasLogDa ' + strTimTwoLasLogDay);
    system.debug('--->>> strFrecuency ' + strFrecuency);
    system.debug('--->>> strdays ' + strdays);
    system.debug('--->>> strGeneratedCSVFile ' + strGeneratedCSVFile);
    system.debug('--->>> strFileRow ' + strFileRow);


    SendEmail();
  }

  /**
  * description: SendEmail
  * @author Victor Velandia
  */
  public void SendEmail() {

    List<EmailTemplate> lstTemplates = new List<EmailTemplate>();
    lstTemplates = [SELECT Id,
                            HtmlValue,
                            Body,
                            DeveloperName
                      FROM EmailTemplate
                      WHERE DeveloperName = 'DevOps_EmailHtmlBodyReportUser'
                    ];
    system.debug('--->>> lstTemplates ' + lstTemplates);

    lstQueryUsers = [SELECT id,
                            ID_User__c,
                            Name,
                            username,
                            CreatedDate,
                            IsActive,
                            Department,
                            ProfileId,
                            Profile.Name,
                            Profile.UserLicense.Name,
                            LastLoginDate
                        FROM User
                        WHERE Profile.Name != null
                        AND profile.name NOT IN ('System Dataloader',
                                                 'System Administrator',
                                                 'Service Integration Remedy',
                                                 'Desktop Integration')                      
                    ];
    Set<String> setUserActive = new Set<String>();
    Set<String> setUserInactive = new Set<String>();
    Set<String> setUserDestokp = new Set<String>();
    Set<String> setUserService = new Set<String>();
    Set<String> setUserOtros = new Set<String>();
    for(user objUser : lstQueryUsers){
      if(objUser.IsActive) {
        setUserActive.add(objUser.id);
      } else {
        setUserInactive.add(objUser.id);
      }
      if(objUser.Profile.Name != null && objUser.IsActive) {
        if(objUser.Profile.Name.contains('BBVA')) {
          setUserDestokp.add(objUser.id);
        } else if(objUser.Profile.Name.contains('Service')) {
          setUserService.add(objUser.id);
        } else {
          setUserOtros.add(objUser.id);
        }
      }
    }
    system.debug('--->>> setUserDestokp ' + setUserDestokp);
    system.debug('--->>> setUserService ' + setUserService);
    system.debug('--->>> setUserOtros ' + setUserOtros);

    string strToday = Datetime.now().format('yyyy-MM-dd\' / \'HH:mm:ss', 'GMT+0200');
    system.debug('--->>> strToday ' + strToday);
    Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
    Blob csvBlob = blob.valueOf(strGeneratedCSVFile);
    String strcsvName = 'Reporte usuarios producción: '+ strToday +'.csv';
    csvAttachment.setFileName(strcsvName);
    csvAttachment.setBody(csvBlob);
    csvAttachment.setContentType('text/csv');
    final Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    String[] strToAddresses = Label.DevOps_EmailReportUsers_Address.split(';');
    system.debug('--->>> strToAddresses ' + strToAddresses);
    String strSubject = Label.DevOps_EmailReportUsers_Subject;
    system.debug('--->>> strSubject ' + strSubject);
    email.setSubject(strSubject);
    email.setToAddresses(strToAddresses);
    email.setPlainTextBody('Reporte usuarios producción: '+ strToday +'');
    String strHtmlBody = lstTemplates.get(0).htmlvalue;
    strHtmlBody = strHtmlBody.replace('{!Today}', strToday);
    strHtmlBody = strHtmlBody.replace('{!User.size}', string.valueOf(lstQueryUsers.size()));
    strHtmlBody = strHtmlBody.replace('{!User.Activos}', string.valueOf(setUserActive.size()));
    strHtmlBody = strHtmlBody.replace('{!User.Inactivos}', string.valueOf(setUserInactive.size()));
    strHtmlBody = strHtmlBody.replace('{!User.Desktop}', string.valueOf(setUserDestokp.size()));
    strHtmlBody = strHtmlBody.replace('{!User.Service}', string.valueOf(setUserService.size()));
    strHtmlBody = strHtmlBody.replace('{!User.Otros}', string.valueOf(setUserOtros.size()));
    system.debug('--->>> strHtmlBody ' + strHtmlBody);
    email.setHtmlBody(strHtmlBody);
    system.debug('--->>> csvAttachment1 ' + csvAttachment);
    email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
    Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});

  }
}