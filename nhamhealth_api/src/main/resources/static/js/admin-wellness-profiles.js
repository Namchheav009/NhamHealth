(() => {
    const table = document.getElementById('wellnessTable');
    const rows = table ? [...table.querySelectorAll('tbody tr[data-email]')] : [];
    const searchInput = document.getElementById('searchInput');
    const statusFilter = document.getElementById('statusFilter');
    const activityFilter = document.getElementById('activityFilter');
    const clearFilters = document.getElementById('clearFilters');
    const resultCount = document.getElementById('resultCount');
    const showingCount = document.getElementById('showingCount');
    const exportButton = document.getElementById('exportButton');

    const applyFilters = () => {
        const search = searchInput?.value.trim().toLowerCase() || '';
        const status = statusFilter?.value || 'all';
        const activity = activityFilter?.value || 'all';
        let visible = 0;
        rows.forEach((row) => {
            const matchesSearch = !search || row.dataset.name.includes(search) || row.dataset.email.includes(search);
            const show = matchesSearch
                && (status === 'all' || row.dataset.status === status)
                && (activity === 'all' || row.dataset.activity === activity);
            row.hidden = !show;
            if (show) visible += 1;
        });
        if (resultCount) resultCount.textContent = visible;
        if (showingCount) showingCount.textContent = visible;
    };

    [searchInput, statusFilter, activityFilter].filter(Boolean).forEach((element) => {
        element.addEventListener(element.tagName === 'INPUT' ? 'input' : 'change', applyFilters);
    });
    clearFilters?.addEventListener('click', () => {
        if (searchInput) searchInput.value = '';
        if (statusFilter) statusFilter.value = 'all';
        if (activityFilter) activityFilter.value = 'all';
        applyFilters();
    });

    exportButton?.addEventListener('click', () => {
        const headers = ['User', 'Age', 'Gender', 'Height', 'Weight', 'BMI', 'Activity', 'Profile status', 'Updated'];
        const content = rows.filter((row) => !row.hidden).map((row) => [...row.querySelectorAll('td')].slice(0, 9).map((cell) => cell.textContent.trim().replaceAll(/\s+/g, ' ')));
        const csv = [headers, ...content].map((row) => row.map((value) => `"${value.replaceAll('"', '""')}"`).join(',')).join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        link.href = url;
        link.download = 'nham-health-wellness-profiles.csv';
        link.click();
        URL.revokeObjectURL(url);
    });

    const modal = document.getElementById('profileModal');
    const form = document.getElementById('profileForm');
    const error = document.getElementById('formError');
    const saveButton = document.getElementById('saveProfileButton');
    const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
    const csrfHeader = document.querySelector('meta[name="_csrf_header"]')?.content;

    const uploadProfileImage = async (file) => {
        if (!(file instanceof File) || file.size === 0) return null;
        const uploadData = new FormData();
        uploadData.append('file', file);
        const response = await fetch('/admin/profile-images', {
            method: 'POST',
            headers: { 'Accept': 'application/json', ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}) },
            body: uploadData
        });
        const body = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(body.message || 'Unable to upload the profile image.');
        return body.profileImageUrl;
    };

    const setError = (message = '') => {
        if (!error) return;
        error.textContent = message;
        error.hidden = !message;
    };
    const openModal = (row) => {
        if (!modal || !form) return;
        form.reset();
        setError();
        const isEdit = Boolean(row);
        document.getElementById('profileModalTitle').textContent = isEdit ? 'Edit wellness profile' : 'Add wellness profile';
        if (row) {
            form.userEmail.value = row.dataset.email;
            form.profileImageUrl.value = row.dataset.image;
            form.gender.value = row.dataset.gender;
            form.dateOfBirth.value = row.dataset.dateOfBirth;
            form.heightCm.value = row.dataset.height;
            form.weightKg.value = row.dataset.weight;
            form.activityLevel.value = row.dataset.activity;
        }
        modal.classList.add('show');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('modal-open');
        form.userEmail.focus();
    };
    const closeModal = () => {
        modal?.classList.remove('show');
        modal?.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        setError();
    };

    document.getElementById('openModal')?.addEventListener('click', () => openModal());
    document.querySelectorAll('.edit-profile').forEach((button) => button.addEventListener('click', () => openModal(button.closest('tr'))));
    document.querySelectorAll('.delete-profile').forEach((button) => button.addEventListener('click', async () => {
        const row = button.closest('tr');
        if (!row?.dataset.id || !window.confirm('Delete this wellness profile? The user account and public profile will remain.')) return;
        button.disabled = true;
        try {
            const response = await fetch(`/admin/wellness-profiles/${row.dataset.id}`, {
                method: 'DELETE',
                headers: { 'Accept': 'application/json', ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}) }
            });
            if (!response.ok) {
                const body = await response.json().catch(() => ({}));
                throw new Error(body.message || 'Unable to delete this wellness profile.');
            }
            window.location.reload();
        } catch (exception) {
            window.alert(exception.message);
            button.disabled = false;
        }
    }));
    document.getElementById('closeModal')?.addEventListener('click', closeModal);
    document.getElementById('cancelModal')?.addEventListener('click', closeModal);
    modal?.addEventListener('click', (event) => { if (event.target === modal) closeModal(); });
    document.addEventListener('keydown', (event) => { if (event.key === 'Escape' && modal?.classList.contains('show')) closeModal(); });

    form?.addEventListener('submit', async (event) => {
        event.preventDefault();
        const formData = new FormData(form);
        const imageFile = formData.get('profileImageFile');
        formData.delete('profileImageFile');
        const payload = Object.fromEntries(formData.entries());
        setError();
        saveButton.disabled = true;
        saveButton.textContent = 'Saving…';
        try {
            const profileImageUrl = await uploadProfileImage(imageFile);
            if (profileImageUrl) payload.profileImageUrl = profileImageUrl;
            const response = await fetch('/admin/wellness-profiles', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}) },
                body: JSON.stringify(payload)
            });
            if (!response.ok) {
                const body = await response.json().catch(() => ({}));
                throw new Error(body.message || 'Unable to save this wellness profile.');
            }
            window.location.reload();
        } catch (exception) {
            setError(exception.message);
            saveButton.disabled = false;
            saveButton.textContent = 'Save profile';
        }
    });
})();
