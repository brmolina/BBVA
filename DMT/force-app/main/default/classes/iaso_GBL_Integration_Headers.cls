/**
* @description Implementing this interface, the framework accepts a header modification.
* The implemented class has to be provided in the parameter Header_class and will modify the HttpRequest to implement the modifications needed for the purpose of the target project
**/
public interface iaso_GBL_Integration_Headers {
  HttpRequest modifyRequest(HttpRequest request);
}