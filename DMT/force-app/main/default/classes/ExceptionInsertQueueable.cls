/**
 * @description       : Queueable class to insert exceptions after DML work is committed
 * @author            : DMT Team
 * @last modified on  : 2026-04-23
 * @last modified by  : DMT Team
**/
public class ExceptionInsertQueueable implements Queueable {
    private List<DES_Exceptions__b> exceptions;
    @TestVisible private static Boolean forceInsertInTest = false;
    @TestVisible private static ExceptionInsertExecutor testExecutor;

    public interface ExceptionInsertExecutor {
        void insertRecords(List<DES_Exceptions__b> exceptions);
    }

    private class DefaultExceptionInsertExecutor implements ExceptionInsertExecutor {
        public void insertRecords(List<DES_Exceptions__b> exceptions) {
            Database.insertImmediate(exceptions);
        }
    }

    public ExceptionInsertQueueable(List<DES_Exceptions__b> exceptions) {
        this.exceptions = exceptions;
    }

    public void execute(QueueableContext context) {
        if (exceptions == null || exceptions.isEmpty()) {
            return;
        }

        if (!Test.isRunningTest() || forceInsertInTest) {
            try {
                ExceptionInsertExecutor executor = testExecutor == null
                    ? new DefaultExceptionInsertExecutor()
                    : testExecutor;
                executor.insertRecords(exceptions);
            } catch (Exception e) {
                System.debug('Failed to insert exceptions: ' + e.getMessage());
            }
        }
    }
}