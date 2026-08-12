(() => {
    const searchInput = document.getElementById('userSearch');
    const statusFilter = document.getElementById('statusFilter');
    const verificationFilter = document.getElementById('verificationFilter');
    const roleFilter = document.getElementById('roleFilter');
    const clearFilters = document.getElementById('clearFilters');
    const table = document.getElementById('usersTable');
    const rows = table ? [...table.querySelectorAll('tbody tr[data-email]')] : [];
    const visibleCount = document.getElementById('visibleCount');
    const footerVisibleCount = document.getElementById('footerVisibleCount');
    const exportButton = document.getElementById('exportButton');
    const modal = document.getElementById('userModal');
    const openAddUser = document.getElementById('openAddUser');
    const closeModal = document.getElementById('closeModal');
    const cancelModal = document.getElementById('cancelModal');
    const form = document.getElementById('addUserForm');
    const formError = document.getElementById('formError');
    const submitButton = document.getElementById('createUserButton');
    const title = document.getElementById('addUserTitle');
    const description = document.getElementById('userModalDescription');
    const passwordLabel = document.getElementById('passwordLabel');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;
    let editingUserId = null;

    const applyFilters = () => {
        const keyword = searchInput?.value.trim().toLowerCase() || '';
        const status = statusFilter?.value || 'all';
        const verification = verificationFilter?.value || 'all';
        const role = roleFilter?.value || 'all';
        let count = 0;
        rows.forEach((row) => {
            const matchesKeyword = !keyword || row.dataset.name.includes(keyword) || row.dataset.email.includes(keyword);
            const show = matchesKeyword
                && (status === 'all' || row.dataset.status === status)
                && (verification === 'all' || row.dataset.verification === verification)
                && (role === 'all' || row.dataset.role === role);
            row.hidden = !show;
            if (show) count += 1;
        });
        if (visibleCount) visibleCount.textContent = count;
        if (footerVisibleCount) footerVisibleCount.textContent = count;
    };

    [searchInput, statusFilter, verificationFilter, roleFilter].filter(Boolean).forEach((control) => {
        control.addEventListener(control.tagName === 'INPUT' ? 'input' : 'change', applyFilters);
    });
    clearFilters?.addEventListener('click', () => {
        if (searchInput) searchInput.value = '';
        if (statusFilter) statusFilter.value = 'all';
        if (verificationFilter) verificationFilter.value = 'all';
        if (roleFilter) roleFilter.value = 'all';
        applyFilters();
    });

    exportButton?.addEventListener('click', () => {
        const headers = ['User', 'Role', 'Status', 'Verification', 'Profile', 'Joined', 'Last active'];
        const dataRows = rows.filter((row) => !row.hidden)
            .map((row) => [...row.querySelectorAll('td')].slice(0, 7)
                .map((cell) => cell.textContent.trim().replaceAll(/\s+/g, ' ')));
        const csv = [headers, ...dataRows].map((row) => row.map((value) => `"${value.replaceAll('"', '""')}"`).join(',')).join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.download = 'nham-health-users.csv';
        link.click();
        URL.revokeObjectURL(url);
    });

    const requestHeaders = (json = false) => ({
        ...(json ? { 'Content-Type': 'application/json' } : {}),
        'Accept': 'application/json',
        ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {})
    });

    const uploadProfileImage = async (file) => {
        if (!(file instanceof File) || file.size === 0) return null;
        const uploadData = new FormData();
        uploadData.append('file', file);
        const response = await fetch('/admin/profile-images', { method: 'POST', headers: requestHeaders(), body: uploadData });
        const body = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(body.message || 'Unable to upload the profile image.');
        return body.profileImageUrl;
    };

    const setFormError = (message = '') => {
        if (!formError) return;
        formError.textContent = message;
        formError.hidden = !message;
    };

    const showModal = (row) => {
        if (!modal || !form) return;
        form.reset();
        setFormError();
        editingUserId = row?.dataset.id || null;
        const editing = Boolean(editingUserId);
        title.textContent = editing ? 'Edit user' : 'Add user';
        description.textContent = editing ? 'Update account access and profile details.' : 'Create an account with a temporary password.';
        passwordLabel.firstChild.textContent = editing ? 'New password (leave blank to keep current)' : 'Temporary password';
        form.password.required = !editing;
        submitButton.textContent = editing ? 'Save changes' : 'Create user';
        if (row) {
            form.userId.value = row.dataset.id;
            form.fullName.value = row.dataset.fullName;
            form.email.value = row.dataset.email;
            form.profileImageUrl.value = row.dataset.image;
            form.role.value = row.dataset.role;
            form.status.value = row.dataset.status;
            form.verified.checked = row.dataset.verification === 'verified';
        } else {
            form.status.value = 'ACTIVE';
            form.verified.checked = true;
        }
        modal.hidden = false;
        document.body.classList.add('modal-open');
        form.fullName.focus();
    };

    const hideModal = () => {
        if (!modal) return;
        modal.hidden = true;
        document.body.classList.remove('modal-open');
        editingUserId = null;
        form?.reset();
        setFormError();
    };

    openAddUser?.addEventListener('click', () => showModal());
    document.querySelectorAll('.edit-user').forEach((button) => button.addEventListener('click', () => showModal(button.closest('tr'))));
    closeModal?.addEventListener('click', hideModal);
    cancelModal?.addEventListener('click', hideModal);
    modal?.addEventListener('click', (event) => { if (event.target === modal) hideModal(); });
    document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal && !modal.hidden) hideModal(); });

    form?.addEventListener('submit', async (event) => {
        event.preventDefault();
        const formData = new FormData(form);
        const imageFile = formData.get('profileImageFile');
        formData.delete('profileImageFile');
        formData.delete('userId');
        const payload = Object.fromEntries(formData.entries());
        if (editingUserId && !payload.password) delete payload.password;
        payload.verified = form.verified.checked;
        setFormError();
        submitButton.disabled = true;
        submitButton.textContent = editingUserId ? 'Saving…' : 'Creating…';
        try {
            const profileImageUrl = await uploadProfileImage(imageFile);
            if (profileImageUrl) payload.profileImageUrl = profileImageUrl;
            const response = await fetch(editingUserId ? `/admin/users/${editingUserId}` : '/admin/users', {
                method: editingUserId ? 'PUT' : 'POST',
                headers: requestHeaders(true),
                body: JSON.stringify(payload)
            });
            if (!response.ok) {
                const body = await response.json().catch(() => ({}));
                throw new Error(body.message || 'Unable to save this user.');
            }
            window.location.reload();
        } catch (error) {
            setFormError(error.message);
            submitButton.disabled = false;
            submitButton.textContent = editingUserId ? 'Save changes' : 'Create user';
        }
    });

    document.querySelectorAll('.delete-user').forEach((button) => button.addEventListener('click', async () => {
        const row = button.closest('tr');
        const name = row?.dataset.fullName || 'this user';
        if (!row?.dataset.id || !window.confirm(`Delete ${name}? Their account will be disabled and hidden, while health and history records remain protected.`)) return;
        button.disabled = true;
        try {
            const response = await fetch(`/admin/users/${row.dataset.id}`, { method: 'DELETE', headers: requestHeaders() });
            if (!response.ok) {
                const body = await response.json().catch(() => ({}));
                throw new Error(body.message || 'Unable to delete this user.');
            }
            window.location.reload();
        } catch (error) {
            window.alert(error.message);
            button.disabled = false;
        }
    }));
})();
