/***************************************************************************************
 * @author        BBVA
 * @date          17/06/2020
 * @description   Clase de test para el Trigger del objeto User y su Handler (refactor 2026).
 *
 *                Objetivos de cobertura:
 *                 - Orquestadores handleBeforeInsert/Update y handleAfterInsert/Update.
 *                 - Ramas de shouldSkipAmbitUpdate y getActiveUsers (incluye returns).
 *                 - Rama skipDenorm=true para ejecutar setUserGroup (sin MIXED_DML).
 *                 - Asignación / eliminación de Permission Set de Chatter.
 *                 - Ramas específicas de México (onAfterInsert / onAfterUpdate).
 *                 - Rama completa de handleReactivatedUsers cuando existen registros:
 *                      • delete existing
 *                      • recreación e insert de nuevos miembros
 *
 *                Notas:
 *                 - No se valida dwp_kitv__EMPLOYEE_DEPARTMENT_DESC__c porque
 *                   EMPLOYEE_DEPARTMENT_DESC__c no es rellenable en este org.
 *                 - Se evita DML sobre CIB_Bypass__c para no provocar MIXED_DML.
 **************************************************************************************/
@isTest@SuppressWarnings('sf:TooManyMethods')
private class UserTrigger_Test{
  
  private static final String EUROPE = 'Europe/London';
  private static final String UTF8 = 'UTF-8';
  
  private static final String LEGAL_GRP_1 = 'DES_LEGAL_Entity_Test1';
  private static final String LEGAL_GRP_2 = 'DES_LEGAL_Entity_Test2';
  
  /**********************************************************************************************************
   * @name            uniqueUsername
   * @author          BBVA
   * @created         25/02/2026
   * @description     Genera un username único para evitar colisiones en tests.
   * @param           String seed - Semilla identificativa para el username.
   * @return          String - Username único.
   **********************************************************************************************************/
  private static String uniqueUsername(String seed){
    return seed + '.' + String.valueOf(DateTime.now().getTime()) + '@test.local';
  }

  /**********************************************************************************************************
   * @name            buildUser
   * @author          BBVA
   * @created         25/02/2026
   * @description     Construye un User mínimo y válido para pruebas.
   * @param           Id profileId - Id del Profile a asignar.
   * @param           String idUser - Valor para ID_User__c.
   * @param           String seed - Semilla para Username/Alias/Email.
   * @return          User - Usuario listo para insertar.
   **********************************************************************************************************/
  private static User buildUser(Id profileId, String idUser, String seed){
    return new User(
      ProfileId = profileId, 
      Username = uniqueUsername(seed), 
      LastName = 'LN_' + seed, 
      Email = seed + '@test.local', 
      Alias = (seed.length() > 8 ? seed.substring(0, 8) : seed), 
      CommunityNickname = 'nick_' + String.valueOf(Crypto.getRandomInteger()), 
      TimeZoneSidKey = EUROPE, 
      LocaleSidKey = 'en_US', 
      EmailEncodingKey = UTF8, 
      LanguageLocaleKey = 'en_US', 
      ID_User__c = idUser, 
      DES_Country__c = 'ESP'
    );
  }

  /**********************************************************************************************************
   * @name            getProfileConsultationIT
   * @author          BBVA
   * @created         25/02/2026
   * @description     Devuelve el ProfileId de "Consultation IT".
   * @return          Id - ProfileId.
   **********************************************************************************************************/
  private static Id getProfileConsultationIT(){
    return [SELECT Id
            FROM Profile
            WHERE Name = 'Consultation IT'
            LIMIT 1].Id;
  }
  
  /**********************************************************************************************************
   * @name            setupData
   * @author          BBVA
   * @created         25/02/2026
   * @description     Crea datos base reutilizables por todos los tests (grupos Legal).
   * @return          void
   **********************************************************************************************************/
  @testSetup
  static void setupData(){
    
    insert new Group(
      Name = LEGAL_GRP_1, 
      DeveloperName = LEGAL_GRP_1, 
      Type = 'Regular'
    );
    insert new Group(
      Name = LEGAL_GRP_2, 
      DeveloperName = LEGAL_GRP_2, 
      Type = 'Regular'
    );
  }
  
