(() => {
    const summarySearch = document.getElementById('summarySearch');
    const moodFilter = document.getElementById('moodFilter');
    const statusFilter = document.getElementById('statusFilter');
    const clearFilters = document.getElementById('clearFilters');
    const openModal = document.getElementById('openWellnessModal');
    const modal = document.getElementById('wellnessModal');
    const closeModal = document.getElementById('closeWellnessModal');
    const cancelModal = document.getElementById('cancelWellnessModal');
    const form = document.getElementById('wellnessForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-user]'));

    function applyFilters() {
        const searchText = (summarySearch?.value || '').trim().toLowerCase();
        const mood = (moodFilter?.value || '').toLowerCase();
        const status = (statusFilter?.value || '').toLowerCase();

        rows.forEach((row) => {
            const user = (row.dataset.user || '').toLowerCase();
            const moodValue = (row.dataset.mood || '').toLowerCase();
            const balanceStatus = (row.dataset.balance || '').toLowerCase();

            const matchesSearch = !searchText || user.includes(searchText) || moodValue.includes(searchText);
            const matchesMood = !mood || moodValue === mood;
            const matchesStatus = !status || balanceStatus === status;

            row.hidden = !(matchesSearch && matchesMood && matchesStatus);
        });
    }

    function showModal() {
        modal?.classList.add('show');
        form?.querySelector('input, select, textarea')?.focus();
    }

    function hideModal() {
        modal?.classList.remove('show');
        form?.reset();
    }

    summarySearch?.addEventListener('input', applyFilters);
    moodFilter?.addEventListener('change', applyFilters);
    statusFilter?.addEventListener('change', applyFilters);
    clearFilters?.addEventListener('click', () => {
        if (!summarySearch || !moodFilter || !statusFilter) return;
        summarySearch.value = '';
        moodFilter.value = '';
        statusFilter.value = '';
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
        alert('This form is ready for your save endpoint. Connect it to your Spring Boot controller to persist wellness summaries.');
        hideModal();
    });

    applyFilters();
})();
