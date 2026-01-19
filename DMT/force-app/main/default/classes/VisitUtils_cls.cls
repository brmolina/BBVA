public without sharing class VisitUtils_cls  {
    /*
   * @author Global Desktop
   * @Description cuando se cambia de usuario el propietario anterior no pierde la visibilidad del registro
  */
  public void createShareOldOwner(List<dwp_kitv__Visit__c> news,List<dwp_kitv__Visit__c> olds) {
    
        final List<dwp_kitv__Visit__Share> lstMnlShrVisits = new List<dwp_kitv__Visit__Share>();
        final Desktop_Utils utilsHandler = Desktop_Utils.getInstance(); 
     
       for(Integer i=0;i<news.size();i++) {
           dwp_kitv__Visit__c visit=olds[i];
            system.debug('news[i].ownerid==========='+news[i].ownerid+'  olds[i].ownerid======'+olds[i].ownerid);
      
           if(news[i].ownerid!=olds[i].ownerid) {
               lstMnlShrVisits.add(utilsHandler.newManualSharingVisits(visit.Id, userInfo.getUserId(), 'Edit'));
           }
       }
       system.debug('==========='+lstMnlShrVisits);
       if(lstMnlShrVisits.size()>0&&!Test.isRunningTest()) {
          Database.insert(lstMnlShrVisits,false);
    
       }
    
    
   }
}