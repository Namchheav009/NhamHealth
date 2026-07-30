(() => {
    const searchInput = document.getElementById('userSearch');
    const statusFilter = document.getElementById('statusFilter');
    const verificationFilter = document.getElementById('verificationFilter');
    const roleFilter = document.getElementById('roleFilter');
    const clearFilters = document.getElementById('clearFilters');
    const table = document.getElementById('usersTable');
    const rows = table ? [...table.querySelectorAll('tbody tr')] : [];
    const visibleCount = document.getElementById('visibleCount');
    const footerVisibleCount = document.getElementById('footerVisibleCount');
    const selectAll = document.getElementById('selectAll');
    const exportButton = document.getElementById('exportButton');

    function applyFilters() {
        const keyword = searchInput.value.trim().toLowerCase();
        const status = statusFilter.value;
        const verification = verificationFilter.value;
        const role = roleFilter.value;
        let count = 0;

        rows.forEach((row) => {
            const matchesKeyword = !keyword || row.dataset.name.includes(keyword) || row.dataset.email.includes(keyword);
            const matchesStatus = status === 'all' || row.dataset.status === status;
            const matchesVerification = verification === 'all' || row.dataset.verification === verification;
            const matchesRole = role === 'all' || row.dataset.role === role;
            const show = matchesKeyword && matchesStatus && matchesVerification && matchesRole;

            row.hidden = !show;
            if (show) count += 1;
        });

        visibleCount.textContent = count;
        footerVisibleCount.textContent = count;
        selectAll.checked = false;
    }

    [searchInput, statusFilter, verificationFilter, roleFilter].forEach((control) => {
        control.addEventListener(control.tagName === 'INPUT' ? 'input' : 'change', applyFilters);
    });

    clearFilters.addEventListener('click', () => {
        searchInput.value = '';
        statusFilter.value = 'all';
        verificationFilter.value = 'all';
        roleFilter.value = 'all';
        applyFilters();
    });

    selectAll.addEventListener('change', () => {
        rows.filter((row) => !row.hidden).forEach((row) => {
            row.querySelector('.row-checkbox').checked = selectAll.checked;
        });
    });

    exportButton.addEventListener('click', () => {
        const headers = ['Name', 'Email', 'Status', 'Verification', 'Wellness Profile', 'Joined Date', 'Last Active'];
        const dataRows = rows.filter((row) => !row.hidden).map((row) => {
            const cells = row.querySelectorAll('td');
            return [
                cells[1].querySelector('strong').textContent.trim(),
                cells[2].textContent.trim(),
                cells[3].textContent.trim(),
                cells[4].textContent.trim(),
                cells[5].textContent.trim(),
                cells[6].textContent.trim(),
                cells[7].textContent.trim()
            ];
        });

        const csv = [headers, ...dataRows]
            .map((row) => row.map((value) => `"${value.replaceAll('"', '""')}"`).join(','))
            .join('\n');

        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = 'nham-health-users.csv';
        link.click();
        URL.revokeObjectURL(url);
    });

    const modal = document.getElementById('userModal');
    const openAddUser = document.getElementById('openAddUser');
    const closeModal = document.getElementById('closeModal');
    const cancelModal = document.getElementById('cancelModal');
    const addUserForm = document.getElementById('addUserForm');

    function showModal() {
        modal.hidden = false;
        document.body.style.overflow = 'hidden';
        modal.querySelector('input')?.focus();
    }

    function hideModal() {
        modal.hidden = true;
        document.body.style.overflow = '';
        addUserForm.reset();
    }

    openAddUser.addEventListener('click', showModal);
    closeModal.addEventListener('click', hideModal);
    cancelModal.addEventListener('click', hideModal);
    modal.addEventListener('click', (event) => {
        if (event.target === modal) hideModal();
    });

    addUserForm.addEventListener('submit', (event) => {
        event.preventDefault();
        alert('UI demonstration only. Connect this form to your UserService to save the user.');
        hideModal();
    });
})();
