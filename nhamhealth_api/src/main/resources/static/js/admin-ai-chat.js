(() => {
    const search = document.getElementById('chatSearch');
    const status = document.getElementById('chatStatus');
    const clearBtn = document.getElementById('clearChatFilters');
    const openBtn = document.getElementById('openChatModal');
    const modal = document.getElementById('chatModal');
    const closeBtn = document.getElementById('closeChatModal');
    const cancelBtn = document.getElementById('cancelChatModal');
    const form = document.getElementById('chatForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-user]'));

    const apply = () => {
        const q = (search?.value || '').trim().toLowerCase();
        const s = (status?.value || '').toLowerCase();
        rows.forEach(r => {
            const u = (r.dataset.user || '').toLowerCase();
            const st = (r.dataset.status || '').toLowerCase();
            const match = (!q || u.includes(q) || r.innerText.toLowerCase().includes(q)) && (!s || st===s);
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
    form?.addEventListener('submit', e=>{ e.preventDefault(); alert('Create endpoint not yet implemented.'); modal?.classList.remove('show'); });
    apply();
})();
