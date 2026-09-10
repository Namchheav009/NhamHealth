(() => {
  const root = document.querySelector('.report-detail-page');
  if (!root) return;

  const id = root.dataset.reportId;
  const type = root.dataset.reportType;
  const returnUrl = root.dataset.returnUrl || '/admin/reports';

  const startReviewBtn = document.getElementById('startReview');
  const submitDecisionBtn = document.getElementById('submitDecision');
  const actionFields = document.getElementById('actionFields');
  const actionType = document.getElementById('actionType');
  const durationField = document.getElementById('durationField');
  const duration = document.getElementById('duration');
  const durationLabel = document.getElementById('durationLabel');
  const customDates = document.getElementById('customDates');
  const startsAt = document.getElementById('startsAt');
  const expiresAt = document.getElementById('expiresAt');
  const escalateFields = document.getElementById('escalateFields');
  const escalateSeverity = document.getElementById('escalateSeverity');
  const adminNote = document.getElementById('adminNote');
  const charCount = document.getElementById('charCount');

  const token = document.querySelector('meta[name="_csrf"]')?.content;
  const header = document.querySelector('meta[name="_csrf_header"]')?.content;
  const headers = {
    'Content-Type': 'application/json',
    ...(token && header ? { [header]: token } : {})
  };

  // Start review handler
  if (startReviewBtn) {
    startReviewBtn.addEventListener('click', async () => {
      startReviewBtn.disabled = true;
      startReviewBtn.innerHTML = '<span class="button-spinner"></span> Starting review workflow...';
      try {
        const response = await fetch('/admin/reports/' + id + '/start-review', {
          method: 'PATCH',
          headers,
          body: '{}'
        });
        const data = await response.json().catch(() => ({}));
        if (!response.ok) {
          startReviewBtn.disabled = false;
          startReviewBtn.innerHTML = '<i class="bi bi-play-circle"></i> Start Review Workflow';
          await Swal.fire('Unable to start review', data.message || 'Please refresh and try again.', 'error');
          return;
        }
        location.reload();
      } catch (err) {
        startReviewBtn.disabled = false;
        startReviewBtn.innerHTML = '<i class="bi bi-play-circle"></i> Start Review Workflow';
        await Swal.fire('Network Error', 'Could not reach server. Please try again.', 'error');
      }
    });
  }

  // Character counter for admin note
  if (adminNote && charCount) {
    const updateCount = () => {
      const len = adminNote.value.length;
      charCount.textContent = len + ' / 1000';
      if (len > 900) {
        charCount.style.color = '#b42318';
        charCount.style.fontWeight = '700';
      } else {
        charCount.style.color = '#94a3b8';
        charCount.style.fontWeight = '500';
      }
    };
    adminNote.addEventListener('input', updateCount);
    updateCount();
  }

  if (!submitDecisionBtn || !actionType) return;

  // Grouped action definitions
  const actionGroups = {
    PROFILE: [
      {
        label: 'Guidelines Warning',
        items: [
          ['WARNING', 'Warning User']
        ]
      },
      {
        label: 'Account Restrictions',
        items: [
          ['POST_RESTRICTED', 'Restrict Posting'],
          ['COMMENT_RESTRICTED', 'Restrict Commenting'],
          ['ACCOUNT_RESTRICTED', 'Restrict Account']
        ]
      },
      {
        label: 'Account Sanctions',
        items: [
          ['SUSPENDED', 'Temporary Suspend Account'],
          ['BANNED', 'Permanent Ban']
        ]
      }
    ],
    POST: [
      {
        label: 'Guidelines Warning',
        items: [
          ['WARNING', 'Warning User']
        ]
      },
      {
        label: 'Content Moderation',
        items: [
          ['CONTENT_HIDDEN', 'Hide Post'],
          ['CONTENT_REMOVED', 'Remove Post'],
          ['CONTENT_RESTORED', 'Restore Content']
        ]
      },
      {
        label: 'Account Restrictions',
        items: [
          ['POST_RESTRICTED', 'Restrict Posting'],
          ['COMMENT_RESTRICTED', 'Restrict Commenting']
        ]
      },
      {
        label: 'Account Sanctions',
        items: [
          ['SUSPENDED', 'Temporary Suspend Account'],
          ['BANNED', 'Permanent Ban']
        ]
      }
    ],
    COMMENT: [
      {
        label: 'Guidelines Warning',
        items: [
          ['WARNING', 'Warning User']
        ]
      },
      {
        label: 'Content Moderation',
        items: [
          ['CONTENT_HIDDEN', 'Hide Comment'],
          ['CONTENT_REMOVED', 'Remove Comment'],
          ['CONTENT_RESTORED', 'Restore Content']
        ]
      },
      {
        label: 'Account Restrictions',
        items: [
          ['COMMENT_RESTRICTED', 'Restrict Commenting'],
          ['POST_RESTRICTED', 'Restrict Posting']
        ]
      },
      {
        label: 'Account Sanctions',
        items: [
          ['SUSPENDED', 'Temporary Suspend Account'],
          ['BANNED', 'Permanent Ban']
        ]
      }
    ]
  };

  const currentGroups = actionGroups[type] || actionGroups.POST;
  actionType.innerHTML = currentGroups.map(group => {
    const options = group.items.map(([val, lbl]) => '<option value="' + val + '">' + lbl + '</option>').join('');
    return '<optgroup label="' + group.label + '">' + options + '</optgroup>';
  }).join('');

  const sync = () => {
    const decisionRadio = document.querySelector('[name="decision"]:checked');
    const decision = decisionRadio ? decisionRadio.value : 'none';
    const action = actionType.value;

    const isViolation = decision === 'violation';
    const isEscalate = decision === 'escalate';

    if (actionFields) actionFields.hidden = !isViolation;
    if (escalateFields) escalateFields.hidden = !isEscalate;

    if (decision === 'none') {
      submitDecisionBtn.innerHTML = '<i class="bi bi-check-circle"></i> Dismiss Report';
      submitDecisionBtn.className = 'btn btn-primary action-button';
    } else if (decision === 'escalate') {
      submitDecisionBtn.innerHTML = '<i class="bi bi-arrow-up-right-circle"></i> Escalate for Review';
      submitDecisionBtn.className = 'btn action-button btn-escalate';
    } else {
      submitDecisionBtn.innerHTML = '<i class="bi bi-shield-check"></i> Apply Moderation Action';
      submitDecisionBtn.className = 'btn btn-primary action-button';
    }

    const hasDuration = ['SUSPENDED', 'POST_RESTRICTED', 'COMMENT_RESTRICTED'].includes(action);
    if (durationField) durationField.hidden = !isViolation || !hasDuration;

    if (durationLabel) {
      if (action === 'SUSPENDED') durationLabel.textContent = 'Suspension duration';
      else if (action === 'POST_RESTRICTED') durationLabel.textContent = 'Posting restriction duration';
      else if (action === 'COMMENT_RESTRICTED') durationLabel.textContent = 'Commenting restriction duration';
      else durationLabel.textContent = 'Duration';
    }

    if (customDates) {
      customDates.hidden = !isViolation || !hasDuration || duration.value !== 'custom';
    }
  };

  document.querySelectorAll('[name="decision"]').forEach(radio => radio.addEventListener('change', sync));
  actionType.addEventListener('change', sync);
  if (duration) duration.addEventListener('change', sync);
  sync();

  submitDecisionBtn.addEventListener('click', async () => {
    const decisionRadio = document.querySelector('[name="decision"]:checked');
    const decision = decisionRadio ? decisionRadio.value : 'none';
    const action = actionType.value;
    const durationVal = duration ? duration.value : '7';
    const durationText = durationVal === 'custom' ? 'the selected custom dates' : durationVal + ' days';

    let title = 'Confirm Decision?';
    let text = 'Are you sure you want to proceed with this decision?';
    let confirmButtonText = 'Confirm';

    if (decision === 'none') {
      title = 'Dismiss Report without Action?';
      text = 'The report will be marked as reviewed and resolved with no disciplinary action taken against the reported user.';
      confirmButtonText = 'Dismiss Report';
    } else if (decision === 'escalate') {
      title = 'Escalate for Senior Review?';
      text = 'This report will be marked as ESCALATED and routed to the senior moderation queue.';
      confirmButtonText = 'Escalate Report';
    } else {
      if (action === 'BANNED') {
        title = 'Permanently Ban User Account?';
        text = 'This user will be permanently banned from NhamHealth and all active authentication sessions will be revoked.';
        confirmButtonText = 'Permanent Ban';
      } else if (action === 'SUSPENDED') {
        title = 'Temporarily Suspend Account?';
        text = 'Suspend this user account for ' + durationText + '? The user will be barred from signing in during this suspension period.';
        confirmButtonText = 'Suspend Account';
      } else if (action === 'POST_RESTRICTED') {
        title = 'Restrict Posting?';
        text = 'Restrict this user from creating meal posts or publishing recipes for ' + durationText + '?';
        confirmButtonText = 'Restrict Posting';
      } else if (action === 'COMMENT_RESTRICTED') {
        title = 'Restrict Commenting?';
        text = 'Restrict this user from posting comments on meal posts for ' + durationText + '?';
        confirmButtonText = 'Restrict Commenting';
      } else if (action === 'ACCOUNT_RESTRICTED') {
        title = 'Restrict Account Privileges?';
        text = 'Apply profile and account restrictions to this user.';
        confirmButtonText = 'Restrict Account';
      } else if (action === 'CONTENT_RESTORED') {
        title = 'Restore Content?';
        text = 'This content will be restored back to published/active status and become visible to the community.';
        confirmButtonText = 'Restore Content';
      } else if (action === 'CONTENT_REMOVED') {
        title = 'Remove Content?';
        text = 'This content will be removed from NhamHealth and made inaccessible to community members.';
        confirmButtonText = 'Remove Content';
      } else if (action === 'CONTENT_HIDDEN') {
        title = 'Hide Content?';
        text = 'This content will be hidden from public feeds and community search.';
        confirmButtonText = 'Hide Content';
      } else if (action === 'WARNING') {
        title = 'Issue Community Guidelines Warning?';
        text = 'A formal guidelines warning will be sent to the user and recorded in the audit history.';
        confirmButtonText = 'Send Warning';
      } else {
        title = 'Apply Moderation Action?';
        text = 'The moderation action will be applied and permanently logged.';
        confirmButtonText = 'Apply Action';
      }
    }

    const confirmResult = await Swal.fire({
      title,
      text,
      icon: decision === 'none' ? 'info' : (action === 'BANNED' ? 'error' : 'warning'),
      showCancelButton: true,
      confirmButtonColor: decision === 'none' ? '#16875b' : (decision === 'escalate' ? '#d97706' : (action === 'BANNED' ? '#b42318' : '#16875b')),
      cancelButtonColor: '#64748b',
      confirmButtonText
    });

    if (!confirmResult.isConfirmed) return;

    let url = '/admin/reports/' + id + '/dismiss';
    let method = 'PATCH';
    let body = { adminNote: adminNote ? adminNote.value.trim() : '' };

    if (decision === 'escalate') {
      url = '/admin/reports/' + id + '/escalate';
      method = 'PATCH';
      body.severity = escalateSeverity ? escalateSeverity.value : 'HIGH';
    } else if (decision === 'violation') {
      url = '/admin/reports/' + id + '/actions';
      method = 'POST';
      body.actionType = action;

      if (['SUSPENDED', 'POST_RESTRICTED', 'COMMENT_RESTRICTED'].includes(action)) {
        let start, end;
        if (durationVal === 'custom') {
          if (!startsAt.value || !expiresAt.value) {
            Swal.fire('Dates Required', 'Please select both start and end dates for custom duration.', 'warning');
            return;
          }
          start = new Date(startsAt.value);
          end = new Date(expiresAt.value);
          if (end <= start) {
            Swal.fire('Invalid Dates', 'End date must be after start date.', 'warning');
            return;
          }
        } else {
          start = new Date();
          end = new Date(start.getTime() + Number(durationVal) * 86400000);
        }
        body.startsAt = start.toISOString().replace('Z', '');
        body.expiresAt = end.toISOString().replace('Z', '');
      }
    }

    submitDecisionBtn.disabled = true;
    submitDecisionBtn.innerHTML = '<span class="button-spinner"></span> Saving decision...';

    try {
      const response = await fetch(url, { method, headers, body: JSON.stringify(body) });
      const data = await response.json().catch(() => ({}));
      submitDecisionBtn.disabled = false;

      if (!response.ok) {
        sync();
        Swal.fire('Unable to Save Decision', data.message || 'The moderation action could not be processed.', 'error');
        return;
      }

      await Swal.fire({
        title: 'Decision Recorded',
        text: decision === 'escalate' ? 'The report has been escalated to the senior moderation team.' : 'The moderation decision has been successfully enacted.',
        icon: 'success',
        confirmButtonColor: '#16875b'
      });

      location.href = returnUrl;
    } catch (err) {
      submitDecisionBtn.disabled = false;
      sync();
      Swal.fire('Network Error', 'Could not reach server. Please try again.', 'error');
    }
  });
})();
