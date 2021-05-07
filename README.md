# Salesforce Azure client_credentials Auth. Provider / Named Credentials

The `client_credentials` flow is an OAuth flow where an `access_token` is obtained from a `client_id` and `client_secret` without the need to a user to authorize the exchange. This flow is typically used for server to server integrations.

This project is an implementation of the Azure `client_credentials` OAuth flow for Salesforce using the `Auth.AuthProvider` interface (technically we extend the `Auth.AuthProviderPluginClass` class). Since the Auth. Providers in Salesforce usually deals with a user behind the keyboard it was designed for a `access_token` / `refresh_token` World. This implementation plays along and just requests a new `access_token` using the `client_credentials` flow whenever the `access_token` expires hence do not need a user behind the keyboard.

Once we have the Auth. Provider in place we can use the Salesforce Named Credentials approach where that is supported i.e. from Apex. Salesforce Named Credentials will transparently obtain and maintain a valid `access_token` when making requests from Salesforce to Azure (i.e. the Graph API) in places where Named Credentials may be used i.e. from Apex.

## What's in the box

This project contains the following:

1. Apex class for the Auth. Provider.
2. Remote Site Settings to allow communication with https://login.microsoftonline.com for the token endpoint and for https://graph.microsoft.com to communicate with the Microsoft Graph API. If you need access to other parts of Azure you need to add these as required.
3. A Custom Metadata Type for configuration of the Auth. Provider. The custom metadata type contains the `client_id`, `client_secret`, `tenant_id`, `callback_url` and `scopes` as required.

## What's NOT in the box

1. An actual Auth. Provider record. Create one using Salesforce Setup or use the metadata template in the `metadataTemplates` directory.
2. A Named Credential record for the AuthProvider. Create one using Salesforce Setup or use the metadata template in the `metadataTemplates` directory.

## Azure setup

To use the code in this project you need to create an App Registration in Azure Active Directory (AAD) and add client secrets to the application. Ensure you add the required Application Permissions to the App Registration and grant admin consent for the tenant.

The example in this README is for using the Microsoft Graph API.

## Salesforce setup

1. Deploy the source i.e. using Salesforce CLI (`sfdx force:source:deploy`)
2. Create an Auth. Provider in Setup of type `Microsoft_Azure_ClientCredentials`
3. Create a Named Credential using the "Named Principal" Identity Type, select "OAuth 2.0" for the Authentication Protocol and select the Auth. Provider you created above. On save you should see your browser go through the OAuth flow with Azure and you should see "Authenticated as Azure Dummy User". This username is hardcoded in the `Azure_ClientCredentials_AuthProvider.cls` Apex class - feel free to change if required.

## Use

The Auth. Provider may be used where ever Named Credentials can be used. Below is an example of using the Named Credential (here named "Microsoft_Graph") to get information about a user with the username `foo@dummy.onmicrosoft.com`. This is also in the file `scripts/apex/apex_namedcredentials_example.apex`.

```
final HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Microsoft_Graph/users/foo@example.onmicrosoft.com');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json');
req.setMethod('GET');
final String body = new Http().send(req).getBody();
final Map<String,Object> data = (Map<String,Object>)JSON.deserializeUntyped(body);
System.debug('Users name is: ' + data.get('displayName'));
```
