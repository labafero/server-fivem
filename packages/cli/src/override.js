import { execFileSync } from "node:child_process";
import { existsSync, cpSync, mkdirSync, rmSync, readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "../../..");
const BACKUP_ROOT = join(REPO_ROOT, ".labafero", "backups");

export class OverrideBuildError extends Error {}

function readJson(path, label) {
  if (!existsSync(path)) {
    throw new OverrideBuildError(`${label} não encontrado: ${path}`);
  }
  let raw;
  try {
    raw = readFileSync(path, "utf8");
  } catch (err) {
    throw new OverrideBuildError(`Falha ao ler ${label} (${path}): ${err.message}`);
  }
  try {
    return JSON.parse(raw);
  } catch (err) {
    throw new OverrideBuildError(`${label} contém JSON inválido (${path}): ${err.message}`);
  }
}

function buildPackage(packageDir, routeId) {
  const packageJsonPath = join(packageDir, "package.json");
  const packageJson = readJson(packageJsonPath, `package.json da rota "${routeId}"`);
  const packageName = packageJson.name;
  if (!packageName) {
    throw new OverrideBuildError(
      `package.json em ${packageJsonPath} não define "name" (rota "${routeId}")`,
    );
  }

  console.log(`[${routeId}] buildando ${packageName}...`);
  try {
    execFileSync("pnpm", ["--filter", packageName, "build"], {
      cwd: REPO_ROOT,
      stdio: "inherit",
    });
  } catch (err) {
    throw new OverrideBuildError(
      `Build do pacote "${packageName}" falhou (rota "${routeId}"): ${err.message}`,
    );
  }
}

// Um valor em target.files/target.dirs pode ser uma string (caminho relativo
// obrigatório no dist/ do pacote) ou um objeto { path, optional } —
// "optional" marca entradas que ainda não foram fornecidas (ex. assets de
// mídia autorais que o usuário vai colocar depois) e que não devem quebrar o
// build/restore enquanto estiverem ausentes.
function normalizeEntry(value) {
  if (typeof value === "string") {
    return { path: value, optional: false };
  }
  if (value && typeof value === "object" && typeof value.path === "string") {
    return { path: value.path, optional: Boolean(value.optional) };
  }
  return null;
}

function validateEntryMap(label, mapLabel, map, required) {
  if (!map || typeof map !== "object" || Array.isArray(map)) {
    if (required) {
      throw new OverrideBuildError(`${label} não define "${mapLabel}" (objeto) em labafero.json.`);
    }
    return;
  }
  if (required && Object.keys(map).length === 0) {
    throw new OverrideBuildError(
      `${label} não define "${mapLabel}" (objeto não vazio) em labafero.json.`,
    );
  }
  for (const [destName, value] of Object.entries(map)) {
    if (!normalizeEntry(value)) {
      throw new OverrideBuildError(
        `${label}: "${mapLabel}['${destName}']" deve ser uma string ou um objeto { path, optional } em labafero.json.`,
      );
    }
  }
}

function validateRoute(route, index) {
  const label = route && typeof route.id === "string" ? `rota "${route.id}"` : `rota #${index}`;

  if (!route || typeof route !== "object") {
    throw new OverrideBuildError(`${label} em labafero.json não é um objeto válido.`);
  }
  if (typeof route.id !== "string" || route.id.length === 0) {
    throw new OverrideBuildError(`${label} em labafero.json não define "id" (string).`);
  }
  if (typeof route.package !== "string" || route.package.length === 0) {
    throw new OverrideBuildError(`${label} não define "package" (string) em labafero.json.`);
  }
  if (!route.target || typeof route.target !== "object") {
    throw new OverrideBuildError(`${label} não define "target" (objeto) em labafero.json.`);
  }
  if (typeof route.target.resource !== "string" || route.target.resource.length === 0) {
    throw new OverrideBuildError(`${label} não define "target.resource" (string) em labafero.json.`);
  }
  validateEntryMap(label, "target.files", route.target.files, true);
  validateEntryMap(label, "target.dirs", route.target.dirs, false);
}

// Backup é por-entrada (não por-rota): cada arquivo/diretório mapeado guarda
// seu próprio snapshot na primeira vez que é sobrescrito. Isso permite mapear
// entradas novas numa rota já existente sem precisar migrar backups antigos —
// só a entrada nova ganha um snapshot na próxima build.
function ensureBackup(route) {
  const { id, target } = route;
  const targetDir = join(REPO_ROOT, target.resource);
  const backupDir = join(BACKUP_ROOT, id);

  for (const destFileName of Object.keys(target.files ?? {})) {
    const backupPath = join(backupDir, destFileName);
    if (existsSync(backupPath)) {
      continue;
    }
    const currentPath = join(targetDir, destFileName);
    if (!existsSync(currentPath)) {
      continue;
    }
    mkdirSync(dirname(backupPath), { recursive: true });
    cpSync(currentPath, backupPath);
    console.log(`[${id}] backup do original salvo: ${destFileName}`);
  }

  // target.dirs é exclusivo pra conteúdo autoral do Labafero (nunca um
  // diretório vendorizado do QBCore) — não existe "original" pra preservar,
  // então não tem backup. restoreRoute() sempre remove esses diretórios.
}

