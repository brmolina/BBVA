@IsTest
public class DMT_DefaultParticipantRendererTest {

    private static DMT_TeamMember__c buildMember(String fullName, String accessLevel) {
        String memberJson = '{"AccessLevel__c":"' + accessLevel + '","Full_Name_User__c":"' + fullName + '"}';
        return (DMT_TeamMember__c) JSON.deserialize(memberJson, DMT_TeamMember__c.class);
    }

    @IsTest
    static void testNullData() {
        DMT_DefaultParticipantRenderer renderer = new DMT_DefaultParticipantRenderer();
        String result = renderer.renderHtml(null);
        Assert.isTrue(result.contains('Participants data not provided'), 'Null data must return guard message.');
    }

    @IsTest
    static void testEmptyParticipantList() {
        DMT_DefaultParticipantRenderer renderer = new DMT_DefaultParticipantRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Participants data not provided'), 'Empty participantList must return guard message.');
    }

    @IsTest
    static void testWithSingleParticipant() {
        DMT_DefaultParticipantRenderer renderer = new DMT_DefaultParticipantRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.participantList = new List<DMT_TeamMember__c>{ buildMember('Test User', 'Edit') };
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'Result must not be null.');
        Assert.isTrue(result.contains('Participants'), 'Result should include the Participants header.');
        Assert.isTrue(result.contains('Test User'), 'Result should render the participant name.');
        Assert.isTrue(result.contains('Edit'), 'Result should render the access level.');
    }

    @IsTest
    static void testWithMultipleParticipants() {
        DMT_DefaultParticipantRenderer renderer = new DMT_DefaultParticipantRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.participantList = new List<DMT_TeamMember__c>{
            buildMember('Alice', 'Edit'),
            buildMember('Bob', 'Read')
        };
        String result = renderer.renderHtml(data);
        Assert.isTrue(result.contains('Alice'), 'First participant should be rendered.');
        Assert.isTrue(result.contains('Bob'), 'Second participant should be rendered.');
        Assert.isTrue(result.contains('Read'), 'Second participant access level should be rendered.');
    }

    @IsTest
    static void testWithNullFieldsInParticipant() {
        DMT_DefaultParticipantRenderer renderer = new DMT_DefaultParticipantRenderer();
        DMT_ViewController.LineDataWrapper data = new DMT_ViewController.LineDataWrapper();
        data.participantList = new List<DMT_TeamMember__c>{ new DMT_TeamMember__c() };
        String result = renderer.renderHtml(data);
        Assert.isNotNull(result, 'Null participant fields should not crash the renderer.');
        Assert.isTrue(!result.contains('Error:'), 'Null fields should render gracefully without error div.');
    }
}