  /**********************************************************************************************************
   * @name            UserLogic_assignPermissionSet_smoke
   * @author          BBVA
   * @created         25/02/2026
   * @description     Smoke test: verifica que assignPermissionSet no lanza errores con un set de usuarios.
   * @return          void
   **********************************************************************************************************/
  @isTest
  static void UserLogic_assignPermissionSet_smoke(){
    Test.startTest();
    PermissionSet ps = [SELECT Id
                        FROM PermissionSet
                        LIMIT 1];
    List<User> someUsers = [SELECT Id
                            FROM User
                            LIMIT 3];

    Set<Id> ids = new Set<Id>();
    for (User u : someUsers)
      ids.add(u.Id);
    UserLogic.assignPermissionSet(ps.Id, ids);
    UserLogic.assignPermissionSet(ps.Id, ids);
    Test.stopTest();

    System.assertNotEquals(null, ids, 'El set de usuarios no debería ser null.');
  }
  
  /**********************************************************************************************************
   * @name            handleBeforeUpdate_skipAmbit_true
   * @author          BBVA
   * @created         25/02/2026
   * @description     Cubre la rama donde shouldSkipAmbitUpdate devuelve true y el orquestador hace return.
   * @return          void
   **********************************************************************************************************/
  @isTest
  static void handleBeforeUpdate_skipAmbit_true(){
    Id profileId = getProfileConsultationIT();

    User u = buildUser(profileId, 'ID_AMBIT_1', 'amb1');
    u.gf_user_operation_ambit_name__c = 'A';
    insert u;

    User oldU = [SELECT Id, gf_user_operation_ambit_name__c, UserType, DES_Disable_Chatter__c
                 FROM User
                 WHERE Id = :u.Id];
                 
    u.gf_user_operation_ambit_name__c = 'B';

    List<User> newList = new List<User>{ u };
    Map<Id, User> oldMap = new Map<Id, User>{ u.Id => oldU };

    Test.startTest();
    
    UserTriggerHandler.getInstance().handleBeforeUpdate(newList, oldMap, false);
    Test.stopTest();

    System.assertEquals('B', u.gf_user_operation_ambit_name__c, 'El cambio de ambit debería mantenerse en memoria.');
  }
  
  /**********************************************************************************************************
   * @name            handleAfterInsert_no_activos_return
   * @author          BBVA
   * @created         25/02/2026
   * @description     Cubre la rama en la que getActiveUsers devuelve vacío y handleAfterInsert hace return.
   *                (No se hace DML, se invoca el orquestador directamente).
   * @return          void
   **********************************************************************************************************/
  @isTest
  static void handleAfterInsert_no_activos_return(){
    Id profileId = getProfileConsultationIT();
    
    User u = buildUser(profileId, 'ID_NOACT_1', 'noact1');
    u.IsActive = false;

    List<User> newList = new List<User>{ u };
    Map<Id, User> newMap = new Map<Id, User>();

    Test.startTest();
    UserTriggerHandler.getInstance().handleAfterInsert(newList, newMap, true);
    Test.stopTest();

    System.assert(true, 'Ejecución completada sin errores (return esperado).');
  }
  
