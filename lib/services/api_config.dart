/// Base URL for the backend API.
const String apiBaseUrl = 'https://gatehub-api.hub360.pro/api';

/// The public, no-login join-request form for a property (see
/// backend/public/invite.html) - what the "Invite Tenant" QR/link points
/// to. `apiBaseUrl` ends in `/api`; this page is served one level up.
String inviteUrlFor(String propertyId) {
  final apiUri = Uri.parse(apiBaseUrl);
  return apiUri.replace(path: '/invite', queryParameters: {'id': propertyId}).toString();
}
