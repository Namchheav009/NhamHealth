(() => {
    const searchInput = document.getElementById('analysisSearch');
    const statusFilter = document.getElementById('statusFilter');
    const clearFiltersButton = document.getElementById('clearFilters');
    const openModalButton = document.getElementById('openAnalysisModal');
    const modal = document.getElementById('analysisModal');
    const closeModalButton = document.getElementById('closeAnalysisModal');
    const cancelModalButton = document.getElementById('cancelAnalysisModal');
    const form = document.getElementById('analysisForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-user]'));

    const applyFilters = () => {
        const searchText = (searchInput?.value || '').trim().toLowerCase();
        const statusValue = (statusFilter?.value || '').toLowerCase();

        rows.forEach((row) => {
            const user = (row.dataset.user || '').toLowerCase();
            const food = (row.dataset.food || '').toLowerCase();
            const status = (row.dataset.status || '').toLowerCase();

            const matchesSearch = !searchText || user.includes(searchText) || food.includes(searchText);
            const matchesStatus = !statusValue || status === statusValue;
            row.hidden = !(matchesSearch && matchesStatus);
        });
    };

    const showModal = () => {
        modal?.classList.add('show');
        form?.querySelector('input, select, textarea')?.focus();
    };

    const hideModal = () => {
        modal?.classList.remove('show');
        form?.reset();
    };

    searchInput?.addEventListener('input', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearFiltersButton?.addEventListener('click', () => {
        if (!searchInput || !statusFilter) return;
        searchInput.value = '';
        statusFilter.value = '';
        applyFilters();
    });

    openModalButton?.addEventListener('click', showModal);
    closeModalButton?.addEventListener('click', hideModal);
    cancelModalButton?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => {
        if (event.target === modal) hideModal();
    });

    form?.addEventListener('submit', (event) => {
        event.preventDefault();
        alert('AI food analysis creation is ready to be wired to your backend save endpoint.');
        hideModal();
    });

    applyFilters();
})();
