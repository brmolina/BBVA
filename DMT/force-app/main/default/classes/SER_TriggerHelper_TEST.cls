@isTest
/*------------------------------------------------------------------------------
        Author:
        Company:
        Description:   SER_TriggerHelper_TEST
--------------------------------------------------------------------------------*/
private class SER_TriggerHelper_TEST {
  /*Constante booleana con el valor TRUE*/
  final static boolean TRU = true;
  /*Constante booleana con el valor FALSE*/
  final static boolean FAL = false;
  @isTest static void testGetTriggerFired() {

    SER_TriggerHelper.mapFiredTriggers.put('Trigger_1_get', Boolean.valueOf(TRU));
    SER_TriggerHelper.mapFiredTriggers.put('Trigger_2_get', Boolean.valueOf(FAL));
    SER_TriggerHelper.mapFiredTriggers.put('Trigger_3_get', Boolean.valueOf(FAL));

    SER_TriggerHelper.mapFiredMethods.put('Method_3_get', Boolean.valueOf(FAL));
    SER_TriggerHelper.mapFiredMethods.put('Method_2_get', Boolean.valueOf(TRU));
    SER_TriggerHelper.mapFiredMethods.put('Method_1_get', Boolean.valueOf(FAL));

    final Boolean resp0 = SER_TriggerHelper.getTriggerFired('Trigger_1');
    System.debug('Primer test testGetTriggerFired (true) -> '+ resp0);

    final Boolean resp1 = SER_TriggerHelper.getTriggerFired('Trigger_7');
    System.assertEquals(resp1, FAL, 'testGetTriggerFired_Trigger_7');
    System.debug('Segundo test testGetTriggerFired (false) -> '+ resp1);
  }

  @isTest static void testSetTriggerFired() {

    SER_TriggerHelper.mapFiredTriggers.put('trigger_1_set', Boolean.valueOf(TRU));
    SER_TriggerHelper.mapFiredTriggers.put('trigger_2_set', Boolean.valueOf(FAL));
    SER_TriggerHelper.mapFiredTriggers.put('trigger_3_set', Boolean.valueOf(FAL));

    SER_TriggerHelper.mapFiredMethods.put('Method_3_set', Boolean.valueOf(FAL));
    SER_TriggerHelper.mapFiredMethods.put('Method_2_set', Boolean.valueOf(TRU));
    SER_TriggerHelper.mapFiredMethods.put('Method_1_set', Boolean.valueOf(FAL));

    SER_TriggerHelper.setTriggerFired('TRIgger_2', Boolean.valueOf(false));

    SER_TriggerHelper.setTriggerFired('Trigger_7', Boolean.valueOf(TRU));

    final Boolean resp1 = SER_TriggerHelper.getTriggerFired('Trigger_7');
    System.assertEquals(resp1,FAL, 'testSetTriggerFired');
  }

  @isTest static void testGetMethodFired() {

    SER_TriggerHelper.mapFiredTriggers.put('trigger_1', Boolean.valueOf(TRU));
    SER_TriggerHelper.mapFiredTriggers.put('trigger_2', Boolean.valueOf(FAL));
    SER_TriggerHelper.mapFiredTriggers.put('trigger_3', Boolean.valueOf(FAL));

    SER_TriggerHelper.mapFiredMethods.put('Method_1', Boolean.valueOf(FAL));
    SER_TriggerHelper.mapFiredMethods.put('Method_3', Boolean.valueOf(TRU));
    SER_TriggerHelper.mapFiredMethods.put('Method_2', Boolean.valueOf(FAL));

    final Boolean resp0 = SER_TriggerHelper.get_MethodFired('Method_2');
    System.debug('Primer test getMethodFired (true) -> '+ resp0);
    final Boolean resp1 = SER_TriggerHelper.get_MethodFired('Method_55');
    System.debug('Primer test getMethodFired (false) -> '+ resp1);
    System.assertEquals(resp1,FAL, 'testGetMethodFired_Method_55');

  }

  @isTest static void testSetMetodFired() {

    SER_TriggerHelper.mapFiredMethods.put('method_1', Boolean.valueOf('false'));
    SER_TriggerHelper.mapFiredMethods.put('method_3', Boolean.valueOf('true'));
    SER_TriggerHelper.mapFiredMethods.put('method_2', Boolean.valueOf('false'));

    SER_TriggerHelper.set_MetodFired('Method_1', Boolean.valueOf('false'));

    SER_TriggerHelper.set_MetodFired('MeTHOd_66', Boolean.valueOf('true'));
    final Boolean resp0 = SER_TriggerHelper.get_MethodFired('MeTHOd_66');
    System.assertEquals(resp0,TRU, 'testSetMetodFired_Method_66');
  }
}