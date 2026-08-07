(() => {
    const menuToggle = document.getElementById('menuToggle');
    const overlay = document.getElementById('sidebarOverlay');
    const sidebar = document.getElementById('sidebar');
    const searchInput = document.querySelector('.search-box input');

    const setSidebarOpen = (isOpen) => {
        document.body.classList.toggle('sidebar-open', isOpen);
        menuToggle?.setAttribute('aria-expanded', String(isOpen));
        menuToggle?.setAttribute('aria-label', isOpen ? 'Close menu' : 'Open menu');
    };
    const toggleSidebar = () => setSidebarOpen(!document.body.classList.contains('sidebar-open'));
    const closeSidebar = () => setSidebarOpen(false);

    menuToggle?.addEventListener('click', toggleSidebar);
    overlay?.addEventListener('click', closeSidebar);
    sidebar?.querySelectorAll('.nav-link')?.forEach(link => {
        link.addEventListener('click', () => {
            if (window.innerWidth <= 850) closeSidebar();
        });
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') closeSidebar();
    });

    window.addEventListener('resize', () => {
        if (window.innerWidth > 850) closeSidebar();
    });

    if (searchInput) {
        searchInput.addEventListener('input', (event) => {
            const term = event.target.value.trim().toLowerCase();
            const rows = document.querySelectorAll('table tbody tr');
            rows.forEach((row) => {
                const text = row.textContent.toLowerCase();
                row.hidden = Boolean(term) && !text.includes(term);
            });
        });
    }
})();
