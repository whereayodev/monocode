// Personal builds of this fork: the app.json config, with the identifiers
// swapped for your own when these are set (see PERSONAL_BUILDS.md).
//
//   MONOCODE_BUNDLE_ID      your bundle identifier, e.g. com.you.monocode
//   MONOCODE_APPLE_TEAM_ID  your Apple Developer team ID
//   MONOCODE_EAS_OWNER      your Expo account (EAS builds only)
//   MONOCODE_EAS_PROJECT_ID your EAS project ID (EAS builds and updates only)
//   MONOCODE_BUILD_NUMBER   the build number TestFlight sees; each upload needs a new one
//
// Unset, the config is app.json's as it is.
module.exports = ({ config }) => {
  const env = process.env;
  const next = { ...config, ios: { ...config.ios } };
  if (env.MONOCODE_BUNDLE_ID) next.ios.bundleIdentifier = env.MONOCODE_BUNDLE_ID;
  if (env.MONOCODE_APPLE_TEAM_ID) next.ios.appleTeamId = env.MONOCODE_APPLE_TEAM_ID;
  if (env.MONOCODE_BUILD_NUMBER) next.ios.buildNumber = env.MONOCODE_BUILD_NUMBER;
  if (env.MONOCODE_EAS_OWNER) next.owner = env.MONOCODE_EAS_OWNER;
  if (env.MONOCODE_EAS_PROJECT_ID) {
    next.extra = { ...config.extra, eas: { ...config.extra?.eas, projectId: env.MONOCODE_EAS_PROJECT_ID } };
    next.updates = { ...config.updates, url: `https://u.expo.dev/${env.MONOCODE_EAS_PROJECT_ID}` };
  } else if (env.MONOCODE_BUNDLE_ID) {
    // Upstream's EAS project can't serve updates to another app: a personal
    // build without its own EAS project ships without over-the-air updates.
    next.updates = { ...config.updates, enabled: false };
    next.extra = { ...config.extra, eas: {} };
  }
  return next;
};
