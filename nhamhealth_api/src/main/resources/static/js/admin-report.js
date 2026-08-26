(() => {
  const $ = id => document.getElementById(id);
  const tbody = $('reportRows');
  const search = $('reportSearch');
  const statusFilter = $('reportStatus');
  const modal = $('reportModal');
  const form = $('reportForm');
  const token = document.querySelector('meta[name="_csrf"]')?.content;
  const header = document.querySelector('meta[name="_csrf_header"]')?.content;
  const rows = () => [...tbody.querySelectorAll('tr[data-id]')];
  const csrfHeaders = () => token && header ? {[header]: token} : {};
  const escapeHtml = value => String(value ?? '').replace(/[&<>'"]/g,
    c => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'})[c]);
  const notify = (icon, title, text) => Swal.fire({icon, title, text, confirmButtonColor:'#078f4a'});

  function applyFilters() {
    const query = search.value.trim().toLowerCase();
    const status = statusFilter.value;
    rows().forEach(row => {
      row.hidden = !((!query || row.textContent.toLowerCase().includes(query))
        && (!status || row.dataset.status === status));
    });
  }

  function updateMetrics() {
    const all = rows();
    $('totalReports').textContent = all.length;
    $('uniqueReporters').textContent = new Set(all.map(row => row.dataset.reporterId).filter(Boolean)).size;
    $('pendingReports').textContent = all.filter(row => row.dataset.status === 'pending').length;
    all.forEach((row, index) => { row.cells[0].textContent = index + 1; });
  }

  function closeModal() { modal.classList.remove('show'); form.reset(); }

  function addRow(report) {
    tbody.querySelector('.empty-state')?.closest('tr')?.remove();
    const row = document.createElement('tr');
    Object.assign(row.dataset, {
      id: report.id, reporterId: report.reporterId, reporter: report.reporterEmail,
      status: report.status, action: report.action || ''
    });
    const created = new Intl.DateTimeFormat(undefined, {
      day:'2-digit', month:'short', year:'numeric', hour:'2-digit', minute:'2-digit'
    }).format(new Date(report.createdAt));
    row.innerHTML = `<td></td>
      <td><strong>${escapeHtml(report.reporterName)}</strong><small>${escapeHtml(report.reporterEmail)}</small></td>
      <td class="target-cell"><button class="target-link view-report-target" type="button"><strong>${escapeHtml(report.targetType || 'post')}</strong><span>${escapeHtml(report.targetSummary)}</span></button></td>
      <td>${escapeHtml(report.reason)}</td>
      <td><span class="status-pill status-${escapeHtml(report.status)}">${escapeHtml(report.status.replace('_', ' '))}</span></td>
      <td>${escapeHtml(report.reviewer || 'Not reviewed')}</td>
      <td>${created}</td>
      <td><button class="btn-small view-report-target" type="button"><i class="fa-solid fa-eye"></i> View</button><button class="btn-small review-report" type="button"><i class="fa-solid fa-gavel"></i> Review</button></td>`;
    tbody.prepend(row);
    updateMetrics();
    applyFilters();
  }

  form.addEventListener('submit', async event => {
    event.preventDefault();
    const submit = form.querySelector('[type="submit"]');
    submit.disabled = true;
    try {
      const response = await fetch(form.action, {method:'POST', headers:csrfHeaders(), body:new FormData(form)});
      const data = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(data.message || 'The report could not be created.');
      addRow(data);
      closeModal();
      Swal.fire({icon:'success', title:'Report created', text:'Added to the moderation queue.', timer:1700, showConfirmButton:false});
    } catch (error) {
      notify('error', 'Create failed', error.message);
    } finally {
      submit.disabled = false;
    }
  });

  function reviewDialog(row) {
    const currentStatus = row.dataset.status;
    const currentAction = row.dataset.action || 'none';
    return Swal.fire({
      title: 'Review report',
      html: `<label class="swal-label" for="reportReviewStatus">Decision status</label>
        <select id="reportReviewStatus" class="swal2-select">
          <option value="pending">Pending</option>
          <option value="under_review">Under review</option>
          <option value="resolved">Resolved — violation confirmed</option>
          <option value="dismissed">Dismissed — keep content</option>
        </select>
        <label class="swal-label" for="reportReviewAction">Moderation action</label>
        <select id="reportReviewAction" class="swal2-select">
          <option value="none">No action</option>
          <option value="keep">Keep content</option>
          <option value="warn">Warn user</option>
          <option value="remove">Remove content</option>
          <option value="suspend">Remove + suspend user</option>
          <option value="ban">Remove + ban user</option>
        </select>
        <label class="swal-label" for="reportAdminNote">Internal note (optional)</label>
        <textarea id="reportAdminNote" class="swal2-textarea" placeholder="Visible to administrators only"></textarea>`,
      showCancelButton: true,
      confirmButtonText: 'Save decision',
      confirmButtonColor: '#078f4a',
      didOpen: () => {
        $('reportReviewStatus').value = currentStatus;
        $('reportReviewAction').value = currentAction;
      },
      preConfirm: () => ({
        status: $('reportReviewStatus').value,
        action: $('reportReviewAction').value,
        adminNote: $('reportAdminNote').value.trim()
      })
    });
  }

  tbody.addEventListener('click', async event => {
    const targetButton = event.target.closest('.view-report-target');
    if (targetButton) {
      const row = targetButton.closest('tr[data-id]');
      try {
        const response = await fetch(`/admin/reports/${row.dataset.id}/target`, {headers: csrfHeaders()});
        const target = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(target.message || 'The reported content is no longer available.');
        const images = (target.imageUrls || []).map(url =>
          `<img src="${escapeHtml(url)}" alt="Attachment from reported post">`).join('');
        const createdAt = target.createdAt
          ? new Intl.DateTimeFormat(undefined, {dateStyle: 'medium', timeStyle: 'short'}).format(new Date(target.createdAt))
          : 'Unknown date';
        await Swal.fire({
          title: `Reported ${escapeHtml(target.targetType || 'content')}`,
          html: `<div class="report-preview">
              <div class="report-preview-meta"><strong>${escapeHtml(target.author)}</strong> (${escapeHtml(target.authorEmail)})<br>
                Status: ${escapeHtml(target.contentStatus)} &middot; ${escapeHtml(createdAt)}</div>
              <div class="report-preview-content">${escapeHtml(target.content)}</div>
              ${images ? `<div class="report-preview-images">${images}</div>` : ''}
            </div>`,
          confirmButtonText: 'Close',
          confirmButtonColor: '#078f4a'
        });
      } catch (error) {
        notify('error', 'Unable to load content', error.message);
      }
      return;
    }
    const button = event.target.closest('.review-report');
    if (!button) return;
    const row = button.closest('tr[data-id]');
    const result = await reviewDialog(row);
    if (!result.isConfirmed) return;
    try {
      const body = new URLSearchParams(result.value);
      const response = await fetch(`/admin/reports/${row.dataset.id}/status`, {
        method:'PATCH', headers:{...csrfHeaders(), 'Content-Type':'application/x-www-form-urlencoded'}, body
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) throw new Error(data.message || 'The decision could not be saved.');
      row.dataset.status = data.status;
      row.dataset.action = data.action || '';
      const pill = row.querySelector('.status-pill');
      pill.className = `status-pill status-${data.status}`;
      pill.textContent = data.status.replace('_', ' ');
      row.cells[5].textContent = data.status === 'pending' ? 'Not reviewed' : (data.reviewer || 'Reviewed');
      updateMetrics();
      applyFilters();
      Swal.fire({icon:'success', title:'Review saved', timer:1400, showConfirmButton:false});
    } catch (error) {
      notify('error', 'Review failed', error.message);
    }
  });

  $('openReportModal').addEventListener('click', () => { modal.classList.add('show'); $('reportReporter').focus(); });
  $('closeReportModal').addEventListener('click', closeModal);
  $('cancelReportModal').addEventListener('click', closeModal);
  modal.addEventListener('click', event => { if (event.target === modal) closeModal(); });
  document.addEventListener('keydown', event => { if (event.key === 'Escape' && modal.classList.contains('show')) closeModal(); });
  search.addEventListener('input', applyFilters);
  statusFilter.addEventListener('change', applyFilters);
  $('clearReportFilters').addEventListener('click', () => { search.value = ''; statusFilter.value = ''; applyFilters(); });
  $('refreshReports').addEventListener('click', () => location.reload());
  $('exportReports').addEventListener('click', () => {
    const data = [['Reporter','Target','Reason','Status','Reviewer','Created'], ...rows().filter(row => !row.hidden)
      .map(row => [...row.cells].slice(1, 7).map(cell => cell.innerText.trim()))];
    const csv = data.map(values => values.map(value => `"${value.replace(/"/g, '""')}"`).join(',')).join('\n');
    const link = document.createElement('a');
    link.href = URL.createObjectURL(new Blob([csv], {type:'text/csv;charset=utf-8'}));
    link.download = `reports-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(link.href);
  });
  updateMetrics();
  applyFilters();
})();