function restoreRoute(route) {
  const { id, target } = route;
  const targetDir = join(REPO_ROOT, target.resource);
  const backupDir = join(BACKUP_ROOT, id);

  for (const [destFileName, rawEntry] of Object.entries(target.files ?? {})) {
    const { optional } = normalizeEntry(rawEntry);
    const backupPath = join(backupDir, destFileName);

    if (!existsSync(backupPath)) {
      if (optional) {
        console.log(`[${id}] sem backup pra "${destFileName}" (opcional) — pulando.`);
        continue;
      }
      throw new OverrideBuildError(
        `Backup não encontrado pra "${destFileName}" (rota "${id}"): ${backupPath}. ` +
          `Rode "override:build" pelo menos uma vez antes de restaurar, ou reinstale o resource original via ./scripts/install-qbcore.sh.`,
      );
    }

    const destPath = join(targetDir, destFileName);
    mkdirSync(dirname(destPath), { recursive: true });
    cpSync(backupPath, destPath);
    console.log(`[${id}] restaurado: ${destFileName}`);
  }

  // target.dirs nunca tem backup (ver ensureBackup) — restaurar significa
  // simplesmente remover o que o Labafero adicionou, voltando o resource pro
  // estado vendorizado puro.
  for (const destDirName of Object.keys(target.dirs ?? {})) {
    const destPath = join(targetDir, destDirName);
    if (existsSync(destPath)) {
      rmSync(destPath, { recursive: true, force: true });
      console.log(`[${id}] removido: ${destDirName}/`);
    }
  }
}

function copyRouteFiles(route) {
  const { id, package: packagePath, target } = route;
  const packageDir = join(REPO_ROOT, packagePath);
  const targetDir = join(REPO_ROOT, target.resource);

  for (const [destFileName, rawEntry] of Object.entries(target.files ?? {})) {
    const { path: relativeSrcPath, optional } = normalizeEntry(rawEntry);
    const srcPath = join(packageDir, relativeSrcPath);
    const destPath = join(targetDir, destFileName);

    if (!existsSync(srcPath)) {
      if (optional) {
        console.log(`[${id}] arquivo opcional ainda não fornecido, pulando: ${relativeSrcPath}`);
        continue;
      }
      throw new OverrideBuildError(
        `Arquivo de origem não encontrado após o build (rota "${id}"): ${srcPath}`,
      );
    }

    mkdirSync(dirname(destPath), { recursive: true });
    cpSync(srcPath, destPath);
    console.log(`[${id}] copiado: ${relativeSrcPath} -> ${target.resource}/${destFileName}`);
  }
}

// Diretórios são espelhados (conteúdo do destino é apagado e recriado a
// partir do dist/) em vez de mesclados — assim remover uma faixa de
// public/audio/ e rebuildar também remove ela do resource. Só é seguro porque
// os destinos mapeados aqui (ex. assets/labafero-audio/) são exclusivos do
// Labafero, nunca compartilhados com diretórios vendorizados do QBCore.
function copyRouteDirs(route) {
  const { id, package: packagePath, target } = route;
  const packageDir = join(REPO_ROOT, packagePath);
  const targetDir = join(REPO_ROOT, target.resource);

  for (const [destDirName, rawEntry] of Object.entries(target.dirs ?? {})) {
    const { path: relativeSrcPath, optional } = normalizeEntry(rawEntry);
    const srcDir = join(packageDir, relativeSrcPath);
    const destDir = join(targetDir, destDirName);

    if (!existsSync(srcDir)) {
      if (optional) {
        console.log(`[${id}] diretório opcional ainda não fornecido, pulando: ${relativeSrcPath}`);
        continue;
      }
      throw new OverrideBuildError(
        `Diretório de origem não encontrado após o build (rota "${id}"): ${srcDir}`,
      );
    }

    rmSync(destDir, { recursive: true, force: true });
    mkdirSync(dirname(destDir), { recursive: true });
    cpSync(srcDir, destDir, { recursive: true });
    console.log(`[${id}] copiado: ${relativeSrcPath}/ -> ${target.resource}/${destDirName}/`);
  }
}

function ensureResourceInstalled(route) {
  const targetDir = join(REPO_ROOT, route.target.resource);
  if (!existsSync(targetDir)) {
    throw new OverrideBuildError(
      `Diretório de destino não existe: ${targetDir}\n` +
        `Rode ./scripts/install-qbcore.sh para instalar os resources vendorizados do QBCore antes de rodar override:build.`,
    );
  }
}

export function overrideBuild() {
  const manifestPath = join(REPO_ROOT, "labafero.json");
  const manifest = readJson(manifestPath, "labafero.json");

  const routes = manifest.routes ?? [];
  if (routes.length === 0) {
    console.log("Nenhuma rota definida em labafero.json — nada a fazer.");
    return;
  }

  routes.forEach(validateRoute);

  for (const route of routes) {
    const packageDir = join(REPO_ROOT, route.package);
    ensureResourceInstalled(route);
    buildPackage(packageDir, route.id);
    ensureBackup(route);
    copyRouteFiles(route);
    copyRouteDirs(route);
  }

  console.log(`override:build concluído (${routes.length} rota(s) processada(s)).`);
}

export function overrideRestore() {
  const manifestPath = join(REPO_ROOT, "labafero.json");
  const manifest = readJson(manifestPath, "labafero.json");

  const routes = manifest.routes ?? [];
  if (routes.length === 0) {
    console.log("Nenhuma rota definida em labafero.json — nada a restaurar.");
    return;
  }

  routes.forEach(validateRoute);
  routes.forEach((route) => {
    ensureResourceInstalled(route);
    restoreRoute(route);
  });

  console.log(`override:restore concluído (${routes.length} rota(s) restaurada(s)).`);
}
