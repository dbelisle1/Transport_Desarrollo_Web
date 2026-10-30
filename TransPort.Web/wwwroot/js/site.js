// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

const toggle = document.querySelector('.menu-toggle');
const menu = document.querySelector('.main-menu');
toggle?.addEventListener('click', () => {
  const open = menu?.classList.toggle('open') ?? false;
  toggle.setAttribute('aria-expanded', String(open));
  document.body.classList.toggle('menu-open', open);
});
menu?.querySelectorAll('a').forEach(link => link.addEventListener('click', () => {
  menu.classList.remove('open');
  toggle?.setAttribute('aria-expanded', 'false');
  document.body.classList.remove('menu-open');
}));
document.querySelectorAll('form[data-confirm]').forEach(form => form.addEventListener('submit', event => {
  if (!window.confirm(form.dataset.confirm)) event.preventDefault();
}));
const adminWorkspace = document.querySelector('[data-admin-workspace="true"]');
const adminOpen = document.querySelector('.admin-sidebar-open');
const adminCollapse = document.querySelector('.admin-sidebar-collapse');
const adminOverlay = document.querySelector('.admin-sidebar-overlay');
const desktopAdmin = window.matchMedia('(min-width: 1100px)');
const setAdminOpen = open => {
  adminWorkspace?.classList.toggle('sidebar-open', open);
  document.body.classList.toggle('admin-sidebar-visible', open);
  adminOpen?.setAttribute('aria-expanded', String(open));
};
if (adminWorkspace) {
  try { if (localStorage.getItem('transport-admin-sidebar') === 'collapsed') adminWorkspace.classList.add('sidebar-collapsed'); } catch { /* almacenamiento opcional */ }
  adminOpen?.addEventListener('click', () => setAdminOpen(!adminWorkspace.classList.contains('sidebar-open')));
  adminOverlay?.addEventListener('click', () => setAdminOpen(false));
  adminCollapse?.addEventListener('click', () => {
    if (!desktopAdmin.matches) { setAdminOpen(false); return; }
    const collapsed = adminWorkspace.classList.toggle('sidebar-collapsed');
    adminCollapse.setAttribute('aria-label', collapsed ? 'Expandir menú administrativo' : 'Contraer menú administrativo');
    adminCollapse.setAttribute('title', collapsed ? 'Expandir menú' : 'Contraer menú');
    try { localStorage.setItem('transport-admin-sidebar', collapsed ? 'collapsed' : 'expanded'); } catch { /* almacenamiento opcional */ }
  });
  adminWorkspace.querySelectorAll('.admin-side-link').forEach(link => link.addEventListener('click', () => setAdminOpen(false)));
  desktopAdmin.addEventListener('change', () => setAdminOpen(false));
  document.addEventListener('keydown', event => { if (event.key === 'Escape') setAdminOpen(false); });
}
if ('serviceWorker' in navigator) window.addEventListener('load', () => navigator.serviceWorker.register('/service-worker.js'));
