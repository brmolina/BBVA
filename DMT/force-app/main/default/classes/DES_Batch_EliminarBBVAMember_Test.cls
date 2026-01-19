/*
*
*Test para probar DES_Batch_EliminarBBVAMember
*/
@isTest
public with sharing class DES_Batch_EliminarBBVAMember_Test {

    @testSetup
    static void setup() {//NOSONAR
        final DES_UtilTestClass utilClass = new DES_UtilTestClass();
        final List<Opportunity> listaOpps = new List<Opportunity>();
        final List<dwp_kitv__Visit__c> listaVisitas = new List<dwp_kitv__Visit__c>();
        final List<almd__Commercial_Alert__c> listaAlertas = new List<almd__Commercial_Alert__c>();
        final Account acc = utilClass.createClient();
        insert acc;
        final Account acc2 = utilClass.createClient();
        insert acc2;
        final List<DES_Subsidiary_Group_Relation__c> listaMatrix = new List<DES_Subsidiary_Group_Relation__c>();
        Profile perfil;
        perfil = [SELECT id, Name from Profile where Name =: System.Label.DES_INTEGRATION_PROFILE LIMIT 1];
        Final String idProfile = perfil.Id;
        List<User> lstUser;
        lstUser = new List<User>();
        User userTest;
        userTest = utilClass.createUser(idProfile);
        lstUser.add(userTest);
        final DES_Subsidiary_Group_Relation__c matrix = new DES_Subsidiary_Group_Relation__c();
            matrix.participant_child_id__c = acc2.Id;
            matrix.participant_parent_id__c = acc.Id;
            matrix.main_subsidiary_ind_type__c = true;
            listaMatrix.add(matrix);
        insert listaMatrix;
        String idProf;
        idProf = utilClass.createProfile();
        User userTest2;
        userTest2 = utilClass.createUser(idProf);
        userTest2.ID_User__c= '2020-02-10 12:12:09';
        System.debug('idProfile------------------>'+idProfile);
        System.debug('idProf-------------------->'+idProf);
        lstUser.add(userTest2);
        System.debug('lstUser[0]-------------------->'+lstUser[0]);
        System.debug('lstUser[1]-------------------->'+lstUser[1]);
        insert lstUser;
        system.runAs(userTest) {
        final DES_BBVA_Management_team__c member = new DES_BBVA_Management_team__c();
        member.DES_Client__c = acc.Id;
        member.copy_record_approval_type__c = false;
        member.DES_User__c = userTest2.id;
        final DES_BBVA_Management_team__c member2 = new DES_BBVA_Management_team__c();
        member2.DES_Client__c = acc.Id;
        member2.copy_record_approval_type__c = false;
        member2.DES_User__c = userTest2.id;
        List<DES_BBVA_Management_team__c> lstMember;
        lstMember = new List<DES_BBVA_Management_team__c>();
        lstMember.add(member);
		lstMember.add(member2);
        insert lstMember;
        final List<DES_BBVA_Management_team__c> lbbva = [SELECT id, CreatedBy.Name, DES_Client__c, CreatedBy.Profile.Name, LastModifiedDate from DES_BBVA_Management_team__c WHERE Id =: member.id];
        System.debug('QUERY------------------>'+lbbva.get(0).CreatedBy.Profile.Name);
            System.debug('QUERY------------------>'+lbbva.get(0).LastModifiedDate);
		}
            Test.startTest();
            final Opportunity opp = utilClass.createOpportunity(acc);
            opp.StageName = LABEL.DES_Proposal;
            listaOpps.add(opp);
            insert listaOpps;
        	final dwp_kitv__Visit__c visit = utilClass.createVisit(acc, opp);
            visit.disclosure_info_type__c = Label.DES_OP_CONFIDENTIAL;
        	visit.RecordTypeId = Desktop_Utils.RTVISITCONF;
            listaVisitas.add(visit);
            insert listaVisitas;
        	final almd__Commercial_Alert__c alert = utilClass.createAlert(userTest,userTest2,acc,1,'Commercial Task');
        	final almd__Commercial_Alert__c alert2 = utilClass.createAlert(userTest,userTest2,acc2,1,'Commercial Task');
        	listaAlertas.add(alert);
        	listaAlertas.add(alert2);
            insert listaAlertas;
        	Test.stopTest();

    }
    /*
    *
    *Test para probar DES_Batch_EliminarBBVAMember
    */
    @isTest
    public static void batchEliminarBBVAMemberTest() {
        Test.startTest();
		final Id batchInstanceId = Database.executeBatch(new DES_Batch_EliminarBBVAMember(),200);
        System.assertNotEquals(batchInstanceId,null,'Error');
        Test.stopTest();
    }
}