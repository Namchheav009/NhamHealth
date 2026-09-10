(() => {
  const $ = (id) => document.getElementById(id);
  const fixedType = document.querySelector('meta[name="report-type"]')?.content || "";
  let currentPage = 0;
  let pageData = null;

  const label = (value) => String(value || "").toLowerCase().replaceAll("_", " ").replace(/\b\w/g, (c) => c.toUpperCase());
  const escapeHtml = (value) => String(value ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const targetLabel = (report) => report.targetSummary || (report.type === "PROFILE" ? report.reportedUserName : label(report.type) + " #" + report.targetId);

  function timeAgo(dateString) {
    if (!dateString) return "";
    const date = new Date(dateString);
    const now = new Date();
    const seconds = Math.floor((now - date) / 1000);
    if (seconds < 60) return "Just now";
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) return minutes + "m ago";
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return hours + "h ago";
    const days = Math.floor(hours / 24);
    if (days === 1) return "Yesterday";
    if (days < 7) return days + "d ago";
    return new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric" }).format(date);
  }

  function params(page = 0) {
    const query = new URLSearchParams({ page });
    const values = {
      type: fixedType || $("reportType")?.value,
      status: $("reportStatus").value,
      reason: $("reportReason").value,
      severity: $("reportSeverity").value,
      search: $("reportSearch").value.trim()
    };
    Object.entries(values).forEach(([key, value]) => { if (value) query.set(key, value); });
    if ($("reportFrom").value) query.set("from", $("reportFrom").value + "T00:00:00");
    if ($("reportTo").value) query.set("to", $("reportTo").value + "T23:59:59");
    return query;
  }

  function syncActiveStatusControls(statusValue) {
    document.querySelectorAll(".stat-card").forEach((card) => {
      card.classList.toggle("active-stat", card.dataset.status === statusValue);
    });
    document.querySelectorAll(".queue-tab").forEach((tab) => {
      tab.classList.toggle("active", tab.dataset.status === statusValue);
    });
  }

  async function load(page = 0) {
    $("reportRows").innerHTML = '<tr><td colspan="9" class="empty-state"><div class="button-spinner"></div><strong style="margin-top:10px;">Loading moderation queue&hellip;</strong></td></tr>';
    syncActiveStatusControls($("reportStatus").value);

    try {
      const response = await fetch("/admin/reports/data?" + params(page));
      if (!response.ok) {
        $("reportRows").innerHTML = '<tr><td colspan="9" class="empty-state"><i class="bi bi-exclamation-triangle" style="color:#b42318;font-size:24px;"></i><strong>Reports could not be loaded.</strong><span style="display:block;margin-top:4px;">Please check server connection and try again.</span></td></tr>';
        return;
      }
      pageData = await response.json();
      currentPage = pageData.number;
      render();
    } catch (err) {
      $("reportRows").innerHTML = '<tr><td colspan="9" class="empty-state"><i class="bi bi-wifi-off" style="color:#b42318;font-size:24px;"></i><strong>Connection error.</strong></td></tr>';
    }
  }

  function render() {
    const rows = pageData.content || [];
    $("resultSummary").textContent = pageData.totalElements + " record" + (pageData.totalElements === 1 ? "" : "s");
    $("pageSummary").textContent = pageData.totalElements ? "Page " + (pageData.number + 1) + " of " + pageData.totalPages : "";

    if (!rows.length) {
      $("reportRows").innerHTML = '<tr><td colspan="9" class="empty-state"><i class="bi bi-inbox" style="font-size:28px;color:#94a3b8;"></i><strong>No reports found</strong><span>There are no reports matching your current filter criteria.</span><button class="btn btn-small" id="emptyResetBtn" style="margin-top:12px;"><i class="bi bi-arrow-counterclockwise"></i> Reset all filters</button></td></tr>';
      $("emptyResetBtn")?.addEventListener("click", () => {
        ["reportSearch", "reportType", "reportStatus", "reportReason", "reportSeverity", "reportFrom", "reportTo"].forEach((id) => { if ($(id)) $(id).value = ""; });
        syncActiveStatusControls("");
        load(0);
      });
      $("pagePrev").disabled = true;
      $("pageNext").disabled = true;
      $("pageNumbers").innerHTML = "";
      return;
    }

    $("reportRows").innerHTML = rows.map((report, index) => {
      const actionable = ["PENDING", "UNDER_REVIEW", "ESCALATED"].includes(report.status);
      const isEscalated = report.status === "ESCALATED";

      let actionButtons = '<div class="action-btn-group">';
      actionButtons += '<button class="btn-icon-small preview-btn" data-index="' + index + '" title="Quick Preview"><i class="bi bi-eye"></i></button>';

      if (actionable) {
        actionButtons += '<a class="btn-small ' + (isEscalated ? "btn-escalate" : "primary") + '" href="/admin/reports/' + report.id + '/review"><i class="bi ' + (isEscalated ? "bi-shield-exclamation" : "bi-shield-check") + '"></i> ' + (isEscalated ? "Review" : "Review") + '</a>';
      } else {
        actionButtons += '<a class="btn-small" href="/admin/reports/' + report.id + '"><i class="bi bi-file-earmark-text"></i> View</a>';
      }
      actionButtons += '</div>';

      const typeIcon = report.type === "PROFILE" ? "bi-person-badge" : (report.type === "POST" ? "bi-file-post" : "bi-chat-left-dots");
      const userInitial = (report.reportedUserName || "U").substring(0, 1).toUpperCase();
      const formattedDate = new Intl.DateTimeFormat(undefined, { dateStyle: "medium", timeStyle: "short" }).format(new Date(report.createdAt));
      const relativeTime = timeAgo(report.createdAt);

      let statusIcon = "bi-hourglass-split";
      if (report.status === "UNDER_REVIEW") statusIcon = "bi-eye";
      else if (report.status === "ESCALATED") statusIcon = "bi-shield-exclamation";
      else if (report.status === "RESOLVED") statusIcon = "bi-check2-circle";
      else if (report.status === "DISMISSED") statusIcon = "bi-x-circle";

      return '<tr>' +
        '<td><span class="report-id-badge">#' + report.id + '</span></td>' +
        '<td><span class="type-badge type-' + report.type.toLowerCase() + '"><i class="bi ' + typeIcon + '"></i> ' + label(report.type) + '</span></td>' +
        '<td>' +
          '<div class="user-cell">' +
            '<div class="user-avatar">' + escapeHtml(userInitial) + '</div>' +
            '<div class="user-info">' +
              '<strong>' + escapeHtml(report.reportedUserName) + '</strong>' +
              '<small title="' + escapeHtml(targetLabel(report)) + '">' + escapeHtml(targetLabel(report)) + '</small>' +
            '</div>' +
          '</div>' +
        '</td>' +
        '<td>' +
          '<div class="reporter-cell">' +
            '<strong>' + escapeHtml(report.reporterName) + '</strong>' +
            '<small><i class="bi bi-shield-lock-fill"></i> ID #' + report.reporterId + '</small>' +
          '</div>' +
        '</td>' +
        '<td><span class="reason-cell-text">' + label(report.reason) + '</span></td>' +
        '<td><span class="severity-badge severity-' + report.severity.toLowerCase() + (report.severity === "CRITICAL" ? " pulse" : "") + '"><i class="bi ' + (report.severity === "CRITICAL" || report.severity === "HIGH" ? "bi-exclamation-circle-fill" : "bi-info-circle") + '"></i> ' + label(report.severity) + '</span></td>' +
        '<td><span class="status-pill status-' + report.status.toLowerCase() + '"><i class="bi ' + statusIcon + '"></i> ' + label(report.status) + '</span></td>' +
        '<td><div class="time-cell" title="' + formattedDate + '"><strong>' + relativeTime + '</strong><small>' + formattedDate.split(",")[0] + '</small></div></td>' +
        '<td class="report-actions">' + actionButtons + '</td>' +
      '</tr>';
    }).join("");

    $("pagePrev").disabled = pageData.first;
    $("pageNext").disabled = pageData.last;
    $("pageNumbers").innerHTML = Array.from({ length: pageData.totalPages }, (_, index) => {
      if (Math.abs(index - currentPage) <= 2) {
        return '<button class="page-btn ' + (index === currentPage ? "active" : "") + '" data-page="' + index + '">' + (index + 1) + '</button>';
      }
      return "";
    }).join("");

    // Wire quick preview modal buttons
    document.querySelectorAll(".preview-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        const index = Number(btn.dataset.index);
        const item = (pageData?.content || [])[index];
        if (item) openQuickPreview(item);
      });
    });
  }

  function openQuickPreview(report) {
    const modal = $("quickPreviewModal");
    if (!modal) return;

    $("modalTitle").textContent = "Report #" + report.id + " (" + label(report.type) + ")";
    $("modalTypeBadge").textContent = label(report.type);
    $("modalTypeBadge").className = "type-badge type-" + report.type.toLowerCase();

    $("modalSeverityBadge").textContent = label(report.severity) + " Severity";
    $("modalSeverityBadge").className = "severity-badge severity-" + report.severity.toLowerCase();

    $("modalStatusPill").textContent = label(report.status);
    $("modalStatusPill").className = "status-pill status-" + report.status.toLowerCase();

    $("modalUserName").textContent = report.reportedUserName;
    $("modalUserId").textContent = "User ID #" + report.reportedUserId;
    $("modalUserAvatar").textContent = (report.reportedUserName || "U").substring(0, 1).toUpperCase();

    $("modalReporterName").textContent = report.reporterName;
    $("modalReporterId").innerHTML = '<i class="bi bi-shield-lock-fill"></i> Confidential ID #' + report.reporterId;

    $("modalReason").textContent = label(report.reason);
    $("modalSnapshot").textContent = report.contentSnapshot || (report.type === "PROFILE" ? "Report concerns overall profile & activity." : "No snapshot recorded.");
    $("modalDescription").textContent = report.description || "No description supplied by reporter.";

    $("modalReviewBtn").href = "/admin/reports/" + report.id + "/review";

    modal.classList.add("show");
    modal.setAttribute("aria-hidden", "false");
  }

  function closeQuickPreview() {
    const modal = $("quickPreviewModal");
    if (!modal) return;
    modal.classList.remove("show");
    modal.setAttribute("aria-hidden", "true");
  }

  $("closeModalBtn")?.addEventListener("click", closeQuickPreview);
  $("cancelModalBtn")?.addEventListener("click", closeQuickPreview);
  $("quickPreviewModal")?.addEventListener("click", (e) => {
    if (e.target === $("quickPreviewModal")) closeQuickPreview();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closeQuickPreview();
  });

  async function summary() {
    try {
      const data = await fetch("/admin/reports/summary").then((res) => res.json());
      $("statTotal").textContent = data.total;
      $("statPending").textContent = data.pending;
      $("statReview").textContent = data.underReview;
      $("statEscalated").textContent = data.escalated || 0;
      $("statResolved").textContent = data.resolved;
      $("statDismissed").textContent = data.dismissed;

      $("tabBadgeTotal").textContent = data.total;
      $("tabBadgePending").textContent = data.pending;
      $("tabBadgeReview").textContent = data.underReview;
      $("tabBadgeEscalated").textContent = data.escalated || 0;
      $("tabBadgeResolved").textContent = data.resolved;
      $("tabBadgeDismissed").textContent = data.dismissed;
    } catch (e) {}
  }

  // Stat cards click -> filter
  document.querySelectorAll(".stat-card").forEach((card) => {
    card.addEventListener("click", () => {
      const status = card.dataset.status ?? "";
      $("reportStatus").value = status;
      syncActiveStatusControls(status);
      load(0);
    });
    card.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        card.click();
      }
    });
  });

  // Queue tabs click -> filter
  document.querySelectorAll(".queue-tab").forEach((tab) => {
    tab.addEventListener("click", () => {
      const status = tab.dataset.status ?? "";
      $("reportStatus").value = status;
      syncActiveStatusControls(status);
      load(0);
    });
  });

  let timer;
  const refresh = () => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      syncActiveStatusControls($("reportStatus").value);
      load(0);
    }, 250);
  };

  ["reportSearch", "reportType", "reportStatus", "reportReason", "reportSeverity", "reportFrom", "reportTo"].forEach((id) => {
    $(id)?.addEventListener(id === "reportSearch" ? "input" : "change", refresh);
  });

  $("clearReportFilters").addEventListener("click", () => {
    ["reportSearch", "reportType", "reportStatus", "reportReason", "reportSeverity", "reportFrom", "reportTo"].forEach((id) => {
      if ($(id)) $(id).value = "";
    });
    syncActiveStatusControls("");
    load(0);
  });

  $("refreshReports").addEventListener("click", () => {
    summary();
    load(currentPage);
  });
  $("pagePrev").addEventListener("click", () => load(currentPage - 1));
  $("pageNext").addEventListener("click", () => load(currentPage + 1));
  $("pageNumbers").addEventListener("click", (event) => {
    const button = event.target.closest("[data-page]");
    if (button) load(Number(button.dataset.page));
  });

  $("exportReports").addEventListener("click", () => {
    const rows = pageData?.content || [];
    const csv = [
      ["ID", "Type", "Reporter", "Reported User", "Target", "Reason", "Severity", "Status", "Created"],
      ...rows.map((report) => [
        report.id,
        report.type,
        report.reporterName,
        report.reportedUserName,
        report.targetId,
        label(report.reason),
        report.severity,
        report.status,
        report.createdAt
      ])
    ].map((row) => row.map((val) => '"' + String(val ?? "").replaceAll('"', '""') + '"').join(",")).join("\n");

    const anchor = document.createElement("a");
    anchor.href = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
    anchor.download = "moderation_reports.csv";
    anchor.click();
    URL.revokeObjectURL(anchor.href);
  });

  summary();
  load();
})();
