/// Base URL for the backend API.
const String apiBaseUrl = 'https://gatehub-api.hub360.pro/api';

/// Cloudinary account used to host property walkthrough videos directly
/// from the app (see lib/services/cloudinary_api.dart) - videos are far too
/// large to route through our own backend/database the way photos are.
/// Neither value is secret: both are meant to be embedded in the app and
/// only allow *unsigned* uploads through the preset configured in the
/// Cloudinary dashboard (Settings > Upload > Upload presets).
const String cloudinaryCloudName = 'm5ava4fy';
const String cloudinaryUploadPreset = 'cbjx3odf';

/// The public, no-login join-request form for a property (see
/// backend/public/invite.html) - what the "Invite Tenant" QR/link points
/// to. `apiBaseUrl` ends in `/api`; this page is served one level up.
String inviteUrlFor(String propertyId) {
  final apiUri = Uri.parse(apiBaseUrl);
  return apiUri.replace(path: '/invite', queryParameters: {'id': propertyId}).toString();
}
