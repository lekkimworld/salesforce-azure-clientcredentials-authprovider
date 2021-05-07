final HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Microsoft_Graph/users/foo@example.onmicrosoft.com');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json');
req.setMethod('GET');
final String body = new Http().send(req).getBody();
final Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(body);
System.debug('Users name is: ' + data.get('displayName'));
