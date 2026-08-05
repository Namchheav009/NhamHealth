(() => {
    const search = document.getElementById('postSearch');
    const status = document.getElementById('postStatus');
    const clearBtn = document.getElementById('clearPostFilters');
    const openBtn = document.getElementById('openPostModal');
    const modal = document.getElementById('postModal');
    const closeBtn = document.getElementById('closePostModal');
    const cancelBtn = document.getElementById('cancelPostModal');
    const form = document.getElementById('postForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-author]'));

    const apply = () => {
        const q = (search?.value || '').trim().toLowerCase();
        const s = (status?.value || '').toLowerCase();
        rows.forEach(r => {
            const a = (r.dataset.author || '').toLowerCase();
            const st = (r.dataset.status || '').toLowerCase();
            const match = (!q || a.includes(q) || r.innerText.toLowerCase().includes(q)) && (!s || st===s);
            r.hidden = !match;
        });
    };

    search?.addEventListener('input', apply);
    status?.addEventListener('change', apply);
    clearBtn?.addEventListener('click', () => { if (!search||!status) return; search.value=''; status.value=''; apply(); });
    openBtn?.addEventListener('click', ()=> modal?.classList.add('show'));
    closeBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    cancelBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    modal?.addEventListener('click', (e)=> { if (e.target===modal) modal.classList.remove('show'); });
    form?.addEventListener('submit', e=>{ e.preventDefault(); alert('Create endpoint not implemented yet.'); modal?.classList.remove('show'); });
    apply();
})();
