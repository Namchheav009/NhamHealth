(() => {
    const menuToggle = document.getElementById('menuToggle');
    const overlay = document.getElementById('sidebarOverlay');

    menuToggle?.addEventListener('click', () => document.body.classList.toggle('sidebar-open'));
    overlay?.addEventListener('click', () => document.body.classList.remove('sidebar-open'));
})();
