import 'package:serverpod_auth_idp_server/providers/anonymous.dart';

/// By extending [AnonymousIdpBaseEndpoint], the anonymous identity provider endpoint
/// is made available on the server to allow guest authentication.
class AnonymousIdpEndpoint extends AnonymousIdpBaseEndpoint {}
