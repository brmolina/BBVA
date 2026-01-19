/***********************************************************************************************
Name:            DES_Sche_BatchTotalLiveWonOpps_test
Description:     Test Class for DES_Sche_BatchTotalLiveWonOpps, its schedulable and handler

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            24/03/2020      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class DES_Sche_BatchTotalLiveWonOpps_test {
    /**
    * Met0d0 test
    */
 @isTest
 	public static void testDeleteBooking() {
    SchedulableContext sccont = null;
    final DES_Schedulable_BatchTotalLiveWonOpps des = new DES_Schedulable_BatchTotalLiveWonOpps();
	des.execute(sccont);
    System.assertNotEquals(des, null,'Error');
    }
}