public class TriggerBypass {
    
    public static Boolean bypassTrigger = false;

    public static void setBypass() {
        bypassTrigger = true;
    }

    public static void removeBypass() {
        bypassTrigger = false;
    }
}