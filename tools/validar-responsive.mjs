import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const baseUrl = (process.env.TRANSPORT_BASE_URL || 'http://localhost:8080').replace(/\/$/, '');
const adminUser = process.env.TRANSPORT_TEST_ADMIN_USER || 'admin.demo';
const adminPassword = process.env.TRANSPORT_TEST_ADMIN_PASSWORD || 'TransPortAdmin2026!';
const output = resolve('artifacts', 'responsive');
const viewports = [{ width: 320, height: 760 }, { width: 768, height: 900 }, { width: 1100, height: 900 }, { width: 1920, height: 1080 }];
const chromeCandidates = [process.env.TRANSPORT_CHROME, 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe', 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe', '/usr/bin/google-chrome', '/usr/bin/chromium'].filter(Boolean);
const chrome = chromeCandidates.find(existsSync);
if (!chrome) throw new Error('No se encontró Chrome/Edge. Defina TRANSPORT_CHROME.');

const port = 9300 + Math.floor(Math.random() * 500);
const profile = await mkdtemp(join(tmpdir(), 'transport-responsive-'));
await mkdir(output, { recursive: true });
const browser = spawn(chrome, [`--headless=new`, `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, '--no-first-run', '--no-default-browser-check', '--disable-gpu', '--hide-scrollbars'], { stdio: 'ignore', windowsHide: true });

const sleep = ms => new Promise(resolvePromise => setTimeout(resolvePromise, ms));
const assert = (condition, message) => { if (!condition) throw new Error(message); };
async function retry(action, timeout = 10000) {
  const end = Date.now() + timeout;
  let error;
  while (Date.now() < end) {
    try { return await action(); } catch (current) { error = current; await sleep(100); }
  }
  throw error || new Error('Tiempo de espera agotado.');
}

class Cdp {
  constructor(socket) {
    this.socket = socket; this.nextId = 1; this.pending = new Map(); this.listeners = new Map();
    socket.addEventListener('message', event => {
      const message = JSON.parse(event.data);
      if (message.id) {
        const pending = this.pending.get(message.id); if (!pending) return;
        this.pending.delete(message.id); message.error ? pending.reject(new Error(message.error.message)) : pending.resolve(message.result);
      } else if (message.method) {
        for (const listener of this.listeners.get(message.method) || []) listener(message.params);
        this.listeners.delete(message.method);
      }
    });
  }
  send(method, params = {}) {
    const id = this.nextId++;
    return new Promise((resolvePromise, reject) => { this.pending.set(id, { resolve: resolvePromise, reject }); this.socket.send(JSON.stringify({ id, method, params })); });
  }
  event(method, timeout = 10000) {
    return new Promise((resolvePromise, reject) => {
      const timer = setTimeout(() => reject(new Error(`No ocurrió ${method}.`)), timeout);
      const callback = value => { clearTimeout(timer); resolvePromise(value); };
      const items = this.listeners.get(method) || []; items.push(callback); this.listeners.set(method, items);
    });
  }
  async navigate(url) {
    const loaded = this.event('Page.loadEventFired');
    await this.send('Page.navigate', { url }); await loaded; await sleep(150);
  }
  async value(expression) {
    const result = await this.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (result.exceptionDetails) throw new Error(result.exceptionDetails.text);
    return result.result.value;
  }
  async screenshot(name) {
    const result = await this.send('Page.captureScreenshot', { format: 'png', fromSurface: true, captureBeyondViewport: false });
    await writeFile(join(output, name), Buffer.from(result.data, 'base64'));
  }
}

let cdp;
try {
  await retry(() => fetch(`http://127.0.0.1:${port}/json/version`).then(response => { if (!response.ok) throw new Error('CDP no disponible'); return response.json(); }));
  const target = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' }).then(response => response.json());
  const socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolvePromise, reject) => { socket.addEventListener('open', resolvePromise, { once: true }); socket.addEventListener('error', reject, { once: true }); });
  cdp = new Cdp(socket);
  await cdp.send('Page.enable'); await cdp.send('Runtime.enable');

  for (const viewport of viewports) {
    await cdp.send('Emulation.setDeviceMetricsOverride', { ...viewport, deviceScaleFactor: 1, mobile: viewport.width < 768 });
    await cdp.navigate(`${baseUrl}/`);
    const check = await cdp.value(`(() => { const toggle=getComputedStyle(document.querySelector('.menu-toggle')).display; return {overflow:document.documentElement.scrollWidth<=document.documentElement.clientWidth+1,toggle}; })()`);
    assert(check.overflow, `La portada desborda horizontalmente a ${viewport.width}px.`);
    assert(viewport.width < 1100 ? check.toggle !== 'none' : check.toggle === 'none', `El menú principal no responde al breakpoint de ${viewport.width}px.`);
    await cdp.screenshot(`publico-${viewport.width}.png`);
  }

  await cdp.send('Emulation.setDeviceMetricsOverride', { width: 1100, height: 900, deviceScaleFactor: 1, mobile: false });
  await cdp.navigate(`${baseUrl}/acceso`);
  const submitted = cdp.event('Page.loadEventFired');
  await cdp.value(`(() => { const form=document.querySelector('form.auth-form'); form.querySelector('[name="NombreUsuario"]').value=${JSON.stringify(adminUser)}; form.querySelector('[name="Clave"]').value=${JSON.stringify(adminPassword)}; form.requestSubmit(); return true; })()`);
  await submitted; await retry(async () => { const path = await cdp.value('location.pathname'); if (path !== '/admin') throw new Error(`Login terminó en ${path}`); return path; });

  for (const viewport of viewports) {
    await cdp.send('Emulation.setDeviceMetricsOverride', { ...viewport, deviceScaleFactor: 1, mobile: viewport.width < 768 });
    await cdp.navigate(`${baseUrl}/admin`);
    await cdp.value(`localStorage.setItem('transport-admin-sidebar','expanded');document.querySelector('.admin-workspace')?.classList.remove('sidebar-collapsed');true`);
    const check = await cdp.value(`(() => ({sidebar:!!document.querySelector('#admin-sidebar'),overflow:document.documentElement.scrollWidth<=document.documentElement.clientWidth+1,openDisplay:getComputedStyle(document.querySelector('.admin-sidebar-open')).display}))()`);
    assert(check.sidebar, `No se renderizó el sidebar administrativo a ${viewport.width}px.`);
    assert(check.overflow, `El panel administrativo desborda a ${viewport.width}px.`);
    assert(viewport.width < 1100 ? check.openDisplay !== 'none' : check.openDisplay === 'none', `El disparador del sidebar no coincide con ${viewport.width}px.`);
    await cdp.screenshot(`admin-${viewport.width}.png`);
    if (viewport.width < 1100) {
      const opened = await cdp.value(`document.querySelector('.admin-sidebar-open').click();document.querySelector('.admin-workspace').classList.contains('sidebar-open')`);
      assert(opened, `El sidebar móvil no abre a ${viewport.width}px.`);
      await cdp.screenshot(`admin-${viewport.width}-menu.png`);
      await cdp.value(`document.querySelector('.admin-sidebar-overlay').click();true`);
    } else {
      const collapsed = await cdp.value(`document.querySelector('.admin-sidebar-collapse').click();document.querySelector('.admin-workspace').classList.contains('sidebar-collapsed')`);
      assert(collapsed, `El sidebar no colapsa a ${viewport.width}px.`);
    }
  }

  await cdp.navigate(`${baseUrl}/`);
  const pwa = await retry(() => cdp.value(`(async()=>{const registration=await navigator.serviceWorker.ready;const keys=await caches.keys();const urls=[];for(const key of keys){for(const request of await (await caches.open(key)).keys())urls.push(new URL(request.url).pathname);}return {scope:registration.scope,keys,urls};})()`), 15000);
  assert(pwa.keys.includes('transport-public-v2'), 'El caché PWA vigente no fue instalado.');
  assert(!pwa.urls.some(path => ['/acceso','/admin','/gestion','/cliente','/portal'].some(prefix => path.startsWith(prefix))), 'El service worker almacenó contenido autenticado.');

  const manifest = await fetch(`${baseUrl}/manifest.webmanifest`).then(response => response.json());
  for (const expected of [{ src: '/images/icon-192.png', size: 192 }, { src: '/images/icon-512.png', size: 512 }]) {
    assert(manifest.icons.some(icon => icon.src === expected.src && icon.sizes === `${expected.size}x${expected.size}`), `Falta ${expected.src} en el manifest.`);
    const bytes = Buffer.from(await fetch(`${baseUrl}${expected.src}`).then(response => response.arrayBuffer()));
    assert(bytes.toString('ascii', 1, 4) === 'PNG' && bytes.readUInt32BE(16) === expected.size && bytes.readUInt32BE(20) === expected.size, `${expected.src} no tiene dimensiones válidas.`);
  }
  console.log(`Validación responsive/PWA correcta: ${viewports.map(x => `${x.width}px`).join(', ')}.`);
  console.log(`Capturas: ${output}`);
} finally {
  try { cdp?.socket.close(); } catch { /* cierre opcional */ }
  browser.kill();
  await sleep(500);
  if (profile.startsWith(tmpdir())) {
    try { await retry(() => rm(profile, { recursive: true, force: true }), 3000); }
    catch { console.warn(`El perfil temporal quedó bloqueado y Windows lo liberará al cerrar Chrome: ${profile}`); }
  }
}
