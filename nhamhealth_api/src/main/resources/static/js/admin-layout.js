(() => {
    window.adminAlerts = {
        confirmDelete: ({ title = "Are you sure?", text = "This cannot be undone.", confirmButtonText = "Yes, delete it!" } = {}) => {
            if (!window.Swal) return Promise.resolve(window.confirm(text));
            return window.Swal.fire({
                title,
                text,
                icon: "warning",
                showCancelButton: true,
                confirmButtonColor: "#d33",
                cancelButtonColor: "#26be4c",
                confirmButtonText,
                cancelButtonText: "Cancel",
                reverseButtons: false
            }).then(result => result.isConfirmed);
        },
        success: (title, text) => {
            if (!window.Swal) return Promise.resolve(window.alert(text || title));
            return window.Swal.fire({ title, text, icon: "success", confirmButtonColor: "#08ae61" });
        },
        error: (text, title = "Something went wrong") => {
            if (!window.Swal) return Promise.resolve(window.alert(text));
            return window.Swal.fire({ title, text, icon: "error", confirmButtonColor: "#d33" });
        },
        confirmLogout: () => {
            if (!window.Swal) return Promise.resolve(window.confirm("Log out of the admin panel?"));
            return window.Swal.fire({
                title: "Log out?",
                text: "You will need to sign in again to access the admin panel.",
                icon: "question",
                showCancelButton: true,
                confirmButtonColor: "#08ae61",
                cancelButtonColor: "#64748b",
                confirmButtonText: "Yes, log out",
                cancelButtonText: "Stay signed in",
                reverseButtons: true
            }).then(result => result.isConfirmed);
        }
    };

    const url = new URL(window.location.href);
    if (url.searchParams.get('login') === 'success') {
        window.adminAlerts.success('Welcome back!', 'You have signed in successfully.');
        url.searchParams.delete('login');
        window.history.replaceState({}, document.title, `${url.pathname}${url.search}${url.hash}`);
    }

    const menuToggle = document.getElementById('menuToggle');
    const overlay = document.getElementById('sidebarOverlay');
    const sidebar = document.getElementById('sidebar');
    const searchInput = document.querySelector('.search-box input');
    const profileMenuToggle = document.getElementById('adminProfileMenuToggle');
    const profileMenu = document.getElementById('adminProfileMenu');
    const logoutForm = document.getElementById('logoutForm');
    const desktopBreakpoint = 850;
    const sidebarPreferenceKey = 'nhamHealthAdminSidebarCollapsed';

    const isMobile = () => window.innerWidth <= desktopBreakpoint;
    const saveDesktopPreference = (isCollapsed) => {
        try {
            window.localStorage.setItem(sidebarPreferenceKey, String(isCollapsed));
        } catch (_) {
            // The layout still works when browser storage is unavailable.
        }
    };
    const getDesktopPreference = () => {
        try {
            return window.localStorage.getItem(sidebarPreferenceKey) === 'true';
        } catch (_) {
            return false;
        }
    };

    const updateAccessibility = (isOpen) => {
        menuToggle?.setAttribute('aria-expanded', String(isOpen));
        menuToggle?.setAttribute('aria-label', isOpen ? 'Close menu' : 'Open menu');
        // A collapsed desktop sidebar remains usable as an icon navigation rail.
        const isOffCanvas = isMobile() && !isOpen;
        sidebar?.setAttribute('aria-hidden', String(isOffCanvas));
        if (sidebar) sidebar.inert = isOffCanvas;
    };

    const setMobileSidebarOpen = (isOpen) => {
        document.body.classList.toggle('sidebar-open', isOpen);
        updateAccessibility(isOpen);
    };
    const setDesktopSidebarCollapsed = (isCollapsed, shouldPersist = true) => {
        document.body.classList.toggle('sidebar-collapsed', isCollapsed);
        updateAccessibility(!isCollapsed);
        if (shouldPersist) saveDesktopPreference(isCollapsed);
    };
    const toggleSidebar = () => {
        if (isMobile()) {
            setMobileSidebarOpen(!document.body.classList.contains('sidebar-open'));
            return;
        }
        setDesktopSidebarCollapsed(!document.body.classList.contains('sidebar-collapsed'));
    };
    const closeSidebar = () => {
        if (isMobile()) setMobileSidebarOpen(false);
    };
    const setProfileMenuOpen = (isOpen) => {
        profileMenuToggle?.setAttribute('aria-expanded', String(isOpen));
        if (profileMenu) profileMenu.hidden = !isOpen;
    };

    menuToggle?.addEventListener('click', toggleSidebar);
    overlay?.addEventListener('click', closeSidebar);
    profileMenuToggle?.addEventListener('click', () => {
        setProfileMenuOpen(profileMenu?.hidden);
    });
    document.addEventListener('click', (event) => {
        if (profileMenuToggle?.contains(event.target) || profileMenu?.contains(event.target)) return;
        setProfileMenuOpen(false);
    });
    logoutForm?.addEventListener('submit', async (event) => {
        event.preventDefault();
        const confirmed = await (window.adminAlerts?.confirmLogout() ?? Promise.resolve(window.confirm("Log out of the admin panel?")));
        if (confirmed) logoutForm.submit();
    });
    sidebar?.querySelectorAll('.nav-link')?.forEach(link => {
        link.addEventListener('click', () => {
            // Keep the desktop sidebar in its selected state while navigating.
            if (isMobile()) closeSidebar();
        });
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            closeSidebar();
            setProfileMenuOpen(false);
        }
    });

    window.addEventListener('resize', () => {
        if (isMobile()) {
            document.body.classList.remove('sidebar-collapsed');
            setMobileSidebarOpen(false);
        } else {
            document.body.classList.remove('sidebar-open');
            setDesktopSidebarCollapsed(getDesktopPreference(), false);
        }
    });

    if (isMobile()) {
        setMobileSidebarOpen(false);
    } else {
        setDesktopSidebarCollapsed(getDesktopPreference(), false);
    }

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
