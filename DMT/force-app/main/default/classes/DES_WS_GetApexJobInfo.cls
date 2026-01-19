@RestResource(urlMapping='/getApexJobInfo/*')
global with sharing class DES_WS_GetApexJobInfo {//NOSONAR

    @HttpGet
    global static WrapperClass getApexJob(){//NOSONAR

        Id jobId = (Id)RestContext.request.params.get('jobId')/* + '%'*/;
	    System.debug('>>>>> jobId : ' + jobId);

	    List<AsyncApexJob> listJobs = new List<AsyncApexJob>([
	    					SELECT 	Id,
							 		ApexClass.Name,
	    							Status,
	    							NumberOfErrors,
	    							JobItemsProcessed,
	    							TotalJobItems,
									CreatedDate
	    					FROM AsyncApexJob
	    					WHERE Id = :jobId
	    ]);
    	System.debug('>>>>> listJobs : ' + listJobs);

        Integer totalJobItems = 0;
        Integer jobItemsProcessed = 0;
        Integer numberOfErrors = 0;

		AsyncApexJob job;
    	if(!listJobs.isEmpty())	{
    		job = listJobs.get(0);
            if(job != null) {
                totalJobItems += job.TotalJobItems;
                jobItemsProcessed += job.JobItemsProcessed;
                numberOfErrors += job.NumberOfErrors;
            }
			if(job != null && job.Status == 'Completed' && listJobs.get(0).ApexClass.Name == 'DES_Batch_EliminarBBVAMember' && listJobs.get(0).TotalJobItems != 0) {
				job = getNext(job, 'Batch_DeleteOppShare');
                if(job != null) {//NOSONAR
                    totalJobItems += job.TotalJobItems;
                    jobItemsProcessed += job.JobItemsProcessed;
                    numberOfErrors += job.NumberOfErrors;
                }
				if(job != null && job.Status == 'Completed' && job.ApexClass.Name == 'Batch_DeleteOppShare') {//NOSONAR
					job = getNext(job, 'BATCH_DeleteVisitShare');
                    if(job != null) {
                        totalJobItems += job.TotalJobItems;
                        jobItemsProcessed += job.JobItemsProcessed;
                        numberOfErrors += job.NumberOfErrors;
                    }
					if(job != null && job.Status == 'Completed' && job.ApexClass.Name == 'BATCH_DeleteVisitShare') {//NOSONAR
						job = getNext(job, 'BATCH_DeleteAlertShare');
						if(job != null) {
							totalJobItems += job.TotalJobItems;
							jobItemsProcessed += job.JobItemsProcessed;
							numberOfErrors += job.NumberOfErrors;
						}
					}
					if(job != null && job.Status == 'Completed' && job.ApexClass.Name == 'BATCH_DeleteAlertShare') {
						job = getNext(job, 'BATCH_DeleteAlertTeam');
						if(job != null) {
							totalJobItems += job.TotalJobItems;
							jobItemsProcessed += job.JobItemsProcessed;
							numberOfErrors += job.NumberOfErrors;
						}
					}
				}
			}
		}

    	System.debug('>>>>> job : (' + (job == null ?  'null' : job.ApexClass.Name) + ') ' + job);

		String idResult;
		String statusResult;
		if (job == null) {
			idResult = jobId;
			statusResult = 'Processing';
		} else {
			idResult = job.id;
			statusResult = job.Status;
		}
        WrapperClass result;
		result = new WrapperClass(idResult, statusResult, totalJobItems, jobItemsProcessed, numberOfErrors);
    	System.debug('>>>>> result : ' + result);
		return result;
    }

	private static AsyncApexJob getNext (AsyncApexJob previousJob, String className) {
		AsyncApexJob job;
		List<AsyncApexJob> listJobs;
		listJobs = new List<AsyncApexJob>([
				SELECT 	Id,
						ApexClass.Name,
						Status,
						NumberOfErrors,
						JobItemsProcessed,
						TotalJobItems,
						CreatedDate
				FROM AsyncApexJob
				WHERE CreatedDate >= :previousJob.CreatedDate AND ApexClass.Name = :className
				ORDER BY CreatedDate DESC
		]);
		if(!listJobs.isEmpty())	{
			job = listJobs.get(0);
		}
    	return job;
	}

    /**
    *
    * Clase necesaria para devolver al webservice
    */
    global class WrapperClass {//NOSONAR
        /*
        * idBatch para crear el idBatch
         */
        String Id;//NOSONAR
        /*
        * statusBatch para crear el statusBatch
         */
        String Status;//NOSONAR
        /*
        * totalJobItems para crear el totalJobItems
         */
        Integer TotalJobItems;//NOSONAR
        /*
        * jobItemsProcessed para crear el jobItemsProcessed
         */
        Integer JobItemsProcessed;//NOSONAR
        /*
        * numberOfErrors para crear el numberOfErrors
         */
        Integer NumberOfErrors;//NOSONAR

        /*
        * Met0d0 para crear el wrapp
         */
		global WrapperClass(Id idB, String statusB, Integer totalJobItems, Integer jobItemsProcessed, Integer numberOfErrors) {
			this.Id = idB;
            this.Status = statusB;
			this.totalJobItems = totalJobItems;
            this.jobItemsProcessed = jobItemsProcessed;
			this.numberOfErrors = numberOfErrors;
		}

	}

}