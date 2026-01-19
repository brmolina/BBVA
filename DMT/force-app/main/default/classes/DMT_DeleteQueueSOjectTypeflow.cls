public without sharing class DMT_DeleteQueueSOjectTypeflow {

    public class Request {
        @InvocableVariable(required=true)
        public Group groupLst;
    }

    public class Response {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
    }

    @InvocableMethod(label='Delete QueueSObjects' description='Delete two QueueSObjects with the provided GroupId')
    public static List<Response> deleteQueueSObjects(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Integer i = 0; i < requests.size(); i++) {
            Response response = new Response();
            response.success = true;
            responses.add(response);
        }
        
        System.enqueueJob(new QueueSObjectProcessor(requests));

        return responses;

    }

    public class QueueSObjectProcessor implements Queueable {
        private List<Request> requests;

        public QueueSObjectProcessor(List<Request> requests) {
            this.requests = requests;
        }

        public void execute(QueueableContext context) 
        {
            List<Group> groupLst = new List<Group>();

            for (Request request : this.requests) 
            {
                if(request.groupLst != null)
                {
                    groupLst.add(request.groupLst);
                }    
            }

            if(!groupLst.isEmpty())
            {
                delete [SELECT Id FROM QueueSobject WHERE QueueId IN :groupLst];
                delete groupLst;
            }   
        }
    }
}