// Node.js module resolution hook for SunOS (illumos).
// Intercepts packages that throw at import time on unsupported platforms
// and returns stubs so the CLI can start (with those features degraded).

const UNSUPPORTED_PLATFORM = process.platform === "sunos";

const STUBS = {
  "playwright-core": `
    export const chromium = null;
    export const devices = {};
    export default { chromium: null, devices: {} };
  `,
};

export async function resolve(specifier, context, nextResolve) {
  if (UNSUPPORTED_PLATFORM && specifier in STUBS) {
    return { url: `stub:${specifier}`, shortCircuit: true };
  }
  return nextResolve(specifier, context);
}

export async function load(url, context, nextLoad) {
  if (url.startsWith("stub:")) {
    const specifier = url.slice("stub:".length);
    return {
      format: "module",
      source: STUBS[specifier],
      shortCircuit: true,
    };
  }
  return nextLoad(url, context);
}
