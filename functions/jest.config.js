/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  testMatch: ["<rootDir>/test/**/*.test.ts"],
  testTimeout: 30000,
  setupFiles: ["<rootDir>/test/setup.ts"],
};
