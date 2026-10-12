import { defineRailway, postgres, preserve, project, service, volume } from "railway/iac";

export default defineRailway(() => {
  const Postgres = postgres("Postgres", { region: "europe-west4-drams3a" });
  Postgres.networking = { privateNetworkEndpoint: "postgres" };
  const postgresVolume = volume("postgres-volume", { alerts: { usage: { "100": {}, "80": {}, "95": {} } }, allowOnlineResize: true, region: "europe-west4-drams3a", sizeMB: 5000 });
  const api = service("api", {
    build: { buildEnvironment: "V3", builder: "DOCKERFILE", dockerfilePath: "backend/Dockerfile" },
    healthcheck: "/health",
    healthcheckTimeout: 120,
    replicas: { "europe-west4-drams3a": 1 },
    deploy: { restartPolicyMaxRetries: 5 },
    env: {
      DATABASE_URL: preserve(),
      // Every request needs a token (on since 2026-10-12, DEPLOY_CHECK.md).
      AUTH_REQUIRED: "true",
      // OpenRouteService key for routes and addresses (docs/MAPS.md): set in
      // the Railway dashboard, never in the repository.
      ORS_API_KEY: preserve(),
      // The client IP for the login rate limit: Railway's edge sets X-Real-IP
      // (and overwrites a forged one); its X-Forwarded-For lacks the client.
      CLIENT_IP_HEADER: "x-real-ip",
    },
  });

  return project("driver-shift-diary", {
    resources: [api, Postgres, postgresVolume],
  });
});
