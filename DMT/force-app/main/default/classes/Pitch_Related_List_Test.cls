/**********************************************************************************
* @author       Global Desktop
* @date         07/05/2020
* @description  Test del componente de Pitch_Related_List
**********************************************************************************/
@isTest
public with sharing class Pitch_Related_List_Test {
  /*
  * TEST2VAR
  */
  public static final String TEST2VAR = 'test2';

  /**
  * Test method 1
  */
  @isTest
  public static void test1() {
    final DES_UtilTestClass tstClass = new DES_UtilTestClass();
    final Account iAccount = tstClass.createClient();
    iAccount.SER_CClient__c = 'test1';
    iAccount.Name = 'test1';
    iAccount.DES_Tier__c = '00000020'; // CIB-Platinum
    insert iAccount;

    final pith__Pitch__c iPitch = new pith__Pitch__c();
    iPitch.pith__solution_name_path_desc__c = 'Cash Management';
    iPitch.pith__solution_category_name__c = 'GTB';
    insert iPitch;

    final Denorm_Account_Pitch__c iDenormAccPitch = new Denorm_Account_Pitch__c();
    iDenormAccPitch.participant_id__c = iAccount.Id;
    iDenormAccPitch.gf_pitch_id__c = iPitch.Id;
    insert iDenormAccPitch;

    Pitch_Related_List_Controller.relatedPitches('3', iAccount.Id, '');
    Pitch_Related_List_Controller.relatedPitches('3', iAccount.Id, 'GTB');

    System.assertNotEquals(iDenormAccPitch, null, 'There is no denorm account pitch');
  }
}