(() => {
    const $ = id => document.getElementById(id);
    const tbody = $('postRows'), search = $('postSearch'), statusFilter = $('postStatus');
    const modal = $('postModal'), form = $('postForm'), submit = $('postSubmit');
    const token = document.querySelector('meta[name="_csrf"]')?.content;
    const header = document.querySelector('meta[name="_csrf_header"]')?.content;
    const rows = () => [...tbody.querySelectorAll('tr[data-id]')];
    const csrfHeaders = () => token && header ? { [header]: token } : {};
    const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'})[c]);
    const notify = (icon, title, text) => Swal.fire({ icon, title, text, confirmButtonColor: '#078f4a' });
    const postUrl = id => `/admin/posts/${id}`;

    function applyFilters() {
        const query = search.value.trim().toLowerCase(), status = statusFilter.value;
        rows().forEach(row => row.hidden = !((!query || row.textContent.toLowerCase().includes(query)) && (!status || row.dataset.status === status)));
    }
    function updateMetrics() {
        const all = rows();
        $('totalPosts').textContent = all.length;
        $('activeAuthors').textContent = new Set(all.map(row => row.dataset.userId).filter(Boolean)).size;
        $('pendingReports').textContent = all.reduce((sum, row) => sum + Number(row.dataset.reports || 0), 0);
        all.forEach((row, index) => { row.cells[0].textContent = index + 1; });
    }
    const statusClass = status => `status-${String(status).toLowerCase()}`;
    function resetForm() {
        form.reset();
        $('editingPostId').value = '';
        $('postAuthor').disabled = false;
        $('removeImagesField').hidden = true;
        $('postModalTitle').textContent = 'New Post';
        $('postModalTitle').nextElementSibling.textContent = 'Create a new community post.';
        submit.textContent = 'Create Post';
    }
    function closeModal() { modal.classList.remove('show'); resetForm(); }
    function openCreateModal() { resetForm(); modal.classList.add('show'); $('postAuthor').focus(); }
    function openEditModal(row) {
        resetForm();
        $('editingPostId').value = row.dataset.id;
        $('postAuthor').value = row.dataset.userId;
        $('postAuthor').disabled = true;
        $('postCaption').value = row.dataset.caption || '';
        $('postVisibility').value = row.dataset.visibility || 'PUBLIC';
        $('postStatusField').value = row.dataset.status || 'ACTIVE';
        $('removeImagesField').hidden = false;
        $('postModalTitle').textContent = 'Edit Post';
        $('postModalTitle').nextElementSibling.textContent = 'Update the post content, visibility, status, or images.';
        submit.textContent = 'Save Changes';
        modal.classList.add('show');
        $('postCaption').focus();
    }
    function addRow(post) {
        tbody.querySelector('.empty-state')?.closest('tr')?.remove();
        const row = document.createElement('tr');
        Object.assign(row.dataset, { id: post.id, userId: post.userId, author: post.authorName, caption: post.caption, visibility: post.visibility, status: post.status, reports: post.reportCount });
        const updated = new Intl.DateTimeFormat(undefined, { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }).format(new Date(post.updatedAt));
        row.innerHTML = `<td></td><td><strong>${escapeHtml(post.authorName)}</strong><small>${escapeHtml(post.authorEmail)}</small></td><td class="caption-cell">${escapeHtml(post.caption)}</td><td><span class="visibility-pill">${escapeHtml(post.visibility)}</span></td><td><span class="status-pill ${statusClass(post.status)}">${escapeHtml(post.status)}</span></td><td>${post.commentCount}</td><td>${post.likeCount}</td><td>${post.favoriteCount}</td><td>${post.reportCount}</td><td>${updated}</td><td><button class="btn-small edit-post" type="button"><i class="fa-solid fa-pen"></i> Edit</button><button class="btn-small delete-post" type="button"><i class="fa-solid fa-trash"></i> Delete</button></td>`;
        tbody.prepend(row); updateMetrics(); applyFilters();
    }
    function updateRow(row, post) {
        Object.assign(row.dataset, { caption: post.caption, visibility: post.visibility, status: post.status, reports: post.reportCount });
        row.cells[2].textContent = post.caption;
        row.cells[3].querySelector('span').textContent = post.visibility;
        const pill = row.cells[4].querySelector('span');
        pill.className = `status-pill ${statusClass(post.status)}`;
        pill.textContent = post.status;
        row.cells[5].textContent = post.commentCount;
        row.cells[6].textContent = post.likeCount;
        row.cells[7].textContent = post.favoriteCount;
        row.cells[8].textContent = post.reportCount;
        row.cells[9].textContent = new Intl.DateTimeFormat(undefined, { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }).format(new Date(post.updatedAt));
        updateMetrics(); applyFilters();
    }

    form.addEventListener('submit', async event => {
        event.preventDefault();
        const editingId = $('editingPostId').value;
        if ($('postImages').files.length > 6) { notify('error', 'Too many images', 'A post can have at most 6 images.'); return; }
        submit.disabled = true;
        try {
            const response = await fetch(editingId ? postUrl(editingId) : form.action, { method: editingId ? 'PUT' : 'POST', headers: csrfHeaders(), body: new FormData(form) });
            const data = await response.json().catch(() => ({}));
            if (!response.ok) throw new Error(data.message || 'The post could not be saved.');
            if (editingId) updateRow(rows().find(row => row.dataset.id === editingId), data); else addRow(data);
            closeModal();
            Swal.fire({ icon: 'success', title: editingId ? 'Post updated' : 'Post created', timer: 1500, showConfirmButton: false });
        } catch (error) { notify('error', 'Save failed', error.message); } finally { submit.disabled = false; }
    });
    tbody.addEventListener('click', async event => {
        const edit = event.target.closest('.edit-post');
        if (edit) { openEditModal(edit.closest('tr[data-id]')); return; }
        const remove = event.target.closest('.delete-post');
        if (!remove) return;
        const row = remove.closest('tr[data-id]');
        const result = await Swal.fire({ title: 'Delete this post?', text: 'The post will be hidden from the Community feed.', icon: 'warning', showCancelButton: true, confirmButtonText: 'Delete post', confirmButtonColor: '#c62828' });
        if (!result.isConfirmed) return;
        try {
            const response = await fetch(postUrl(row.dataset.id), { method: 'DELETE', headers: csrfHeaders() });
            const data = await response.json().catch(() => ({}));
            if (!response.ok) throw new Error(data.message || 'The post could not be deleted.');
            updateRow(row, data);
            Swal.fire({ icon: 'success', title: 'Post deleted', timer: 1400, showConfirmButton: false });
        } catch (error) { notify('error', 'Delete failed', error.message); }
    });
    $('openPostModal').addEventListener('click', openCreateModal);
    $('closePostModal').addEventListener('click', closeModal); $('cancelPostModal').addEventListener('click', closeModal);
    modal.addEventListener('click', event => { if (event.target === modal) closeModal(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape' && modal.classList.contains('show')) closeModal(); });
    search.addEventListener('input', applyFilters); statusFilter.addEventListener('change', applyFilters);
    $('clearPostFilters').addEventListener('click', () => { search.value = ''; statusFilter.value = ''; applyFilters(); });
    $('refreshPosts').addEventListener('click', () => location.reload());
    $('exportPosts').addEventListener('click', () => {
        const data = [['Author', 'Post', 'Visibility', 'Status', 'Comments', 'Likes', 'Favorites', 'Reports', 'Updated'], ...rows().filter(row => !row.hidden).map(row => [...row.cells].slice(1, 10).map(cell => cell.innerText.trim()))];
        const csv = data.map(values => values.map(value => `"${value.replace(/"/g, '""')}"`).join(',')).join('\n');
        const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' })); link.download = `posts-${new Date().toISOString().slice(0, 10)}.csv`; link.click(); URL.revokeObjectURL(link.href);
    });
    updateMetrics(); applyFilters();
})();
