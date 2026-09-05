(() => {
  const chartData = window.adminDashboardChartData || {};
  const activityLabels = chartData.activityLabels || [];
  const activityUsers = chartData.activityUsers || [];
  const categoryLabels = chartData.categoryLabels || [];
  const categoryValues = chartData.categoryValues || [];

  const activityCanvas = document.getElementById("activityChart");
  if (activityCanvas && window.Chart) {
    new Chart(activityCanvas, {
      type: "bar",
      data: {
        labels: activityLabels,
        datasets: [
          {
            type: "line",
            label: "New users",
            data: activityUsers,
            borderColor: "#06a85b",
            backgroundColor: "#06a85b",
            borderWidth: 2,
            pointRadius: 3,
            pointHoverRadius: 4,
            tension: 0.35,
            yAxisID: "y",
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: { legend: { display: false }, tooltip: { padding: 10 } },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: "#8895a5", font: { size: 9 } },
            border: { display: false },
          },
          y: {
            beginAtZero: true,
            ticks: { precision: 0, color: "#8895a5", font: { size: 9 } },
            grid: { color: "#eef1f5" },
            border: { display: false },
          },
        },
      },
    });
  }

  const categoryCanvas = document.getElementById("categoryChart");
  if (categoryCanvas && window.Chart) {
    new Chart(categoryCanvas, {
      type: "doughnut",
      data: {
        labels: categoryLabels,
        datasets: [
          {
            data: categoryValues,
            backgroundColor: [
              "#0ba95d",
              "#3b82f6",
              "#f6c744",
              "#ff914d",
              "#f33f52",
              "#54c9c6",
            ],
            borderWidth: 0,
            hoverOffset: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "67%",
        plugins: { legend: { display: false }, tooltip: { padding: 10 } },
      },
    });
  }

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
