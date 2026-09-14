(() => {
  const chartData = window.adminDashboardChartData || {};
  const activityLabels = chartData.activityLabels || [];
  const activityUsers = chartData.activityUsers || [];
  const categoryLabels = chartData.categoryLabels || [];
  const categoryValues = chartData.categoryValues || [];

  const activityCanvas = document.getElementById("activityChart");
  const categoryCanvas = document.getElementById("categoryChart");
  const categoryColors = [
    "#37d98a",
    "#75b4ff",
    "#f5c761",
    "#f7ad69",
    "#f37586",
    "#77d3d1",
    "#a995f7",
    "#e48ad5",
  ];
  let activityChart;
  let categoryChart;

  const chartTheme = () => {
    const dark = document.documentElement.dataset.theme === "dark";
    return {
      axis: dark ? "#718191" : "#8592a1",
      grid: dark ? "rgba(109, 129, 146, .14)" : "rgba(100, 116, 139, .12)",
      tooltipBackground: dark ? "#17222c" : "#111827",
      tooltipText: "#f8fafc",
      ringBorder: dark ? "#101820" : "#ffffff",
    };
  };

  const renderCharts = () => {
    if (!window.Chart) return;
    const colors = chartTheme();

    activityChart?.destroy();
    categoryChart?.destroy();

    if (activityCanvas) {
      activityChart = new Chart(activityCanvas, {
        type: "line",
        data: {
          labels: activityLabels,
          datasets: [
            {
              label: "New users",
              data: activityUsers,
              borderColor: "#37d98a",
              backgroundColor: (context) => {
                const { ctx, chartArea } = context.chart;
                if (!chartArea) return "rgba(55, 217, 138, .08)";
                const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
                gradient.addColorStop(0, "rgba(55, 217, 138, .24)");
                gradient.addColorStop(1, "rgba(55, 217, 138, 0)");
                return gradient;
              },
              borderWidth: 2,
              fill: true,
              pointRadius: 0,
              pointHoverRadius: 4,
              pointHoverBorderWidth: 3,
              pointHoverBorderColor: colors.ringBorder,
              pointBackgroundColor: "#37d98a",
              tension: 0.38,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          layout: { padding: { top: 8, right: 4 } },
          plugins: {
            legend: { display: false },
            tooltip: {
              displayColors: false,
              padding: 11,
              backgroundColor: colors.tooltipBackground,
              titleColor: colors.tooltipText,
              bodyColor: colors.tooltipText,
              borderColor: colors.grid,
              borderWidth: 1,
              cornerRadius: 8,
              callbacks: {
                label: (context) => `${context.parsed.y} new user${context.parsed.y === 1 ? "" : "s"}`,
              },
            },
          },
          scales: {
            x: {
              grid: { display: false },
              ticks: { color: colors.axis, padding: 8, font: { size: 9, weight: "600" } },
              border: { display: false },
            },
            y: {
              beginAtZero: true,
              grace: "15%",
              ticks: { precision: 0, color: colors.axis, padding: 10, font: { size: 9 } },
              grid: { color: colors.grid, drawTicks: false },
              border: { display: false },
            },
          },
        },
      });
    }

    if (categoryCanvas) {
      categoryChart = new Chart(categoryCanvas, {
        type: "doughnut",
        data: {
          labels: categoryLabels,
          datasets: [
            {
              data: categoryValues,
              backgroundColor: categoryLabels.map((_, index) => categoryColors[index % categoryColors.length]),
              borderColor: colors.ringBorder,
              borderWidth: 3,
              hoverBorderWidth: 3,
              hoverOffset: 3,
              spacing: 1,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          cutout: "72%",
          plugins: {
            legend: { display: false },
            tooltip: {
              padding: 10,
              backgroundColor: colors.tooltipBackground,
              titleColor: colors.tooltipText,
              bodyColor: colors.tooltipText,
              borderColor: colors.grid,
              borderWidth: 1,
              cornerRadius: 8,
            },
          },
        },
      });
    }
  };

  renderCharts();

  new MutationObserver((mutations) => {
    if (mutations.some((mutation) => mutation.attributeName === "data-theme")) {
      renderCharts();
    }
  }).observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });

  const csrfToken = document.querySelector('meta[name="_csrf"]')?.content;
  const csrfHeader = document.querySelector(
    'meta[name="_csrf_header"]',
  )?.content;
  const alerts = window.adminAlerts ?? {
    confirmDelete: ({ text }) => Promise.resolve(window.confirm(text)),
    success: (heading, text) => Promise.resolve(window.alert(text || heading)),
    error: (text) => Promise.resolve(window.alert(text)),
  };

  const requestHeaders = () => ({
    Accept: "application/json",
    ...(csrfToken && csrfHeader ? { [csrfHeader]: csrfToken } : {}),
  });

  document.querySelectorAll(".panel.table-panel .status-control").forEach((button) => {
    button.addEventListener("click", async () => {
      const row = button.closest("tr");
      const userId = button.dataset.id || row?.dataset.id;
      const name = button.dataset.name || row?.dataset.name || "this user";
      const active = (button.dataset.status || row?.dataset.status || "").toUpperCase() === "ACTIVE";
      if (!userId) return;
      const nextStatus = active ? "SUSPENDED" : "ACTIVE";
      const confirmed = await alerts.confirmDelete({
        title: `${active ? "Suspend" : "Activate"} Flutter access?`,
        text: `${active ? "Block" : "Restore"} ${name}'s Flutter app access?`,
        confirmButtonText: active ? "Suspend access" : "Activate access",
      });
      if (!confirmed) return;
      button.disabled = true;
      try {
        const response = await fetch(`/admin/users/${userId}/status?status=${nextStatus}`, {
          method: "PATCH",
          headers: requestHeaders(),
        });
        if (!response.ok) {
          const body = await response.json().catch(() => ({}));
          throw new Error(body.message || "Unable to update user access.");
        }
        await alerts.success(active ? "Access suspended" : "Access activated",
          `${name} can ${active ? "no longer" : "now"} use the Flutter app.`);
        window.location.reload();
      } catch (error) {
        await alerts.error(error.message || "Unable to update user access.");
        button.disabled = false;
      }
    });
  });

  document.querySelectorAll(".panel.table-panel .revoke-sessions").forEach((button) => {
    button.addEventListener("click", async () => {
      const row = button.closest("tr");
      const userId = button.dataset.id || row?.dataset.id;
      const name = button.dataset.name || row?.dataset.name || "this user";
      if (!userId) return;
      const confirmed = await alerts.confirmDelete({
        title: "Force sign out?",
        text: `Sign ${name} out of every Flutter device?`,
        confirmButtonText: "Force sign out",
      });
      if (!confirmed) return;
      button.disabled = true;
      try {
        const response = await fetch(`/admin/users/${userId}/revoke-sessions`, {
          method: "POST",
          headers: requestHeaders(),
        });
        if (!response.ok) {
          const body = await response.json().catch(() => ({}));
          throw new Error(body.message || "Unable to revoke user sessions.");
        }
        await alerts.success("Sessions revoked", `${name} has been signed out on all Flutter devices.`);
      } catch (error) {
        await alerts.error(error.message || "Unable to revoke user sessions.");
        button.disabled = false;
      }
    });
  });

  document
    .querySelectorAll(".panel.table-panel .delete-user")
    .forEach((button) => {
      button.addEventListener("click", async () => {
        const row = button.closest("tr");
        const userId = button.dataset.id || row?.dataset.id;
        const name = button.dataset.name || row?.dataset.name || "this user";
        if (!userId) return;

        const confirmed = await alerts.confirmDelete({
          title: "Delete user?",
          text: `Permanently delete ${name}? Their account and profile will be removed from the platform. This cannot be undone.`,
          confirmButtonText: "Yes, delete user!",
        });
        if (!confirmed) return;

        button.disabled = true;
        try {
          const response = await fetch(`/admin/users/${userId}`, {
            method: "DELETE",
            headers: requestHeaders(),
          });
          if (!response.ok) {
            const body = await response.json().catch(() => ({}));
            throw new Error(body.message || "Unable to delete this user.");
          }

          if (row) {
            row.remove();
          }

          const tableBody = document.querySelector(".panel.table-panel tbody");
          if (tableBody && !tableBody.querySelector("tr[data-id]")) {
            tableBody.innerHTML =
              '<tr><td colspan="4" class="table-empty">No users yet.</td></tr>';
          }

          const totalUsersElem = document.querySelector(
            '.stat-card[href$="/admin/users"] strong',
          );
          if (totalUsersElem) {
            const current = parseInt(
              totalUsersElem.textContent.replace(/,/g, ""),
              10,
            );
            if (!isNaN(current) && current > 0) {
              totalUsersElem.textContent = (current - 1).toLocaleString();
            }
          }

          await alerts.success("User deleted", `${name} has been deleted.`);
        } catch (error) {
          await alerts.error(error.message || "Unable to delete this user.");
          button.disabled = false;
        }
      });
    });
})();
