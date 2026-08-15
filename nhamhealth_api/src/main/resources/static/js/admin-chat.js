(() => {
    const $ = id => document.getElementById(id);
    const tbody = $('chatRows'), search = $('chatSearch'), typeFilter = $('chatType');
    const modal = $('chatModal'), form = $('chatForm'), typeField = $('chatTypeField');
    const participantSelect = $('chatParticipants');
    const token = document.querySelector('meta[name="_csrf"]')?.content;
    const header = document.querySelector('meta[name="_csrf_header"]')?.content;
    const rows = () => [...tbody.querySelectorAll('tr[data-id]')];
    const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'})[c]);
    const csrfHeaders = () => token && header ? { [header]: token } : {};

    function applyFilters() {
        const query = search.value.trim().toLowerCase(), type = typeFilter.value;
        rows().forEach(row => { row.hidden = !((!query || row.textContent.toLowerCase().includes(query)) && (!type || row.dataset.type === type)); });
    }
    function updateMetrics() {
        $('totalChats').textContent = rows().length;
        rows().forEach((row, index) => { row.cells[0].textContent = index + 1; });
    }
    function updateHelp() {
        const direct = typeField.value === 'direct';
        $('participantHelp').textContent = direct ? 'Direct chats require exactly two users.' : 'Select one or more group participants.';
        $('chatName').placeholder = direct ? 'Optional — participant names will be used' : 'Group chat name';
    }
    function closeModal() { modal.classList.remove('show'); form.reset(); updateHelp(); }
    function notify(icon, title, text) { return Swal.fire({ icon, title, text, confirmButtonColor:'#078f4a' }); }
    function addRow(chat) {
        tbody.querySelector('.empty-state')?.closest('tr')?.remove();
        const row = document.createElement('tr');
        Object.assign(row.dataset, { id:chat.id, chat:chat.chatName, type:chat.chatType, participants:chat.participantCount });
        const created = new Intl.DateTimeFormat(undefined, {day:'2-digit',month:'short',year:'numeric',hour:'2-digit',minute:'2-digit'}).format(new Date(chat.createdAt));
        row.innerHTML = `<td></td><td><strong>${escapeHtml(chat.chatName)}</strong></td><td><span class="type-pill type-${escapeHtml(chat.chatType)}">${escapeHtml(chat.chatType)}</span></td><td>${chat.participantCount}</td><td>${chat.messageCount}</td><td>No messages</td><td>${created}</td>`;
        tbody.prepend(row); updateMetrics(); applyFilters();
    }

    form.addEventListener('submit', async event => {
        event.preventDefault();
        const selectedCount = participantSelect.selectedOptions.length;
        if (typeField.value === 'direct' && selectedCount !== 2) {
            return notify('warning', 'Choose two users', 'A direct chat must contain exactly two participants.');
        }
        if (typeField.value === 'group' && !$('chatName').value.trim()) {
            return notify('warning', 'Chat name required', 'Enter a name for the group chat.');
        }
        const submit = form.querySelector('[type="submit"]'); submit.disabled = true;
        try {
            const response = await fetch(form.action, { method:'POST', headers:csrfHeaders(), body:new FormData(form) });
            const data = await response.json().catch(() => ({}));
            if (!response.ok) throw new Error(data.message || 'The chat could not be created.');
            addRow(data); closeModal();
            Swal.fire({icon:'success',title:'Chat created',text:'The selected users are now connected to this chat.',timer:1800,showConfirmButton:false});
        } catch (error) { notify('error', 'Create failed', error.message); } finally { submit.disabled = false; }
    });

    $('openChatModal').addEventListener('click', () => { modal.classList.add('show'); $('chatName').focus(); });
    $('closeChatModal').addEventListener('click', closeModal); $('cancelChatModal').addEventListener('click', closeModal);
    modal.addEventListener('click', event => { if (event.target === modal) closeModal(); });
    document.addEventListener('keydown', event => { if (event.key === 'Escape' && modal.classList.contains('show')) closeModal(); });
    typeField.addEventListener('change', updateHelp); search.addEventListener('input', applyFilters); typeFilter.addEventListener('change', applyFilters);
    $('clearChatFilters').addEventListener('click', () => { search.value=''; typeFilter.value=''; applyFilters(); });
    $('refreshChats').addEventListener('click', () => location.reload());
    $('exportChats').addEventListener('click', () => {
        const data = [['Chat','Type','Participants','Messages','Last Message','Created'], ...rows().filter(row => !row.hidden).map(row => [...row.cells].slice(1).map(cell => cell.innerText.trim()))];
        const csv = data.map(values => values.map(value => `"${value.replace(/"/g,'""')}"`).join(',')).join('\n');
        const link = document.createElement('a'); link.href=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'})); link.download=`chats-${new Date().toISOString().slice(0,10)}.csv`; link.click(); URL.revokeObjectURL(link.href);
        Swal.fire({icon:'success',title:'Export ready',timer:1200,showConfirmButton:false});
    });
    updateHelp(); updateMetrics(); applyFilters();
})();
