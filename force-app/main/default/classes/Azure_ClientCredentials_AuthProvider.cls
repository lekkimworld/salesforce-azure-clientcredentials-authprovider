public class Azure_ClientCredentials_AuthProvider extends Auth.AuthProviderPluginClass {
    // constants
    public static final String CUSTOM_METADATA_TYPE = 'MicrosoftAzure_ClientCredentials__mdt';
    public static final String AUTH_PROVIDER_NAME = 'Azure_ClientCredentials';
    public static final String USERNAME = 'Azure Dummy User';

    // declarations
    private IRefreshTokenGenerator generator = new DefaultRefreshTokenGenerator();

    public Azure_ClientCredentials_AuthProvider() {
    }
    public Azure_ClientCredentials_AuthProvider(IRefreshTokenGenerator gen) {
        this.generator = gen;
    }

    public String getCustomMetadataType() {
        return CUSTOM_METADATA_TYPE;
    }

    public PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
        final String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        final String url = baseUrl + authProviderConfiguration.get('Callback_URL__c') + '?state=' + stateToPropagate;
        System.debug('initiate called - url <' + url + '>');
        return new PageReference(url);
    }

    public Auth.AuthProviderTokenResponse handleCallback(
        Map<String, String> config,
        Auth.AuthProviderCallbackState callbackState
    ) {
        System.debug('handleCallback');
        // get access token
        final String access_token = this.retrieveToken(config);
        final String refresh_token = this.generateRefreshToken();
        final String state = callbackState.queryParameters.get('state');
        return new Auth.AuthProviderTokenResponse(AUTH_PROVIDER_NAME, access_token, refresh_token, state);
    }

    public Auth.UserData getUserInfo(
        Map<String, String> authProviderConfiguration,
        Auth.AuthProviderTokenResponse response
    ) {
        return new Auth.UserData(
            null,
            null,
            null,
            null,
            null,
            null,
            USERNAME,
            null,
            AUTH_PROVIDER_NAME,
            null,
            new Map<String, String>()
        );
    }

    public override Auth.OAuthRefreshResult refresh(Map<String, String> config, String refreshToken) {
        // generate dummy refresh token and get new access token
        final String newRefreshToken = this.generateRefreshToken();
        final String access_token = this.retrieveToken(config);
        return new Auth.OAuthRefreshResult(access_token, newRefreshToken);
    }

    private String retrieveToken(Map<String, String> config) {
        final String tenantId = config.get('Tenant_ID__c');
        final String tokenEndpoint = 'https://login.microsoftonline.com/' + tenantId + '/oauth2/v2.0/token';
        final String body =
            'client_id=' +
            getAndEncode(config, 'Client_ID__c') +
            '&client_secret=' +
            getAndEncode(config, 'Client_Secret__c') +
            '&scope=' +
            getAndEncode(config, 'Scopes__c') +
            '&grant_type=client_credentials';
        System.debug('Token endpoint <' + tokenEndpoint + '>');
        System.debug('Body <' + body + '>');

        // setup request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(tokenEndpoint);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded;charset=UTF-8');
        req.setMethod('POST');
        req.setBody(body);

        // execute requets
        Http h = new Http();
        HttpResponse res = h.send(req);

        // get token from response
        return this.getTokenFromHttpResponse(res);
    }

    /**
     * Get the access_token from Http response.
     *
     */
    private String getTokenFromHttpResponse(HttpResponse res) {
        final Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        final String errorCode = (String) data.get('error');
        if (String.isNotEmpty(errorCode)) {
            String errorDesc = (String) data.get('error_description');
            throw new Azure_ClientCredentials_Exception(errorDesc)
                .setDetails(errorCode, (String) data.get('trace_id'), (String) data.get('correlation_id'));
        } else {
            return (String) data.get('access_token');
        }
    }

    private String getAndEncode(Map<String, String> config, String key) {
        return EncodingUtil.urlEncode(config.get(key), 'UTF-8');
    }

    private String generateRefreshToken() {
        return this.generator.generate();
    }

    public class Azure_ClientCredentials_Exception extends Exception {
        public String errorCode;
        public String traceId;
        public String correlationId;

        public Azure_ClientCredentials_Exception setDetails(String error_code, String trace_id, String correlation_id) {
            this.traceId = trace_id;
            this.correlationId = correlation_id;
            this.errorCode = error_code;
            return this;
        }
    }

    /**
     * Interface to allow us to override refresh token generation when testing.
     */
    public interface IRefreshTokenGenerator {
        String generate();
    }

    /**
     * Default implementation for runtime.
     */
    public class DefaultRefreshTokenGenerator implements IRefreshTokenGenerator {
        public String generate() {
            final String refreshToken = EncodingUtil.base64Encode(Crypto.generateAesKey(128));
            return refreshToken;
        }
    }
}
