/// The areas of the app whose data comes from a repository.
enum AppFeature {
  auth,
  workspace,
  access,
  home,
  notifications,
  search,
  leads,
  tasks,
  calendar,
  cardScan,
  contacts,
  companies,
  customers,
  sales,
  collection,
  team,
  chat,
  files,
  settings,
  sync,
  reports,
  billing,
  referral,
  feedback,
  support,
  academy,
  fieldForce,
  growth,
  hr,
}

/// Features wired to the real API. Everything else runs on fake data.
const Set<AppFeature> liveFeatures = {};

bool isLive(AppFeature feature) => liveFeatures.contains(feature);
