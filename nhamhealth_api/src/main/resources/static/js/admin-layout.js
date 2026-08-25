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
    const sidebarScrollKey = 'nhamHealthAdminSidebarScrollTop';
    const sidebarGroupsKey = 'nhamHealthAdminSidebarGroups';

    const isMobile = () => window.innerWidth <= desktopBreakpoint;
    const sectionToggles = [...(sidebar?.querySelectorAll('.nav-section[aria-controls]') ?? [])];
    const setSectionOpen = (toggle, isOpen) => {
        const group = document.getElementById(toggle.getAttribute('aria-controls'));
        toggle.setAttribute('aria-expanded', String(isOpen));
        group?.classList.toggle('is-open', isOpen);
    };
    const saveSectionStates = () => {
        try {
            const states = Object.fromEntries(sectionToggles.map(toggle => [
                toggle.getAttribute('aria-controls'),
                toggle.getAttribute('aria-expanded') === 'true'
            ]));
            window.sessionStorage.setItem(sidebarGroupsKey, JSON.stringify(states));
        } catch (_) {
            // Categories still expand when browser storage is unavailable.
        }
    };
    const initializeSectionStates = () => {
        let savedStates = {};
        try {
            savedStates = JSON.parse(window.sessionStorage.getItem(sidebarGroupsKey) || '{}');
        } catch (_) {
            savedStates = {};
        }
        sectionToggles.forEach(toggle => {
            const group = document.getElementById(toggle.getAttribute('aria-controls'));
            const containsActivePage = Boolean(group?.querySelector('.nav-link.active'));
            setSectionOpen(toggle, containsActivePage || savedStates[group?.id] === true);
            toggle.addEventListener('click', () => {
                setSectionOpen(toggle, toggle.getAttribute('aria-expanded') !== 'true');
                saveSectionStates();
            });
        });
    };
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
    const saveSidebarScrollPosition = () => {
        if (!sidebar) return;
        try {
            window.sessionStorage.setItem(sidebarScrollKey, String(sidebar.scrollTop));
        } catch (_) {
            // The layout still works when browser storage is unavailable.
        }
    };
    const restoreSidebarScrollPosition = () => {
        if (!sidebar) return;
        try {
            const savedScrollTop = Number(window.sessionStorage.getItem(sidebarScrollKey));
            if (Number.isFinite(savedScrollTop)) sidebar.scrollTop = savedScrollTop;
        } catch (_) {
            // The sidebar simply starts at the top when browser storage is unavailable.
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
            saveSidebarScrollPosition();
            if (isMobile()) closeSidebar();
        });
    });
    sidebar?.addEventListener('scroll', saveSidebarScrollPosition, { passive: true });
    window.addEventListener('pagehide', saveSidebarScrollPosition);

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
    initializeSectionStates();
    restoreSidebarScrollPosition();

    const pageWindow = (totalPages, currentPage) => {
        if (totalPages <= 5) return Array.from({ length: totalPages }, (_, index) => index + 1);
        if (currentPage <= 3) return [1, 2, 3, totalPages];
        if (currentPage >= totalPages - 2) return [1, totalPages - 2, totalPages - 1, totalPages];
        return [1, currentPage - 1, currentPage, currentPage + 1, totalPages];
    };

    const renderPageButtons = (container, totalPages, currentPage, onSelect, buttonClass = 'admin-page-button') => {
        container.replaceChildren();
        let previousPage = 0;
        pageWindow(totalPages, currentPage).forEach(pageNumber => {
            if (pageNumber > previousPage + 1) {
                const ellipsis = document.createElement('span');
                ellipsis.className = 'admin-pagination-ellipsis';
                ellipsis.textContent = '\u2026';
                container.appendChild(ellipsis);
            }
            const button = document.createElement('button');
            button.type = 'button';
            button.className = `${buttonClass}${pageNumber === currentPage ? ' active' : ''}`;
            button.textContent = String(pageNumber);
            button.setAttribute('aria-label', `Page ${pageNumber}`);
            if (pageNumber === currentPage) button.setAttribute('aria-current', 'page');
            button.addEventListener('click', () => onSelect(pageNumber));
            container.appendChild(button);
            previousPage = pageNumber;
        });
    };

    const createPageSelect = (totalPages, currentPage, onSelect) => {
        const label = document.createElement('label');
        label.className = 'admin-page-jump';
        label.append('Page ');
        const select = document.createElement('select');
        select.setAttribute('aria-label', 'Select page');
        for (let pageNumber = 1; pageNumber <= totalPages; pageNumber += 1) {
            const option = document.createElement('option');
            option.value = String(pageNumber);
            option.textContent = String(pageNumber);
            option.selected = pageNumber === currentPage;
            select.appendChild(option);
        }
        select.addEventListener('change', () => onSelect(Number(select.value)));
        const total = document.createElement('span');
        total.textContent = `of ${totalPages}`;
        label.append(select, total);
        return label;
    };

    // Pages that render their table rows on the server use this shared control.
    // Pages with their own pagination controls retain their paging logic and are
    // enhanced below so their controls share the same visual pattern.
    const enableTablePagination = () => {
        if (document.getElementById('pageNumbers') || document.getElementById('mealPagination')) return;

        document.querySelectorAll('table tbody').forEach((body, tableIndex) => {
            const rows = () => [...body.querySelectorAll('tr')]
                .filter(row => !row.querySelector('.empty-state'));
            if (rows().length <= 10) return;

            const controls = document.createElement('nav');
            controls.className = 'admin-pagination-nav';
            controls.setAttribute('aria-label', `Table ${tableIndex + 1} pages`);
            controls.innerHTML = `
                <button class="admin-page-button admin-page-previous" type="button" aria-label="Previous page">Previous</button>
                <div class="admin-page-numbers"></div>
                <button class="admin-page-button admin-page-next" type="button" aria-label="Next page">Next</button>`;

            const [previous, pageNumbers, next] = controls.children;
            const footer = document.createElement('div');
            footer.className = 'admin-pagination-wrap';
            const summary = document.createElement('div');
            summary.className = 'admin-pagination-summary';
            const pageJump = document.createElement('span');
            footer.append(summary, controls, pageJump);
            const table = body.closest('table');
            const tableHeading = table.closest('article, section')?.querySelector('h2, h3')?.textContent?.trim();
            const itemLabel = (tableHeading || 'records').replace(/^all\s+/i, '').toLowerCase();
            table.parentElement.after(footer);

            let page = 0;
            let matchingRowCount = 0;
            const render = () => {
                rows().forEach(row => {
                    if (row.dataset.adminPaginationHidden === 'true') {
                        row.hidden = false;
                        delete row.dataset.adminPaginationHidden;
                    }
                });

                const matchingRows = rows().filter(row => !row.hidden);
                matchingRowCount = matchingRows.length;
                const pageCount = Math.max(1, Math.ceil(matchingRows.length / 10));
                page = Math.min(page, pageCount - 1);
                const first = page * 10;
                const displayed = new Set(matchingRows.slice(first, first + 10));
                matchingRows.forEach(row => {
                    if (!displayed.has(row)) {
                        row.hidden = true;
                        row.dataset.adminPaginationHidden = 'true';
                    }
                });
                const start = matchingRows.length ? first + 1 : 0;
                const end = Math.min(first + 10, matchingRows.length);
                summary.textContent = `Showing ${start} to ${end} of ${matchingRows.length} ${itemLabel}`;
                renderPageButtons(pageNumbers, pageCount, page + 1, selectedPage => {
                    page = selectedPage - 1;
                    render();
                });
                pageJump.replaceChildren(createPageSelect(pageCount, page + 1, selectedPage => {
                    page = selectedPage - 1;
                    render();
                }));
                previous.disabled = page === 0;
                next.disabled = page >= pageCount - 1;
            };

            previous.addEventListener('click', () => {
                if (page > 0) {
                    page -= 1;
                    render();
                }
            });
            next.addEventListener('click', () => {
                if (page < Math.ceil(matchingRowCount / 10) - 1) {
                    page += 1;
                    render();
                }
            });
            document.addEventListener('input', () => window.setTimeout(() => {
                page = 0;
                render();
            }));
            document.addEventListener('change', () => window.setTimeout(() => {
                page = 0;
                render();
            }));
            render();
        });
    };
    enableTablePagination();

    // Existing page modules render their own number buttons. Keep that data
    // flow intact, but collapse long lists and add a direct page selector once
    // those modules have finished their first render.
    const enhanceModulePagination = () => {
        const numbers = document.getElementById('pageNumbers');
        if (!numbers) return;
        const controls = numbers.closest('nav');
        const footer = controls?.parentElement;
        if (!controls || !footer) return;

        let jump = footer.querySelector('.admin-page-jump');
        if (!jump) {
            jump = document.createElement('span');
            footer.appendChild(jump);
        }

        const sync = () => {
            const buttons = [...numbers.querySelectorAll(':scope > button')];
            if (!buttons.length) return;
            const active = buttons.findIndex(button => button.classList.contains('active'));
            const currentPage = active >= 0 ? active + 1 : 1;
            const visiblePages = new Set(pageWindow(buttons.length, currentPage));
            buttons.forEach((button, index) => { button.hidden = !visiblePages.has(index + 1); });

            numbers.querySelectorAll('.admin-pagination-ellipsis').forEach(node => node.remove());
            let previousPage = 0;
            pageWindow(buttons.length, currentPage).forEach(pageNumber => {
                if (pageNumber > previousPage + 1) {
                    const ellipsis = document.createElement('span');
                    ellipsis.className = 'admin-pagination-ellipsis';
                    ellipsis.textContent = '\u2026';
                    numbers.insertBefore(ellipsis, buttons[pageNumber - 1]);
                }
                previousPage = pageNumber;
            });
            jump.replaceChildren(createPageSelect(buttons.length, currentPage, selectedPage => buttons[selectedPage - 1]?.click()));
        };

        const observer = new MutationObserver(records => {
            const moduleRebuiltPages = records.some(record => [...record.addedNodes, ...record.removedNodes]
                .some(node => node.nodeType === Node.ELEMENT_NODE && node.tagName === 'BUTTON'));
            if (moduleRebuiltPages) window.queueMicrotask(sync);
        });
        observer.observe(numbers, { childList: true, subtree: false });
        sync();
    };
    window.setTimeout(enhanceModulePagination, 0);

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
