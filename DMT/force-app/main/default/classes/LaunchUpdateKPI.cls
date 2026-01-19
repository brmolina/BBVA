/*
 controls that UpdateKPI is launched once and resolves future errors
*/
public class LaunchUpdateKPI {
    private static Boolean banKPI=false;
    public static Boolean getBanKPI() {
        return banKPI;
    }
    public static void ActivateBanKPI() {
        banKPI=true;
    }    
}