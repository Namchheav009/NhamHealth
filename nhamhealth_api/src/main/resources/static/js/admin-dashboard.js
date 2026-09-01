(() => {
    const chartData = window.adminDashboardChartData || {};
    const activityLabels = chartData.activityLabels || [];
    const activityUsers = chartData.activityUsers || [];
    const categoryLabels = chartData.categoryLabels || [];
    const categoryValues = chartData.categoryValues || [];

    const activityCanvas = document.getElementById('activityChart');
    if (activityCanvas && window.Chart) {
        new Chart(activityCanvas, {
            type: 'bar',
            data: {
                labels: activityLabels,
                datasets: [
                    {
                        type: 'line',
                        label: 'New users',
                        data: activityUsers,
                        borderColor: '#06a85b',
                        backgroundColor: '#06a85b',
                        borderWidth: 2,
                        pointRadius: 3,
                        pointHoverRadius: 4,
                        tension: 0.35,
                        yAxisID: 'y'
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: { mode: 'index', intersect: false },
                plugins: { legend: { display: false }, tooltip: { padding: 10 } },
                scales: {
                    x: { grid: { display: false }, ticks: { color: '#8895a5', font: { size: 9 } }, border: { display: false } },
                    y: { beginAtZero: true, ticks: { precision: 0, color: '#8895a5', font: { size: 9 } }, grid: { color: '#eef1f5' }, border: { display: false } }
                }
            }
        });
    }

    const categoryCanvas = document.getElementById('categoryChart');
    if (categoryCanvas && window.Chart) {
        new Chart(categoryCanvas, {
            type: 'doughnut',
            data: {
                labels: categoryLabels,
                datasets: [{
                    data: categoryValues,
                    backgroundColor: ['#0ba95d', '#3b82f6', '#f6c744', '#ff914d', '#f33f52', '#54c9c6'],
                    borderWidth: 0,
                    hoverOffset: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: '67%',
                plugins: { legend: { display: false }, tooltip: { padding: 10 } }
            }
        });
    }
})();
