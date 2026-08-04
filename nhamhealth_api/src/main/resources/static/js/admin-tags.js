(() => {
    const searchInput = document.getElementById('tagSearch');
    const scopeFilter = document.getElementById('scopeFilter');
    const statusFilter = document.getElementById('statusFilter');
    const clearButton = document.getElementById('clearTagFilter');
    const modal = document.getElementById('tagModal');
    const openModal = document.getElementById('openTagModal');
    const closeModal = document.getElementById('closeTagModal');
    const cancelModal = document.getElementById('cancelTagModal');
    const form = document.getElementById('tagForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-name]'));

    function applyFilters() {
        const keyword = (searchInput?.value || '').trim().toLowerCase();
        const scope = (scopeFilter?.value || 'all').toLowerCase();
        const status = (statusFilter?.value || 'all').toLowerCase();

        rows.forEach((row) => {
            const name = (row.dataset.name || '').toLowerCase();
            const rowScope = (row.dataset.scope || '').toLowerCase();
            const rowStatus = (row.dataset.status || '').toLowerCase();

            const matchesKeyword = !keyword || name.includes(keyword);
            const matchesScope = scope === 'all' || rowScope === scope;
            const matchesStatus = status === 'all' || rowStatus === status;

            row.hidden = !(matchesKeyword && matchesScope && matchesStatus);
        });
    }

    function showModal() {
        modal?.classList.add('show');
        form?.querySelector('input')?.focus();
    }

    function hideModal() {
        modal?.classList.remove('show');
        form?.reset();
    }

    searchInput?.addEventListener('input', applyFilters);
    scopeFilter?.addEventListener('change', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearButton?.addEventListener('click', () => {
        searchInput.value = '';
        scopeFilter.value = 'all';
        statusFilter.value = 'all';
        applyFilters();
    });

    openModal?.addEventListener('click', showModal);
    closeModal?.addEventListener('click', hideModal);
    cancelModal?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => {
        if (event.target === modal) {
            hideModal();
        }
    });

    form?.addEventListener('submit', (event) => {
        event.preventDefault();
        alert('This form is ready for your Spring controller. Connect it to your save endpoint to persist tags.');
        hideModal();
    });
})();
