/**
* ------------------------------------------------------------------------------------------------
* @Name     PRW_SendBundleEmailTest
* @Author   Global Hub
* @Date     Created: 2022-07-13
* ------------------------------------------------------------------------------------------------
* @Description Test class for PRW_SendBundleEmailBuilder
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2022-07-13 ivan.garces.contractor@bbva.com
*             Class Creation
* -----------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class PRW_SendBundleEmailTest {
  /**
  * @description
  * @author Global Hub | 2022-07-13
  **/
  @isTest
  static void renderTest() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account acc = utilTestClass.createClient();
    insert acc;
    String recordID = 'BND:::::"400 €"';
    recordID = recordID +':::::undefined:::::undefined:::::undefined:::::undefined:::::[{"bndleProduct":"international_transfers_issued","q"';
    recordID = recordID +':"5"},{"bndleProduct":"sepa_transfers_issued","q":"1.130"},{"bndleProduct":"total_payrolls","q":"215"}]:::::[{"bndleProductAdded":"Gastos de Correo",';
    recordID = recordID + '"id_prod":"np.transfer.mail.expenses","p":"-1,0000 €","q":"-1","pNumber":-1,"qNumber":-1},{"bndleProductAdded":"Transf. nacionales dest. BBVA (traspasos';
    recordID = recordID + 'exentos) - Oficina","id_prod":"np.nat.transfer.BBVA.branch","p":"1,6108 €","q":"74,175","pNumber":1.6108388980450379,"qNumber":74.17479674796748},{"bndleP';
    recordID = recordID + 'roductAdded":"Transf. nacionales dest. BBVA (traspasos exentos) - Telemát. y Fichero","id_prod":"np.nat.transfer.BBVA.tf","p":"0,1632 €","q":"13.483","pNum';
    recordID = recordID + 'ber":0.16323122016136019,"qNumber":13483},{"bndleProductAdded":"Transf. nacionales y EEE (eur, sek,ron) dest. otros bancos - Oficina","id_prod":"np.nat.tra';
    recordID = recordID + 'nsfer.EEE.ob.branch","p":"0,0100 €","q":"69,451","pNumber":0.009999999776482582,"qNumber":69.45138888888889},{"bndleProductAdded":"Transf. nacionales y EEE';
    recordID = recordID + ' (eur,sek,ron) dest. otros bancos - Telemát. y Fichero","id_prod":"np.nat.transfer.EEE.ob.tf","p":"0,4704 €","q":"12.291","pNumber":0.4703859838449116,"qNu';
    recordID = recordID + 'mber":12291}]';
    final Map<String, String> mapa = new Map<String, String>();
    mapa.put('recordId', recordID);
    final PRW_SendBundleEmailBuilder emailbuilder = new PRW_SendBundleEmailBuilder();
    final Object content = emailbuilder.call('getContent', mapa);
    final Object recipients = emailbuilder.call('getRecipients', mapa);
    system.assertNotEquals(null, content);
  }

  /**
  * @description
  * @author Global Hub | 2022-07-13
  **/
  @isTest
  static void renderTest1() {
    final DES_UtilTestClass utilTestClass = new DES_UtilTestClass();
    final Account acc = utilTestClass.createClient();
    insert acc;
    List<Map<String,String>> listBundles = new List<Map<String,String>>();
    String recordID = 'BND:::::"400 €"';
    recordID = recordID +':::::undefined:::::undefined:::::undefined:::::undefined:::::[{"bndleProduct":"international_transfers_issued","q"';
    recordID = recordID +':"5"},{"bndleProduct":"sepa_transfers_issued","q":"1.130"},{"bndleProduct":"total_payrolls","q":"215"}]:::::[{"bndleProductAdded":"Gastos de Correo",';
    recordID = recordID + '"id_prod":"np.transfer.mail.expenses","p":"-1,0000 €","q":"-1","pNumber":-1,"qNumber":-1},{"bndleProductAdded":"Transf. nacionales dest. BBVA (traspasos';
    recordID = recordID + 'exentos) - Oficina","id_prod":"np.nat.transfer.BBVA.branch","p":"1,6108 €","q":"74,175","pNumber":1.6108388980450379,"qNumber":74.17479674796748},{"bndleP';
    recordID = recordID + 'roductAdded":"Transf. nacionales dest. BBVA (traspasos exentos) - Telemát. y Fichero","id_prod":"np.nat.transfer.BBVA.tf","p":"0,1632 €","q":"13.483","pNum';
    recordID = recordID + 'ber":0.16323122016136019,"qNumber":13483},{"bndleProductAdded":"Transf. nacionales y EEE (eur, sek,ron) dest. otros bancos - Oficina","id_prod":"np.nat.tra';
    recordID = recordID + 'nsfer.EEE.ob.branch","p":"0,0100 €","q":"69,451","pNumber":0.009999999776482582,"qNumber":69.45138888888889},{"bndleProductAdded":"Transf. nacionales y EEE';
    recordID = recordID + ' (eur,sek,ron) dest. otros bancos - Telemát. y Fichero","id_prod":"np.nat.transfer.EEE.ob.tf","p":"0,4704 €","q":"12.291","pNumber":0.4703859838449116,"qNu';
    recordID = recordID + 'mber":12291}]';
    final String args = '{"selectedIds":["sigblock-'+UserInfo.getUserId()+'"]}';
    final Map<String, String> mapa2 = new Map<String, String>();
    mapa2.put('args', args);
    mapa2.put('recordId', recordID);
    final PRW_SendBundleEmailBuilder emailbuilder = new PRW_SendBundleEmailBuilder();
    final Object content1 = emailbuilder.call('renderContent', mapa2);
    system.assertNotEquals(null, content1);
  }

  /**
  * @description
  * @author Global Hub | 2022-07-13
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
    List<Map<String,String>> listBundles = new List<Map<String,String>>();

    String recordID = 'BND:::::"400 €":';
    recordID =recordID + '::::'+acc.Id + ':::::'+acc2.Id+'-'+acc3.Id+ 'undefined:::::[{"bndleProduct":"international_transfers_issued","q":"5"},{"bndlePro';
    recordID =recordID + 'duct":"sepa_transfers_issued","q":"1.130"},{"bndleProduct":"total_payrolls","q":"215"}]:::::'+JSON.serialize(listBundles);
    final String args = '{"selectedIds":["sigblock-'+UserInfo.getUserId()+'"]}';
    final Map<String, String> mapa2 = new Map<String, String>();
    mapa2.put('args', args);
    mapa2.put('recordId', recordID);
    final PRW_SendBundleEmailBuilder emailbuilder = new PRW_SendBundleEmailBuilder();
    final Object content1 = emailbuilder.call('renderContent', mapa2);
    system.assertNotEquals(null, content1);
  }

  /**
  * @description
  * @author Global Hub | 2022-07-13
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
    List<Map<String,String>> listBundles = new List<Map<String,String>>();

    String recordID = 'BND:::::"400 €":';
    recordID =recordID + '::::'+ acc.Id + ':::::'+'undefined'+ 'undefined:::::[{"bndleProduct":"international_transfers_issued","q":"5"},{"bndlePro';
    recordID =recordID + 'duct":"sepa_transfers_issued","q":"1.130"},{"bndleProduct":"total_payrolls","q":"215"}]:::::'+JSON.serialize(listBundles);
    final String args = '{"selectedIds":["sigblock-'+UserInfo.getUserId()+'"]}';

    final Map<String, String> mapa2 = new Map<String, String>();
    mapa2.put('recordId', recordID);
    final PRW_SendBundleEmailBuilder emailbuilder = new PRW_SendBundleEmailBuilder();
    system.runAs(userTest1) {
      final Object content1 = emailbuilder.call('isUserAllowed', mapa2);
      system.assert((Boolean)content1, 'notallowed');
    }
  }

  /**
  * @description
  * @author Global Hub | 2022-07-13
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
    final PRW_SendBundleEmailBuilder emailbuilder = new PRW_SendBundleEmailBuilder();
    system.runAs(userTest1) {
      final Object content1 = emailbuilder.call('sendEmail', mapa1);
      system.assert(!(Boolean)content1);
    }
  }
}