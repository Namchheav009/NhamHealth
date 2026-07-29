(() => {
    const menuToggle = document.getElementById('menuToggle');
    const overlay = document.getElementById('sidebarOverlay');

    menuToggle?.addEventListener('click', () => document.body.classList.toggle('sidebar-open'));
    overlay?.addEventListener('click', () => document.body.classList.remove('sidebar-open'));

    const activityCanvas = document.getElementById('activityChart');
    if (activityCanvas && window.Chart) {
        new Chart(activityCanvas, {
            type: 'bar',
            data: {
                labels: ['May 14', 'May 15', 'May 16', 'May 17', 'May 18', 'May 19', 'May 20'],
                datasets: [
                    {
                        type: 'line',
                        label: 'Active Users',
                        data: [5600, 8100, 6100, 7100, 8200, 5900, 7600],
                        borderColor: '#06a85b',
                        backgroundColor: '#06a85b',
                        borderWidth: 2,
                        pointRadius: 3,
                        pointHoverRadius: 4,
                        tension: 0.35,
                        yAxisID: 'y'
                    },
                    {
                        label: 'Meal Logs',
                        data: [13800, 15500, 14800, 16600, 15100, 14600, 19000],
                        backgroundColor: 'rgba(76, 157, 247, .45)',
                        borderRadius: 3,
                        maxBarThickness: 18,
                        yAxisID: 'y1'
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
                    y: { beginAtZero: true, max: 10000, ticks: { stepSize: 2000, callback: value => `${value / 1000}K`, color: '#8895a5', font: { size: 9 } }, grid: { color: '#eef1f5' }, border: { display: false } },
                    y1: { beginAtZero: true, position: 'right', max: 25000, ticks: { stepSize: 5000, callback: value => `${value / 1000}K`, color: '#8895a5', font: { size: 9 } }, grid: { drawOnChartArea: false }, border: { display: false } }
                }
            }
        });
    }

    const categoryCanvas = document.getElementById('categoryChart');
    if (categoryCanvas && window.Chart) {
        new Chart(categoryCanvas, {
            type: 'doughnut',
            data: {
                labels: ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Desserts', 'Beverages'],
                datasets: [{
                    data: [776, 693, 664, 444, 290, 257],
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
