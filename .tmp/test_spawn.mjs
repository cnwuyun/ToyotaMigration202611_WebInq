import { spawnSync } from "node:child_process";

function run(cmd, args, options = {}) {
  const t0 = Date.now();
  const r = spawnSync(cmd, args, { encoding: "utf8", input: options.input, timeout: options.timeout });
  return {
    code: r.status,
    ms: Date.now() - t0,
    err: r.error ? String(r.error.message) : "",
    out: `${r.stdout ?? ""}${r.stderr ?? ""}`.slice(0, 120).replace(/\s+/g, " ")
  };
}

console.log("version", run("sql.exe", ["-v"], { timeout: 60000 }));
console.log("nolog", run("sql.exe", ["/nolog"], { input: "help apex\nexit\n", timeout: 60000 }));
