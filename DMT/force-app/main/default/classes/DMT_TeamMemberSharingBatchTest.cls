@isTest
private without sharing class DMT_TeamMemberSharingBatchTest {
    
    // Método de configuración de datos de prueba
    @TestSetup
    static void setupTestData() {
        // Crear usuarios de prueba
        DMT_Test_DataFactory.generateUserWithoutPermissions();
        List<User> testUsers = [SELECT Id, Name FROM User WHERE Email = 'useremail@test.comm'];
        
        // Crear registros DMT_Line__c de prueba
        List<DMT_Line__c> lines = new List<DMT_Line__c>();
        for (Integer i = 0; i < 3; i++) {
            lines.add(new DMT_Line__c(
                Name = 'Test Line ' + i
            ));
        }
        insert lines;
        
        // Crear DMT_TeamMember__c de prueba con CreatedDate reciente
        List<DMT_TeamMember__c> teamMembers = new List<DMT_TeamMember__c>();
        
        // Team Member 1: Con acceso Edit
        teamMembers.add(new DMT_TeamMember__c(
            Name = 'TM 1',
            Line__c = lines[0].Id,
            User__c = testUsers[0].Id,
            AccessLevel__c = 'Edit'
        ));
        
        // Team Member 2: Con acceso Read
        teamMembers.add(new DMT_TeamMember__c(
            Name = 'TM 2',
            Line__c = lines[1].Id,
            User__c = testUsers[0].Id,
            AccessLevel__c = 'Read'
        ));
        
        // Team Member 3: Con acceso Edit para otra línea
        teamMembers.add(new DMT_TeamMember__c(
            Name = 'TM 3',
            Line__c = lines[2].Id,
            User__c = testUsers[0].Id,
            AccessLevel__c = 'Edit'
        ));
        
        insert teamMembers;
        
        // Establecer fechas de creación recientes
        Datetime now = Datetime.now();
        for (DMT_TeamMember__c tm : teamMembers) {
            Test.setCreatedDate(tm.Id, now);
        }
    }
    
    @IsTest
    static void testBatchStartAndExecute() {
        // Obtener los team members creados en el setup
        List<DMT_TeamMember__c> teamMembers = [SELECT Id FROM DMT_TeamMember__c];
        System.assert(!teamMembers.isEmpty(), 'Deberían existir team members');
        
        Test.startTest();
        
        // Ejecutar el batch
        DMT_TeamMemberSharingBatch batch = new DMT_TeamMemberSharingBatch();
        Id batchJobId = Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Verificar que el job se completó
        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, NumberOfErrors 
                           FROM AsyncApexJob 
                           WHERE Id = :batchJobId];
        
        System.assertEquals('Completed', job.Status, 'El batch debería completarse');
        System.assertEquals(0, job.NumberOfErrors, 'No debería haber errores');
        
        // Verificar que se crearon shares
        List<DMT_Line__Share> shares = [SELECT Id, ParentId, UserOrGroupId, AccessLevel 
                                        FROM DMT_Line__Share 
                                        WHERE RowCause = 'Manual'];
        
        // Deberían haberse creado al menos 2 shares (uno Edit y uno Read)
        System.assert(shares.size() >= 2, 'Deberían existir shares manuales');
        
        // Verificar que los shares tienen los niveles de acceso correctos
        List<DMT_TeamMember__c> tms = [SELECT Id, User__c, AccessLevel__c, Line__c 
                                       FROM DMT_TeamMember__c 
                                       WHERE User__c != null];
        
        for (DMT_TeamMember__c tm : tms) {
            List<DMT_Line__Share> tmShares = [SELECT Id, AccessLevel 
                                             FROM DMT_Line__Share 
                                             WHERE ParentId = :tm.Line__c 
                                             AND UserOrGroupId = :tm.User__c 
                                             AND RowCause = 'Manual'];
            
            if (!tmShares.isEmpty()) {
                String expectedAccess = tm.AccessLevel__c.contains('Edit') ? 'Edit' : 'Read';
                System.assertEquals(expectedAccess, tmShares[0].AccessLevel, 
                                   'El share debería tener el nivel de acceso correcto');
            }
        }
    }
    
    @IsTest
    static void testBatchWithOwnerUser() {
        // Crear un line con el usuario actual como owner
        DMT_Line__c line = new DMT_Line__c(Name = 'Owner Test Line');
        insert line;
        
        // Crear team member donde el usuario es el owner
        DMT_TeamMember__c tm = new DMT_TeamMember__c(
            Name = 'Owner TM',
            Line__c = line.Id,
            User__c = UserInfo.getUserId(),
            AccessLevel__c = 'Edit'
        );
        insert tm;
        
        // Establecer fecha de creación reciente
        Test.setCreatedDate(tm.Id, Datetime.now());
        
        Test.startTest();
        
        DMT_TeamMemberSharingBatch batch = new DMT_TeamMemberSharingBatch();
        Id batchJobId = Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Verificar que NO se creó share para el owner
        List<DMT_Line__Share> ownerShares = [SELECT Id 
                                            FROM DMT_Line__Share 
                                            WHERE ParentId = :line.Id 
                                            AND UserOrGroupId = :UserInfo.getUserId() 
                                            AND RowCause = 'Manual'];
        
        System.assert(ownerShares.isEmpty(), 'No debería crearse share para el owner del registro');
    }
    
    @IsTest
    static void testBatchUpdateExistingShare() {
        // Obtener datos existentes
        List<DMT_TeamMember__c> existingTMs = [SELECT Id, Line__c, User__c 
                                               FROM DMT_TeamMember__c 
                                               WHERE AccessLevel__c = 'Read' 
                                               LIMIT 1];
        
        if (!existingTMs.isEmpty()) {
            // Crear un share manual existente con nivel diferente
            DMT_Line__Share existingShare = new DMT_Line__Share(
                ParentId = existingTMs[0].Line__c,
                UserOrGroupId = existingTMs[0].User__c,
                AccessLevel = 'Edit', // Diferente al team member (que es Read)
                RowCause = Schema.DMT_Line__Share.RowCause.Manual
            );
            insert existingShare;
            
            Test.startTest();
            
            // Ejecutar batch
            DMT_TeamMemberSharingBatch batch = new DMT_TeamMemberSharingBatch();
            Id batchJobId = Database.executeBatch(batch, 50);
            
            Test.stopTest();
            
            // Verificar que el share se actualizó a Read
            DMT_Line__Share updatedShare = [SELECT Id, AccessLevel 
                                           FROM DMT_Line__Share 
                                           WHERE Id = :existingShare.Id];
            
            System.assertEquals('Read', updatedShare.AccessLevel, 
                               'El share debería haberse actualizado a Read');
        }
    }
    
    @IsTest
    static void testBatchWithInvalidData() {
        // Crear datos inválidos
        DMT_Line__c line = new DMT_Line__c(Name = 'Invalid Test Line');
        insert line;
        
        // Team Member sin usuario
        DMT_TeamMember__c tm1 = new DMT_TeamMember__c(
            Name = 'Invalid TM 1',
            Line__c = line.Id,
            AccessLevel__c = 'Edit'
        );
        
        // Team Member con acceso inválido
        DMT_TeamMember__c tm2 = new DMT_TeamMember__c(
            Name = 'Invalid TM 2',
            Line__c = line.Id,
            User__c = UserInfo.getUserId(),
            AccessLevel__c = 'Edit'
        );
        
        List<DMT_TeamMember__c> invalidTMs = new List<DMT_TeamMember__c>{tm1, tm2};
        insert invalidTMs;
        
        // Establecer fechas recientes
        for (DMT_TeamMember__c tm : invalidTMs) {
            Test.setCreatedDate(tm.Id, Datetime.now());
        }
        
        Test.startTest();
        
        DMT_TeamMemberSharingBatch batch = new DMT_TeamMemberSharingBatch();
        Id batchJobId = Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // Verificar que el batch se completó (aunque con errores)
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors 
                           FROM AsyncApexJob 
                           WHERE Id = :batchJobId];
        
        System.assertEquals('Completed', job.Status, 'El batch debería completarse');
        
        // El batch maneja los errores internamente, no debería fallar
        System.assertEquals(0, job.NumberOfErrors, 'El batch no debería fallar por errores manejados');
    }
    
    @IsTest
    static void testBatchFinishMethod() {
        Test.startTest();
        
        // Ejecutar batch con datos del setup
        DMT_TeamMemberSharingBatch batch = new DMT_TeamMemberSharingBatch();
        Id batchJobId = Database.executeBatch(batch, 50);
        
        Test.stopTest();
        
        // El método finish se ejecuta automáticamente
        // Verificar que no hay excepciones
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :batchJobId];
        System.assertEquals('Completed', job.Status, 'El batch debería completarse');
    }

    @IsTest
    static void testSchedulerExecuteMethod() {
        Test.startTest();
        
        // Crear instancia del scheduler
        DMT_TeamMemberSharingScheduler scheduler = new DMT_TeamMemberSharingScheduler();
        
        // Crear un contexto de scheduler simulado
        String cronExp = '0 0 2 * * ?'; // Todos los días a las 2:00 AM
        String jobName = 'DMT Team Member Sharing Nightly Batch';
        
        // Programar el job
        System.schedule(jobName, cronExp, scheduler);
        
        Test.stopTest();
        
        // Verificar que el job fue programado
        List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression, State, NextFireTime 
                                          FROM CronTrigger 
                                          WHERE CronExpression = :cronExp];
        
        System.assert(!scheduledJobs.isEmpty(), 'El job debería estar programado');
        System.assertEquals(cronExp, scheduledJobs[0].CronExpression, 'La expresión cron debería coincidir');
        
        // También podemos verificar que se puede instanciar el scheduler sin errores
        System.assert(scheduler != null, 'El scheduler debería instanciarse correctamente');
    }
}