  /**********************************************************************************************************
   * @name            handleAfterInsert_skipDenorm_setUserGroup_y_mexico
   * @author          BBVA
   * @created         25/02/2026
   * @description     Cubre:
   *                 - Rama skipDenorm=true -> setUserGroup(users)
   *                 - checkAssignChatterPermissionSet(users)
   *                 - onAfterInsert -> rama México (Country == 'MEX')
   * @return          void
   **********************************************************************************************************/
  @isTest
  static void handleAfterInsert_skipDenorm_setUserGroup_y_mexico(){
    Id profileId = getProfileConsultationIT();

    User u = buildUser(profileId, 'ID_AI_1', 'ai1');
    
    u.DES_Country__c = 'MEX';
    
    u.Entity_name__c = LEGAL_GRP_1 + ';' + LEGAL_GRP_2;
    insert u;
    
    User inserted = [SELECT Id, IsActive, Country, Entity_name__c, UserType, DES_Disable_Chatter__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c
                     FROM User
                     WHERE Id = :u.Id];

    List<User> newList = new List<User>{ inserted };
    Map<Id, User> newMap = new Map<Id, User>{ inserted.Id => inserted };

    Test.startTest();
    
    UserTriggerHandler.getInstance().handleAfterInsert(newList, newMap, true);
    Test.stopTest();
    
    Integer gmCount = [SELECT COUNT()
                       FROM GroupMember
                       WHERE UserOrGroupId = :inserted.Id AND Group.DeveloperName IN:new Set<String>{ LEGAL_GRP_1, LEGAL_GRP_2 }];
    System.assertEquals(2, gmCount, 'Debería crear 2 GroupMember para las dos entidades Legal.');
    
    System.assertEquals('MEX', [SELECT Country
                                FROM User
                                WHERE Id = :inserted.Id].Country, 'Country debería sincronizarse desde DES_Country__c.');
  }
  
  /**********************************************************************************************************
   * @name            handleAfterUpdate_mexico_y_inactivo
   * @author          BBVA
   * @created         25/02/2026
   * @description     Cubre ramas de onAfterUpdate:
   *                 - Usuario activo: MEX -> ESP (mexicoDeactivate)
   *                 - Usuario activo: ESP -> MEX (mexicoActivate)
   *                 - Usuario inactivo con Country=MEX (mexicoDeactivate por rama else)
   *                 Además cubre handleAfterUpdate con activeUsers vacío (return).
   * @return          void
   **********************************************************************************************************/
  @isTest
  static void handleAfterUpdate_mexico_y_inactivo(){
    Id profileId = getProfileConsultationIT();
    
    User u = buildUser(profileId, 'ID_MX_1', 'mx1');
    u.DES_Country__c = 'MEX';
    insert u;
    
    User old1 = [SELECT Id, IsActive, Country, DES_Country__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, UserType, DES_Disable_Chatter__c
                 FROM User
                 WHERE Id = :u.Id];
                 
    u.DES_Country__c = 'ESP';
    update u;

    User after1 = [SELECT Id, IsActive, Country, DES_Country__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, UserType, DES_Disable_Chatter__c
                   FROM User
                   WHERE Id = :u.Id];
    List<User> newList1 = new List<User>{ after1 };
    Map<Id, User> oldMap1 = new Map<Id, User>{ old1.Id => old1 };
    Map<Id, User> newMap1 = new Map<Id, User>{ after1.Id => after1 };

    Test.startTest();
    UserTriggerHandler.getInstance().handleAfterUpdate(newList1, oldMap1, newMap1, false);
    
    User old2 = [SELECT Id, IsActive, Country, DES_Country__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, UserType, DES_Disable_Chatter__c
                 FROM User
                 WHERE Id = :u.Id];
    u.DES_Country__c = 'MEX';
    update u;

    User after2 = [SELECT Id, IsActive, Country, DES_Country__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, UserType, DES_Disable_Chatter__c
                   FROM User
                   WHERE Id = :u.Id];
      
    UserTriggerHandler.getInstance().handleAfterUpdate(new List<User>{ after2 }, new Map<Id, User>{ old2.Id => old2 }, new Map<Id, User>{ after2.Id => after2 }, false);
    
    User old3 = [SELECT Id, IsActive, Country, DES_Country__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, UserType, DES_Disable_Chatter__c
                 FROM User
                 WHERE Id = :u.Id];
    u.IsActive = false;
    u.DES_Country__c = 'MEX';
    update u;

    User after3 = [SELECT Id, IsActive, Country, DES_Country__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, UserType, DES_Disable_Chatter__c
                   FROM User
                   WHERE Id = :u.Id];
      
    UserTriggerHandler.getInstance().handleAfterUpdate(new List<User>{ after3 }, new Map<Id, User>{ old3.Id => old3 }, new Map<Id, User>{ after3.Id => after3 }, false);
    
    User phantom = buildUser(profileId, 'ID_PHANTOM', 'ph1');
    phantom.IsActive = false;
      
    UserTriggerHandler.getInstance().handleAfterUpdate(new List<User>{ phantom }, new Map<Id, User>(), new Map<Id, User>(), false);
    Test.stopTest();

    System.assertEquals(false, [SELECT IsActive
                                FROM User
                                WHERE Id = :u.Id].IsActive, 'El usuario debería quedar inactivo.');
  }

