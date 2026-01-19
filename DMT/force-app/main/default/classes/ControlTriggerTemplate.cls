/*******
 control issure unlock template, avoid cycles in execution
*********/

public class ControlTriggerTemplate {

   private static Boolean activateAfterUpdate=false;
   private static Boolean activateBeforeUpdate=false;

   public static void setActivateAfterUpdate(){
       activateAfterUpdate=true;
   }

   public static Boolean validateActivateAfterUpdate(){
       return activateAfterUpdate;
   }

   public static void setActivateBeforeUpdate(){
       activateBeforeUpdate=true;
   }

   public static Boolean validateActivateBeforeUpdate(){
       return activateBeforeUpdate;
   }

}