public with sharing class DMT_CreateQueueSObjectTypeFlow {

    public class Request {
        @InvocableVariable(required=true)
        public Id groupId;
        @InvocableVariable(required=true)
        public List<String> sObjectTypes;
    }

    public class Response {
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public String errorMessage;
    }
    
    @InvocableMethod(label='Create QueueSObjects' description='Create two QueueSObjects with the provided GroupId')
    public static List<Response> createQueueSObjects(List<Request> requests) {
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

        public void execute(QueueableContext context) {
                List<QueueSObject> queues = new List<QueueSObject>();
                for (Request request : requests) {
                    for (String sObjectType : request.sObjectTypes) {
                        QueueSObject queue = new QueueSObject();
                        queue.QueueId = request.groupId;
                        queue.SobjectType = sObjectType.trim();
                        queues.add(queue);
                    }
                }

                if (!queues.isEmpty()) {
                    insert queues;
                }    
        }
    }
}