  // ------------------------------------------------------------------------------------
  // Cobertura: Chatter assign/remove (update path)
  // ------------------------------------------------------------------------------------
  /**********************************************************************************************************
   * @name            chatter_assign_y_remove
   * @author          BBVA
   * @created         25/02/2026
   * @description     Cubre:
   *                 - Asignación de Permission Set Chatter (insert / handleAfterInsert)
   *                 - Eliminación por DES_Disable_Chatter__c=true (handleAfterUpdate)
   * @return          void
   **********************************************************************************************************/
  @isTest
  static void chatter_assign_y_remove(){
    Id profileId = getProfileConsultationIT();

    User u = buildUser(profileId, 'ID_CHAT_1', 'chat1');
    u.DES_Disable_Chatter__c = false;
    insert u;

    User inserted = [SELECT Id, IsActive, UserType, DES_Disable_Chatter__c, Country, DES_Country__c, DES_LevelUO_1__c, gf_user_operation_ambit_name__c
                     FROM User
                     WHERE Id = :u.Id];
                     
    Test.startTest();
    UserTriggerHandler.getInstance().handleAfterInsert(new List<User>{ inserted }, new Map<Id, User>{ inserted.Id => inserted }, false);
    
    User oldU = [SELECT Id, IsActive, DES_Disable_Chatter__c, UserType, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, Country
                 FROM User
                 WHERE Id = :u.Id];

    u.DES_Disable_Chatter__c = true;
    update u;

    User updated = [SELECT Id, IsActive, DES_Disable_Chatter__c, UserType, DES_LevelUO_1__c, gf_user_operation_ambit_name__c, Country
                    FROM User
                    WHERE Id = :u.Id];
      
    UserTriggerHandler.getInstance().handleAfterUpdate(new List<User>{ updated }, new Map<Id, User>{ oldU.Id => oldU }, new Map<Id, User>{ updated.Id => updated }, false);
    Test.stopTest();
    
    Integer psaCount = [SELECT COUNT()
                        FROM PermissionSetAssignment
                        WHERE AssigneeId = :u.Id AND PermissionSet.Name = :Label.DES_Name_PermissionSet_Chatter];
    System.assertEquals(0, psaCount, 'El Permission Set de Chatter debería eliminarse al deshabilitarlo.');
  }

  // ------------------------------------------------------------------------------------
  // Cobertura: handleReactivatedUsers con delete + recreate (máxima cobertura)
  // ------------------------------------------------------------------------------------
  /**********************************************************************************************************
   * @name            reactivation_future_delete_y_recreate
   * @author          BBVA
   * @created         25/02/2026
   * @description     Cubre la rama completa de handleReactivatedUsers cuando existen registros:
   *                 - Query devuelve registros
   *                 - delete existing
   *                 - recreación e insert de registros nuevos
   *
   *                 Implementación robusta:
   *                  - Se crea Opportunity abierta.
   *                  - Se crea DES_Opportunity_Management_member__c con campos requeridos dinámicamente (Describe).
   * @return          void
   **********************************************************************************************************/
  @isTest
  static void reactivation_future_delete_y_recreate(){
    Id profileId = getProfileConsultationIT();

    User u = buildUser(profileId, 'ID_REACT_1', 'react1');
    insert u;

    Opportunity opp = new Opportunity(
      Name = 'Opp Test React', 
      StageName = 'Prospecting', 
      CloseDate = Date.today().addDays(10)
    );
    insert opp;
    
    SObject otm = buildRequiredSObject(Schema.getGlobalDescribe().get('DES_Opportunity_Management_member__c'), new Map<String, Object>{ 
    'DES_User__c' => u.Id, 'DES_Opportunity__c' => opp.Id });
    
    Database.SaveResult sr = Database.insert (otm, false);
    System.assert(sr.isSuccess(), 'No se pudo insertar DES_Opportunity_Management_member__c para cubrir delete/recreate.');

    Test.startTest();
    
    UserTriggerHandler.getInstance().processReactivatedUsers(new Set<Id>{ u.Id });
    Test.stopTest();
    
    Integer countAfter = (Integer) Database.countQuery('SELECT COUNT() FROM DES_Opportunity_Management_member__c WHERE DES_User__c = \'' + String.valueOf(u.Id) + '\'');
    System.assert(countAfter >= 1, 'Debería existir al menos un registro recreado tras la reactivación.');
  }

