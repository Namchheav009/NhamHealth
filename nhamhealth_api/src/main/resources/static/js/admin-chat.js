(function(){
    const search = document.getElementById('chatSearch');
    const type = document.getElementById('chatType');
    const clearBtn = document.getElementById('clearChatFilters');
    const openBtn = document.getElementById('openChatModal');
    const modal = document.getElementById('chatModal');
    const closeBtn = document.getElementById('closeChatModal');
    const cancelBtn = document.getElementById('cancelChatModal');
    const form = document.getElementById('chatForm');
    const rows = Array.from(document.querySelectorAll('tbody tr[data-chat]'));

    const apply = () => {
        const q = (search?.value || '').trim().toLowerCase();
        const t = (type?.value || '').toLowerCase();
        rows.forEach(r => {
            const a = (r.dataset.chat || '').toLowerCase();
            const tt = (r.dataset.type || '').toLowerCase();
            const match = (!q || a.includes(q) || r.innerText.toLowerCase().includes(q)) && (!t || tt===t);
            r.hidden = !match;
        });
    };

    search?.addEventListener('input', apply);
    type?.addEventListener('change', apply);
    clearBtn?.addEventListener('click', () => { if (!search||!type) return; search.value=''; type.value=''; apply(); });
    openBtn?.addEventListener('click', ()=> modal?.classList.add('show'));
    closeBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    cancelBtn?.addEventListener('click', ()=> modal?.classList.remove('show'));
    modal?.addEventListener('click', (e)=> { if (e.target===modal) modal.classList.remove('show'); });
    form?.addEventListener('submit', e=>{ e.preventDefault(); alert('Create endpoint not implemented yet.'); modal?.classList.remove('show'); });
    apply();
})();
