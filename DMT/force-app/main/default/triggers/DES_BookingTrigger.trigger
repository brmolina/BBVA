trigger DES_BookingTrigger on DES_Booking__c (before insert, after update, after insert, after delete) {
     
    
    if(trigger.isBefore){
        if(trigger.isInsert){
            //List<DES_Booking__c> listBookings = new List<DES_Booking__c>([SELECT Id, DES_Client__c FROM DES_Booking__c]);
            //delete listBookings;
            //DES_BookingTriggerHandler.identifyYearOfBooking(trigger.new);
        }
    }
    
    if(trigger.isAfter){
        /*if (Trigger.isUpdate){
            //DES_BookingTriggerHandler.calculateClientRevenues(Trigger.new, Trigger.oldMap);
            DES_BookingTriggerHandler.calcularRevenues(trigger.new);
        }*/
        if(trigger.isInsert || trigger.isUpdate){
            //DES_BookingTriggerHandler.calcularRevenues(trigger.new);    
        }
        if(trigger.isDelete){
            //DES_BookingTriggerHandler.limpiarDatos(trigger.old);
        }
        
    }
    
    
      
}