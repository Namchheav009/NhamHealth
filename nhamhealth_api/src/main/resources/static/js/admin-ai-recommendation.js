(() => {
    const searchInput = document.getElementById('recSearch');
    const typeFilter = document.getElementById('typeFilter');
    const statusFilter = document.getElementById('typeFilter') || null; // reuse dropdown as status selector
    const clearBtn = document.getElementById('clearFilters');
    const openBtn = document.getElementById('openRecModal');
    const modal = document.getElementById('recModal');
    const closeBtn = document.getElementById('closeRecModal');
    const cancelBtn = document.getElementById('cancelRecModal');
    const form = document.getElementById('recForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-user]'));

    const apply = () => {
        const q = (searchInput?.value || '').trim().toLowerCase();
        const type = (statusFilter?.value || '').toLowerCase();
        rows.forEach(row => {
            const user = (row.dataset.user || '').toLowerCase();
            const t = (row.dataset.status || '').toLowerCase();
            const match = (!q || user.includes(q) || row.innerText.toLowerCase().includes(q)) && (!type || t===type);
            row.hidden = !match;
        });
    };

    searchInput?.addEventListener('input', apply);
    typeFilter?.addEventListener('change', apply);
    clearBtn?.addEventListener('click', () => { if (!searchInput||!typeFilter) return; searchInput.value=''; typeFilter.value=''; apply(); });
    openBtn?.addEventListener('click', ()=> modal?.classList.add('show'));
    closeBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    cancelBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    modal?.addEventListener('click', (e)=> { if (e.target===modal) modal.classList.remove('show'); });
    form?.addEventListener('submit', e=>{ e.preventDefault(); alert('Connect this form to your save endpoint.'); modal?.classList.remove('show'); });
    apply();
})();