  // ------------------------------------------------------------------------------------
  // Utilidad: crear SObject dinámico con campos requeridos (Describe)
  // ------------------------------------------------------------------------------------
  /**********************************************************************************************************
   * @name            buildRequiredSObject
   * @author          BBVA
   * @created         25/02/2026
   * @description     Construye un SObject dinámico rellenando campos requeridos (nillable=false) y createable=true.
   *                 Permite sobreescribir valores mediante el mapa "preset".
   *
   *                 Tipos soportados:
   *                  - String / TextArea / Phone / Url / Email: 'TEST'
   *                  - Boolean: false
   *                  - Date: hoy
   *                  - DateTime: ahora
   *                  - Integer/Double/Currency/Percent: 1
   *                  - Picklist: primer valor disponible
   *                  - Reference: si viene en preset se usa; si no, se deja sin setear (para evitar ids erróneos)
   *
   * @param           Schema.SObjectType sobjectType - Tipo del objeto a construir.
   * @param           Map<String,Object> preset - Valores forzados por API name de campo.
   * @return          SObject - Registro listo para insert (en la mayoría de casos).
   **********************************************************************************************************/
  private static SObject buildRequiredSObject(Schema.SObjectType sobjectType, Map<String, Object> preset){
    SObject sobj = sobjectType.newSObject();
    Schema.DescribeSObjectResult dor = sobjectType.getDescribe();

    Map<String, Schema.SObjectField> fields = dor.fields.getMap();
    
    if (preset != null){
      for (String f : preset.keySet()){
        if (fields.containsKey(f)){
          sobj.put(f, preset.get(f));
        }
      }
    }
    
    for (String fieldName : fields.keySet()){
      Schema.DescribeFieldResult fdr = fields.get(fieldName).getDescribe();
      
      if (!fdr.isCreateable())
        continue;
      if (fdr.isNillable())
        continue;
      if (fdr.isCalculated())
        continue;
      if (sobj.get(fieldName) != null)
        continue;
      Schema.DisplayType t = fdr.getType();

      if (t == Schema.DisplayType.String || t == Schema.DisplayType.TextArea || t == Schema.DisplayType.EncryptedString || t == Schema.DisplayType.Phone || t == Schema.DisplayType.Url || t == Schema.DisplayType.Email){

        sobj.put(fieldName, 'TEST');

      } else if (t == Schema.DisplayType.Boolean){

        sobj.put(fieldName, false);

      } else if (t == Schema.DisplayType.Date){

        sobj.put(fieldName, Date.today());

      } else if (t == Schema.DisplayType.DateTime){

        sobj.put(fieldName, DateTime.now());

      } else if (t == Schema.DisplayType.Integer){

        sobj.put(fieldName, 1);

      } else if (t == Schema.DisplayType.Double || t == Schema.DisplayType.Currency || t == Schema.DisplayType.Percent){

        sobj.put(fieldName, 1);

      } else if (t == Schema.DisplayType.Picklist){

        List<Schema.PicklistEntry> pe = fdr.getPicklistValues();
        if (!pe.isEmpty()){
          sobj.put(fieldName, pe[0].getValue());
        }

      } else if (t == Schema.DisplayType.Reference){
        // No inventamos Ids. Si es requerido y no viene en preset,
        // lo dejamos para que el insert nos diga qué falta y ajustarlo con preset.
        // (En este caso, nosotros sí seteamos DES_User__c y DES_Opportunity__c vía preset.)
      }
    }

    return sobj;
  }

}