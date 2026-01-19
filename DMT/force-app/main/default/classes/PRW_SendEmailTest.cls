/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_SendEmailTest
* @Author   Global Hub
* @Date     Created: 2021-11-25
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_SendEmailBuilder
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2021-11-25 david.rodriguez.lucena.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_SendEmailTest {
  /**
  * @description
  * @author Global Hub | 2021-11-25
  **/
  @isTest
  static void renderTest() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account acc = utilTestClass.createClient();
    insert acc;
    String recordID = 'PRW:::::[{"id":1,"product":"Adeudos - Conjunto adeudos","id_prod":"dypri.set","isDisabled":true}]';
    recordID = recordID + ':::::' + acc.Id + ':::::undefined:::::undefined:::::false';
    final Map<String, String> mapa = new Map<String, String>();
    mapa.put('recordId', recordID);
    final PRW_SendEmailBuilder emailbuilder = new PRW_SendEmailBuilder();
    final Object content = emailbuilder.call('getContent', mapa);
    final Object recipients = emailbuilder.call('getRecipients', mapa); //NOSONAR
    system.assertNotEquals(null, content);
  }

  /**
  * @description
  * @author Global Hub | 2021-11-25
  **/
  @isTest
  static void renderTest1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account acc = utilTestClass.createClient();
    insert acc;
    String recordID = 'PRW:::::[{"id":1,"product":"Adeudos - Conjunto adeudos","id_prod":"dypri.set","isDisabled":true},{"id":2,"product":"Transferencias emitidas - Transf. nacionales y EEE (eur, sek,ron) dest. otros bancos - Oficina","id_prod":"np.nat.transfer.EEE.ob.branch","isDisabled":true}]';
    recordID = recordID + ':::::' + acc.Id + ':::::undefined:::::undefined:::::false';
    final String args = '{"selectedIds":["flats-dypri.set","specials-np.nat.transfer.EEE.ob.branch","sigblock-'+UserInfo.getUserId()+'"]}';
    final Map<String, String> mapa2 = new Map<String, String>();
    mapa2.put('args', args);
    mapa2.put('recordId', recordID);
    final PRW_SendEmailBuilder emailbuilder = new PRW_SendEmailBuilder();
    final Object content1 = emailbuilder.call('renderContent', mapa2);
    system.assertNotEquals(null, content1);
  }

  /**
  * @description
  * @author Global Hub | 2021-11-25
  **/
  @isTest
  static void renderTest2() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account acc = utilTestClass.createClient();
    acc.Name = 'testcuenta1';
    final Account acc2 = utilTestClass.createClient();
    acc2.Name = 'testcuenta2';
    final Account acc3 = utilTestClass.createClient();
    acc3.Name = 'testcuenta3';
    final List<Account> accs = new List<Account>();
    accs.add(acc);
    accs.add(acc2);
    accs.add(acc3);
    insert accs;

    String recordID = 'PRW:::::[{"id":1,"product":"Adeudos - Conjunto adeudos","id_prod":"dypri.set","isDisabled":true},{"id":2,"product":"Transferencias emitidas - Transf. nacionales y EEE (eur, sek,ron) dest. otros bancos - Oficina","id_prod":"np.nat.transfer.EEE.ob.branch","isDisabled":true}]';
    recordID = recordID + ':::::' + acc.Id + ':::::'+acc2.Id+'-'+acc3.Id+':::::undefined:::::true';

    final String args = '{"selectedIds":["flats-dypri.set","specials-np.nat.transfer.EEE.ob.branch","sigblock-'+UserInfo.getUserId()+'"]}';
    final Map<String, String> mapa2 = new Map<String, String>();
    mapa2.put('args', args);
    mapa2.put('recordId', recordID);
    final PRW_SendEmailBuilder emailbuilder = new PRW_SendEmailBuilder();
    final Object content1 = emailbuilder.call('renderContent', mapa2);
    system.assertNotEquals(null, content1);
  }

  /**
  * @description
  * @author Global Hub | 2021-11-25
  **/
  @isTest
  static void renderTest3() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User userTest1 = utilTestClass.createUser(profileTest);
    userTest1.gf_pricing_gtb_type__c = true;
    insert userTest1;

    final Account acc = utilTestClass.createClient();
    insert acc;
    String recordID = 'PRW:::::[{"id":1,"product":"Adeudos - Conjunto adeudos","id_prod":"dypri.set","isDisabled":true},{"id":2,"product":"Transferencias emitidas - Transf. nacionales y EEE (eur, sek,ron) dest. otros bancos - Oficina","id_prod":"np.nat.transfer.EEE.ob.branch","isDisabled":true}]';
    recordID = recordID + ':::::' + acc.Id + ':::::undefined:::::undefined:::::false';
    final Map<String, String> mapa2 = new Map<String, String>();
    mapa2.put('recordId', recordID);
    final PRW_SendEmailBuilder emailbuilder = new PRW_SendEmailBuilder();
    system.runAs(userTest1) {
      final Object content1 = emailbuilder.call('isUserAllowed', mapa2);
      system.assert((Boolean)content1, 'notallowed');
    }
  }

  /**
  * @description
  * @author Global Hub | 2021-11-25
  **/
  @isTest
  static void renderTest4() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final String profileTest = utilTestClass.createProfile();
    final User userTest1 = utilTestClass.createUser(profileTest);
    userTest1.gf_pricing_gtb_type__c = true;
    insert userTest1;
	final Map<String, String> mapa1 = new Map<String, String>();
    final Map<String, Object> mapa2 = new Map<String, Object>();
    final Map<String, Object> mapaRecipients = new Map<String, Object>();
      mapaRecipients.put('to' , new List<String>{'test' , 'test2'});
    mapaRecipients.put('cc' , new List<String>{'test' , 'test2'});
    mapaRecipients.put('bcc' , new List<String>{'test' , 'test2'});
    mapa2.put('subject', 'test');
    mapa2.put('template', 'test');
    mapa2.put('targetObjectId', '');
    mapa2.put('recipients', mapaRecipients);
    mapa1.put('args' ,JSON.serialize(mapa2));
    final PRW_SendEmailBuilder emailbuilder = new PRW_SendEmailBuilder();
    system.runAs(userTest1) {
      final Object content1 = emailbuilder.call('sendEmail', mapa1);
      system.assert(!(Boolean)content1);
    }
  }
}