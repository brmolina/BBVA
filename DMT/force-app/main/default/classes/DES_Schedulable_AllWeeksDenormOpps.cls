global class DES_Schedulable_AllWeeksDenormOpps implements Schedulable{

  global void execute(SchedulableContext scMain) {
    //Denormalize de Opportunities
    system.debug('>>>>> Inicio Batch GBL_DenormalizeOpportunities ');
    final GBL_DenormalizeOppUtilsLocal oppUtil = new GBL_DenormalizeOppUtilsLocal();
    oppUtil.restore();
  }


}