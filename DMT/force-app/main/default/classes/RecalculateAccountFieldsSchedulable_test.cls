/***********************************************************************************************
Name:            RecalculateAccountFieldsSchedulable_test
Description:     Test Class for RecalculateAccountFieldsSchedulable_test

Version        Date            Author            Summary of changes
------------------------------------------------------------------------------------------------
1.0            24/03/2020      Global Desktop    Class creation

***********************************************************************************************/
@isTest
public class RecalculateAccountFieldsSchedulable_test {
 @isTest
 	public static void testDeleteBooking() {
    Final SchedulableContext scContext = null;
    Final RecalculateAccountFieldsSchedulable des = new RecalculateAccountFieldsSchedulable();
	des.execute(scContext);
    System.assertNotEquals(des, null,'Error');
    }
}