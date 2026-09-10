(() => {
  const $ = id => document.getElementById(id);
  const fixedType = document.querySelector('meta[name="report-type"]')?.content || '';
  let currentPage = 0;
  let pageData = null;
  const label = value => String(value || '').toLowerCase().replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase());
  const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const targetLabel = report => report.targetSummary || (report.type === 'PROFILE' ? report.reportedUserName : `${label(report.type)} #${report.targetId}`);

  function params(page = 0) {
    const query = new URLSearchParams({page});
    const values = {type: fixedType || $('reportType')?.value, status: $('reportStatus').value,
      reason: $('reportReason').value, severity: $('reportSeverity').value, search: $('reportSearch').value.trim()};
    Object.entries(values).forEach(([key,value]) => { if(value) query.set(key,value); });
    if($('reportFrom').value) query.set('from', `${$('reportFrom').value}T00:00:00`);
    if($('reportTo').value) query.set('to', `${$('reportTo').value}T23:59:59`);
    return query;
  }

  async function load(page = 0) {
    $('reportRows').innerHTML = '<tr><td colspan="9" class="empty-state">Loading reports…</td></tr>';
    const response = await fetch(`/admin/reports/data?${params(page)}`);
    if(!response.ok) { $('reportRows').innerHTML='<tr><td colspan="9" class="empty-state">Reports could not be loaded.</td></tr>'; return; }
    pageData = await response.json(); currentPage = pageData.number; render();
  }

  function render() {
    const rows = pageData.content || [];
    $('resultSummary').textContent = `${pageData.totalElements} matching report${pageData.totalElements === 1 ? '' : 's'}`;
    $('pageSummary').textContent = pageData.totalElements ? `Page ${pageData.number + 1} of ${pageData.totalPages}` : '';
    $('reportRows').innerHTML = rows.length ? rows.map(r => `<tr><td><strong>#${r.id}</strong></td><td><span class="type-badge type-${r.type.toLowerCase()}">${label(r.type)}</span></td><td><strong>${escapeHtml(r.reporterName)}</strong><small>Private · ID ${r.reporterId}</small></td><td><strong>${escapeHtml(targetLabel(r))}</strong><small>${escapeHtml(r.reportedUserName)} · User ID ${r.reportedUserId}</small></td><td>${label(r.reason)}</td><td><span class="severity-badge severity-${r.severity.toLowerCase()}">${label(r.severity)}</span></td><td><span class="status-pill status-${r.status.toLowerCase()}">${label(r.status)}</span></td><td>${new Intl.DateTimeFormat(undefined,{dateStyle:'medium'}).format(new Date(r.createdAt))}</td><td class="report-actions"><a class="btn-small" href="/admin/reports/${r.id}">View</a><a class="btn-small primary" href="/admin/reports/${r.id}/review">Review</a></td></tr>`).join('') : '<tr><td colspan="9" class="empty-state">No reports found for these filters.</td></tr>';
    $('pagePrev').disabled = pageData.first; $('pageNext').disabled = pageData.last;
    $('pageNumbers').innerHTML = Array.from({length:pageData.totalPages},(_,i)=>Math.abs(i-currentPage)<=2?`<button class="page-btn ${i===currentPage?'active':''}" data-page="${i}">${i+1}</button>`:'').join('');
  }

  async function summary() {
    const data = await fetch('/admin/reports/summary').then(r => r.json());
    $('statTotal').textContent=data.total; $('statPending').textContent=data.pending; $('statReview').textContent=data.underReview; $('statResolved').textContent=data.resolved; $('statDismissed').textContent=data.dismissed;
  }

  let timer; const refresh = () => { clearTimeout(timer); timer=setTimeout(()=>load(0),250); };
  ['reportSearch','reportType','reportStatus','reportReason','reportSeverity','reportFrom','reportTo'].forEach(id => $(id)?.addEventListener(id==='reportSearch'?'input':'change',refresh));
  $('clearReportFilters').addEventListener('click',()=>{['reportSearch','reportType','reportStatus','reportReason','reportSeverity','reportFrom','reportTo'].forEach(id=>{if($(id))$(id).value='';});load(0);});
  $('refreshReports').addEventListener('click',()=>load(currentPage)); $('pagePrev').addEventListener('click',()=>load(currentPage-1)); $('pageNext').addEventListener('click',()=>load(currentPage+1)); $('pageNumbers').addEventListener('click',e=>{const b=e.target.closest('[data-page]');if(b)load(Number(b.dataset.page));});
  $('exportReports').addEventListener('click',()=>{const rows=pageData?.content||[];const csv=[['ID','Type','Reporter','Reported User','Target','Reason','Severity','Status','Created'],...rows.map(r=>[r.id,r.type,r.reporterName,r.reportedUserName,r.targetId,label(r.reason),r.severity,r.status,r.createdAt])].map(row=>row.map(v=>`"${String(v??'').replaceAll('"','""')}"`).join(',')).join('\n');const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([csv],{type:'text/csv'}));a.download='reports.csv';a.click();URL.revokeObjectURL(a.href);});
  summary(); load();
})();
