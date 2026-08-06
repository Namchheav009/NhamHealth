(() => {
    const menuToggle = document.getElementById('menuToggle');
    const overlay = document.getElementById('sidebarOverlay');
    const sidebar = document.getElementById('sidebar');
    const searchInput = document.querySelector('.search-box input');

    const toggleSidebar = () => document.body.classList.toggle('sidebar-open');
    const closeSidebar = () => document.body.classList.remove('sidebar-open');

    menuToggle?.addEventListener('click', toggleSidebar);
    overlay?.addEventListener('click', closeSidebar);
    sidebar?.querySelectorAll('.nav-link')?.forEach(link => {
        link.addEventListener('click', () => {
            if (window.innerWidth <= 850) closeSidebar();
        });
    });

    if (searchInput) {
        searchInput.addEventListener('input', (event) => {
            const term = event.target.value.trim().toLowerCase();
            const rows = document.querySelectorAll('table tbody tr');
            rows.forEach((row) => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(term) ? '' : 'none';
            });
        });
    }
})();
