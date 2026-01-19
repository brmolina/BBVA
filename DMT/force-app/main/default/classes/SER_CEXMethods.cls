/*-----------------------------
    Author:        Juan Carlos Terrón
    Company:       Accenture
    Description:   Class to handle SER_EUR_Currency_exchange_rate__c records

    History:
    <Date>          <Author>                <Description>
    12/07/2017		Juan Carlos Terrón		Initial Version
--------------------------------*/
public without sharing class SER_CEXMethods {
  /*--
      comment
  --*/
  private static final boolean BL_ERROR = false;
  /*-----------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Class to handle SER_EUR_Currency_exchange_rate__c records

      History:
      <Date>          <Author>                <Description>
      12/07/2017		Juan Carlos Terrón		Initial Version
  --------------------------------*/
  private SER_CEXMethods() {
    System.debug('Error');
    /** comment */
  }
  /*--------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to avoid duplicated unlisted currencies.

      IN:            List<SER_EUR_Currency_exchange_rate__c>(Trigger.news)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  --------------------------------*/
  public static void validateUnlistedCurrency(List<SER_EUR_Currency_exchange_rate__c> news) {
    final Set<String> setUnlCurren = new Set<String>();
    for(SER_EUR_Currency_exchange_rate__c cex : news) {
      System.debug('JCT - Filtro por unlisted : '+cex.SER_Unlisted__c);
      if(cex.SER_Unlisted__c) {
        if(setUnlCurren.contains(cex.SER_Counter_currency__c)) {
          //Error
          cex.addError(System.Label.SER_Duplicated_Unlisted_Currency);
        } else {
          setUnlCurren.add(cex.SER_Counter_currency__c);
        }
      }
    }
    boolean notNull;
    notnull = !BL_ERROR && setUnlCurren != null && !setUnlCurren.isEmpty();
    if(notnull) {
      final Set<String> set_CEX = new Set<String>();
      for(SER_EUR_Currency_exchange_rate__c cex :
          [
            select Id,SER_Counter_currency__c, SER_Unlisted__c
            from SER_EUR_Currency_exchange_rate__c
            where SER_Counter_currency__c in :setUnlCurren
            and SER_Unlisted__c = true
          ]) {
        System.debug('JCT - CEX que ya Existe : '+cex);
        set_CEX.add(cex.SER_Counter_currency__c);
      }
      boolean secNotNull;
      secNotNull = set_CEX != null && !set_CEX.isEmpty();
      if(secNotNull) {
        for(SER_EUR_Currency_exchange_rate__c cex : news) {
          if(set_CEX.contains(cex.SER_Counter_currency__c)) {
            System.debug('JCT - CEX que estoy comprobando : '+cex);
            cex.addError(System.Label.SER_Duplicated_Unlisted_Currency);
          }
        }
      }
    }
  }

  /*------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method to avoid duplicated unlisted currencies.

      IN:            List<SER_EUR_Currency_exchange_rate__c>(Trigger.news)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      12/07/2017				Juan Carlos Terrón		Initial Version
  ------------------------------------*/
  public static void validateUnlistedCurrency(Map<Id,SER_EUR_Currency_exchange_rate__c> newMap) {
    final Set<String> setUnlCurren = new Set<String>();
    for(SER_EUR_Currency_exchange_rate__c cex : newMap.values()) {
      System.debug('JCT - Filtro por unlisted : '+cex.SER_Unlisted__c);
      if(cex.SER_Unlisted__c) {
        if(setUnlCurren.contains(cex.SER_Counter_currency__c)) {
          //Error
          cex.addError(System.Label.SER_Duplicated_Unlisted_Currency);
        } else {
          setUnlCurren.add(cex.SER_Counter_currency__c);
        }
      }
    }
    boolean notNull;
    notNull = !BL_ERROR && setUnlCurren != null && !setUnlCurren.isEmpty();
    if(notNull) {
      final Set<String> set_CEX = new Set<String>();
      for(SER_EUR_Currency_exchange_rate__c cex :
          [
            select Id,SER_Counter_currency__c, SER_Unlisted__c
            from SER_EUR_Currency_exchange_rate__c
            where SER_Counter_currency__c in :setUnlCurren
            and Id not in :newMap.keyset()
            and SER_Unlisted__c = true
          ]) {
        System.debug('JCT - CEX que ya Existe - Currency : '+cex.SER_Counter_currency__c);
        System.debug('JCT - CEX que ya Existe - Unlisted : '+cex.SER_Unlisted__c);
        set_CEX.add(cex.SER_Counter_currency__c);
      }
      boolean secNotNull;
      secNotNull = set_CEX != null && !set_CEX.isEmpty();
      if(secNotNull) {
        for(SER_EUR_Currency_exchange_rate__c cex : newMap.values()) {
          if(set_CEX.contains(cex.SER_Counter_currency__c)) {
            System.debug('JCT - CEX que estoy comprobando : '+cex);
            cex.addError(System.Label.SER_Duplicated_Unlisted_Currency);
          }
        }
      }
    }
  }

  /*------------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method To Fix the daily upload , it changes the Processdate using the text field

      IN:            List<Cases>(Trigger.New)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      03/08/2017				Juan Carlos Terrón		Initial Version
  -----------------------------------------*/
  public static void assignProcessDate(List<SER_EUR_Currency_exchange_rate__c> news) {
    Date dtNewProcessDate;
    for(SER_EUR_Currency_exchange_rate__c cex : news) {
      if(     String.isNotBlank(cex.SER_Currency_Pair_Date__c)
              && cex.SER_Currency_Pair_Date__c.indexOf('_') != -1
              && String.isNotBlank(cex.SER_Currency_Pair_Date__c.substringAfter('_'))
              && cex.SER_Currency_Pair_Date__c.substringAfter('_').split('-') != null
              && !cex.SER_Currency_Pair_Date__c.substringAfter('_').split('-').isEmpty()
              ) {
        List<String> stDateParameters = new List<String>();
        final String stProcessDate =  cex.SER_Currency_Pair_Date__c.substringAfter('_');
        stDateParameters = stProcessDate.split('-');
        dtNewProcessDate = Date.newInstance(Integer.valueOf(stDateParameters[0]),Integer.valueOf(stDateParameters[1]),Integer.valueOf(stDateParameters[2]));
        cex.SER_Process_date__c = dtNewProcessDate;
      }
    }
  }

  /*---------------------------------
      Author:        Juan Carlos Terrón
      Company:       Accenture
      Description:   Method To Fix the daily upload , it changes the Processdate using the text field

      IN:            List<Cases>(Trigger.New)
      OUT:           void

      History:
      <Date>                  <Author>                <Change Description>
      03/08/2017				Juan Carlos Terrón		Initial Version
  ---------------------------------*/
  public static void assignProcessDate(Map<Id,SER_EUR_Currency_exchange_rate__c> newMap, Map<Id,SER_EUR_Currency_exchange_rate__c> oldMap) {
    Date dtNewProcessDate;
    for(SER_EUR_Currency_exchange_rate__c cex : newMap.values()) {
      /*-- No se usa SER_EUR_Currency_exchange_rate__c OLDCEX = oldMap.get(cex.Id); --*/
      if(     String.isNotBlank(cex.SER_Currency_Pair_Date__c)
              && cex.SER_Currency_Pair_Date__c.indexOf('_') != -1
              && String.isNotBlank(cex.SER_Currency_Pair_Date__c.substringAfter('_'))
              && cex.SER_Currency_Pair_Date__c.substringAfter('_').split('-') != null
              && !cex.SER_Currency_Pair_Date__c.substringAfter('_').split('-').isEmpty()
              ) {
        List<String> stDateParameters = new List<String>();
        final String stProcessDate =  cex.SER_Currency_Pair_Date__c.substringAfter('_');
        stDateParameters = stProcessDate.split('-');
        dtNewProcessDate = Date.newInstance(Integer.valueOf(stDateParameters[0]),Integer.valueOf(stDateParameters[1]),Integer.valueOf(stDateParameters[2]));
        cex.SER_Process_date__c = dtNewProcessDate;
      }
    }
  }
}