(() => {
    const search = document.getElementById('notifSearch');
    const status = document.getElementById('notifStatus');
    const clearButton = document.getElementById('clearNotifFilters');
    const exportButton = document.getElementById('exportNotifications');
    const refreshButton = document.getElementById('refreshNotifications');
    const openButton = document.getElementById('openNotificationModal');
    const modal = document.getElementById('notificationModal');
    const closeButton = document.getElementById('closeNotificationModal');
    const cancelButton = document.getElementById('cancelNotificationModal');
    const form = document.getElementById('notificationForm');
    const formError = document.getElementById('notificationFormError');
    const submitButton = document.getElementById('createNotificationButton');
    const visibleCount = document.getElementById('visibleNotificationCount');
    const rows = [...document.querySelectorAll('tbody tr[data-id]')];
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;

    const requestHeaders = (json = false) => ({
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
        ...(json ? { 'Content-Type': 'application/json' } : {})
    });

    const responseBody = async (response) => {
        const contentType = response.headers.get('content-type') || '';
        return contentType.includes('application/json') ? response.json() : {};
    };

    const applyFilters = () => {
        const query = search?.value.trim().toLowerCase() || '';
        const selectedStatus = status?.value || 'all';
        let count = 0;
        rows.forEach((row) => {
            const matchesText = !query || [row.dataset.user, row.dataset.title, row.dataset.message]
                .some(value => (value || '').includes(query));
            const matchesStatus = selectedStatus === 'all' || row.dataset.status === selectedStatus;
            row.hidden = !(matchesText && matchesStatus);
            if (!row.hidden) count += 1;
        });
        if (visibleCount) visibleCount.textContent = String(count);
    };

    const showModal = () => {
        form?.reset();
        if (formError) formError.hidden = true;
        modal?.classList.add('show');
        document.body.classList.add('modal-open');
        form?.querySelector('input')?.focus();
    };

    const hideModal = () => {
        modal?.classList.remove('show');
        document.body.classList.remove('modal-open');
    };

    search?.addEventListener('input', applyFilters);
    status?.addEventListener('change', applyFilters);
    clearButton?.addEventListener('click', () => {
        if (search) search.value = '';
        if (status) status.value = 'all';
        applyFilters();
    });
    refreshButton?.addEventListener('click', () => window.location.reload());
    openButton?.addEventListener('click', showModal);
    closeButton?.addEventListener('click', hideModal);
    cancelButton?.addEventListener('click', hideModal);
    modal?.addEventListener('click', event => { if (event.target === modal) hideModal(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape') hideModal(); });

    exportButton?.addEventListener('click', () => {
        const quote = value => `"${String(value || '').replaceAll('"', '""')}"`;
        const data = rows.filter(row => !row.hidden).map(row => [
            row.querySelector('.recipient-cell small')?.textContent.trim(),
            row.querySelector('.notification-copy strong')?.textContent.trim(),
            row.querySelector('.notification-copy span')?.textContent.trim(),
            row.querySelector('.type-badge')?.textContent.trim(),
            row.querySelector('time')?.textContent.trim(),
            row.dataset.status
        ]);
        const csv = [['User', 'Title', 'Message', 'Type', 'Created', 'Status'], ...data]
            .map(columns => columns.map(quote).join(',')).join('\n');
        const link = document.createElement('a');
        link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
        link.download = 'nham-health-notifications.csv';
        link.click();
        URL.revokeObjectURL(link.href);
    });

    form?.addEventListener('submit', async event => {
        event.preventDefault();
        if (formError) formError.hidden = true;
        if (submitButton) { submitButton.disabled = true; submitButton.textContent = 'Creating…'; }
        try {
            const payload = Object.fromEntries(new FormData(form).entries());
            const response = await fetch('/admin/notifications', {
                method: 'POST', headers: requestHeaders(true), body: JSON.stringify(payload)
            });
            const body = await responseBody(response);
            if (!response.ok) throw new Error(body.message || 'Unable to create notification.');
            window.location.reload();
        } catch (error) {
            if (formError) { formError.textContent = error.message; formError.hidden = false; }
        } finally {
            if (submitButton) { submitButton.disabled = false; submitButton.textContent = 'Create notification'; }
        }
    });

    document.querySelectorAll('.toggle-read').forEach(button => button.addEventListener('click', async () => {
        const row = button.closest('tr[data-id]');
        if (!row) return;
        const markRead = row.dataset.status !== 'read';
        const response = await fetch(`/admin/notifications/${row.dataset.id}/read`, {
            method: 'PATCH', headers: requestHeaders(true), body: JSON.stringify({ read: markRead })
        });
        if (response.ok) window.location.reload();
    }));

    document.querySelectorAll('.delete-notification').forEach(button => button.addEventListener('click', async () => {
        const row = button.closest('tr[data-id]');
        if (!row || !window.confirm('Delete this notification?')) return;
        const response = await fetch(`/admin/notifications/${row.dataset.id}`, {
            method: 'DELETE', headers: requestHeaders()
        });
        if (response.ok) window.location.reload();
    }));

    applyFilters();
})();
