(() => {
    const searchInput = document.getElementById('suggestionSearch');
    const statusFilter = document.getElementById('statusFilter');
    const clearFiltersButton = document.getElementById('clearFilters');
    const openModalButton = document.getElementById('openSuggestionModal');
    const modal = document.getElementById('suggestionModal');
    const closeModalButton = document.getElementById('closeSuggestionModal');
    const cancelModalButton = document.getElementById('cancelSuggestionModal');
    const form = document.getElementById('suggestionForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-food]'));

    const applyFilters = () => {
        const searchText = (searchInput?.value || '').trim().toLowerCase();
        const statusValue = (statusFilter?.value || '').toLowerCase();

        rows.forEach((row) => {
            const food = (row.dataset.food || '').toLowerCase();
            const status = (row.dataset.status || '').toLowerCase();
            const matchesSearch = !searchText || food.includes(searchText);
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
        alert('AI food suggestion creation is ready to be connected to your save endpoint.');
        hideModal();
    });

    applyFilters();
})();
