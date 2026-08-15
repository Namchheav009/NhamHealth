(() => {
    const $ = id => document.getElementById(id);
    const search = $('recSearch'), statusFilter = $('statusFilter'), tbody = $('recommendationRows');
    const modal = $('recModal'), form = $('recForm');
    const token = document.querySelector('meta[name="_csrf"]')?.content;
    const header = document.querySelector('meta[name="_csrf_header"]')?.content;
    const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'})[c]);
    const csrfHeaders = () => token && header ? { [header]: token } : {};
    const rows = () => [...tbody.querySelectorAll('tr[data-id]')];
    const alert = (icon, title, text) => Swal.fire({ icon, title, text, confirmButtonColor: '#078f4a' });
    const statusClass = status => status === 'ready' ? 'status-active' : status === 'archived' ? 'status-neutral' : 'status-inactive';

    function updateMetrics() {
        const all = rows();
        $('totalRecommendations').textContent = all.length;
        $('uniqueUsers').textContent = new Set(all.map(row => row.dataset.userId).filter(Boolean)).size;
        $('totalItems').textContent = all.reduce((sum, row) => sum + Number(row.dataset.items || 0), 0);
        all.forEach((row, index) => { row.cells[0].textContent = index + 1; });
    }
    function applyFilters() {
        const query = search.value.trim().toLowerCase(), status = statusFilter.value;
        rows().forEach(row => { row.hidden = !((!query || row.textContent.toLowerCase().includes(query)) && (!status || row.dataset.status === status)); });
    }
    function closeModal() { modal.classList.remove('show'); form.reset(); }
    function addRow(rec) {
        tbody.querySelector('.empty-state')?.closest('tr')?.remove();
        const row = document.createElement('tr');
        Object.assign(row.dataset, { id: rec.id, userId: rec.userId, user: rec.userName, status: rec.status, items: rec.itemCount });
        const created = new Intl.DateTimeFormat(undefined, {day:'2-digit',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit'}).format(new Date(rec.createdAt));
        row.innerHTML = `<td></td><td><strong>${escapeHtml(rec.userName)}</strong><small>${escapeHtml(rec.userEmail)}</small></td><td>${escapeHtml(rec.requestText)}</td><td>${escapeHtml(rec.responseText) || '<span class="muted">No response yet</span>'}</td><td><span class="status-pill ${statusClass(rec.status)}">${escapeHtml(rec.status)}</span></td><td>${rec.itemCount}</td><td>${created}</td><td><button class="icon-button delete-recommendation" type="button" aria-label="Delete recommendation"><i class="fa-solid fa-trash"></i></button></td>`;
        tbody.prepend(row); updateMetrics(); applyFilters();
    }

    form.addEventListener('submit', async event => {
        event.preventDefault(); const submit = form.querySelector('[type="submit"]'); submit.disabled = true;
        try {
            const response = await fetch(form.action, { method: 'POST', headers: csrfHeaders(), body: new FormData(form) });
            const data = await response.json().catch(() => ({}));
            if (!response.ok) throw new Error(data.message || 'The recommendation could not be saved.');
            addRow(data); closeModal();
            Swal.fire({ icon:'success', title:'Recommendation added', text:'Connected to the selected user.', timer:1800, showConfirmButton:false });
        } catch (error) { alert('error', 'Save failed', error.message); } finally { submit.disabled = false; }
    });
    tbody.addEventListener('click', async event => {
        const button = event.target.closest('.delete-recommendation'); if (!button) return;
        const row = button.closest('tr[data-id]');
        const result = await Swal.fire({ icon:'warning', title:'Delete recommendation?', text:'Its linked recommendation items will also be removed.', showCancelButton:true, confirmButtonText:'Delete', confirmButtonColor:'#dc2626' });
        if (!result.isConfirmed) return;
        try {
            const response = await fetch(`/admin/ai-recommendations/${row.dataset.id}`, { method:'DELETE', headers:csrfHeaders() });
            if (!response.ok) throw new Error('The recommendation could not be deleted.');
            row.remove(); updateMetrics(); alert('success', 'Deleted', 'The recommendation and linked items were removed.');
        } catch (error) { alert('error', 'Delete failed', error.message); }
    });
    $('openRecModal').addEventListener('click', () => { modal.classList.add('show'); $('recUser')?.focus(); });
    $('closeRecModal').addEventListener('click', closeModal); $('cancelRecModal').addEventListener('click', closeModal);
    modal.addEventListener('click', event => { if (event.target === modal) closeModal(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape' && modal.classList.contains('show')) closeModal(); });
    search.addEventListener('input', applyFilters); statusFilter.addEventListener('change', applyFilters);
    $('clearFilters').addEventListener('click', () => { search.value=''; statusFilter.value=''; applyFilters(); });
    $('refreshRecommendations').addEventListener('click', () => location.reload());
    $('exportRecommendations').addEventListener('click', () => {
        const data = [['User','Request','Response','Status','Items','Created'], ...rows().filter(row => !row.hidden).map(row => [...row.cells].slice(1,7).map(cell => cell.innerText.trim()))];
        const csv = data.map(values => values.map(value => `"${value.replace(/"/g,'""')}"`).join(',')).join('\n');
        const link = document.createElement('a'); link.href = URL.createObjectURL(new Blob([csv], {type:'text/csv;charset=utf-8'})); link.download = `ai-recommendations-${new Date().toISOString().slice(0,10)}.csv`; link.click(); URL.revokeObjectURL(link.href);
        Swal.fire({icon:'success',title:'Export ready',timer:1200,showConfirmButton:false});
    });
    updateMetrics(); applyFilters();
})();
