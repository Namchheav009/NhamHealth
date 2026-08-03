const rowsBox = document.getElementById("mealRows");
const resultText = document.getElementById("resultText");
const showingText = document.getElementById("showingText");

let meals = [];
let currentFilter = {};

const tagClass = tag => {
    const t = tag.toLowerCase();
    if (["high protein", "high fiber"].includes(t)) return "tag-orange";
    if (["gluten-free", "vegan", "vegetarian"].includes(t)) return "tag-green";
    if (["low carb", "omega-3"].includes(t)) return "tag-blue";
    return "tag-purple";
};

const statusClass = status => {
    const s = status.toLowerCase();
    if (s === "published") return "status-published";
    if (s === "draft") return "status-draft";
    return "status-archived";
};

function drawRows(list) {
    rowsBox.innerHTML = "";
    if (!list.length) {
        rowsBox.innerHTML = '<tr><td colspan="10" style="padding:40px;text-align:center">No meals found.</td></tr>';
    } else {
        list.forEach(meal => {
            const tags = (meal.tags || []).map(tag => `<span class="pill ${tagClass(tag)}">${tag}</span>`).join(" ");
            rowsBox.insertAdjacentHTML("beforeend", `
                <tr>
                    <td>
                        <div class="meal-cell">
                            <div class="meal-thumb"><i class="fa-solid ${meal.iconClass || 'fa-utensils'}"></i></div>
                            <div>
                                <strong>${meal.mealName}</strong>
                                <small>${meal.category} meal</small>
                            </div>
                        </div>
                    </td>
                    <td>${meal.category}</td>
                    <td>${meal.calories}</td>
                    <td>${meal.servingSize}</td>
                    <td>${tags}</td>
                    <td><i class="fa-solid fa-star" style="color:#f5a623"></i> ${meal.reviews}</td>
                    <td>${meal.favorites.toLocaleString()}</td>
                    <td><span class="pill ${statusClass(meal.status)}">${meal.status}</span></td>
                    <td>${meal.updatedDate}</td>
                    <td><button class="action" type="button" aria-label="Meal actions"><i class="fa-solid fa-ellipsis-vertical"></i></button></td>
                </tr>
            `);
        });
    }

    resultText.textContent = `${list.length} meal${list.length === 1 ? "" : "s"}`;
    showingText.textContent = list.length ? `Showing 1 to ${list.length} of ${meals.length} meals` : "No meals to show";
}

function filterMeals() {
    currentFilter.search = document.getElementById("searchInput").value.toLowerCase();
    currentFilter.category = document.getElementById("categoryFilter").value.toLowerCase();
    currentFilter.status = document.getElementById("statusFilter").value.toLowerCase();
    currentFilter.tag = document.getElementById("tagFilter").value.toLowerCase();

    const filtered = meals.filter(meal => {
        const matchesSearch = meal.mealName.toLowerCase().includes(currentFilter.search);
        const matchesCategory = !currentFilter.category || meal.category.toLowerCase() === currentFilter.category;
        const matchesStatus = !currentFilter.status || meal.status.toLowerCase() === currentFilter.status;
        const matchesTag = !currentFilter.tag || (meal.tags || []).some(item => item.toLowerCase() === currentFilter.tag);
        return matchesSearch && matchesCategory && matchesStatus && matchesTag;
    });

    drawRows(filtered);
}

async function loadMeals() {
    try {
        const response = await fetch("/api/v1/admin/meals");
        if (!response.ok) {
            throw new Error("Unable to load meals");
        }

        meals = await response.json();
        drawRows(meals);
    } catch (error) {
        rowsBox.innerHTML = '<tr><td colspan="10" style="padding:40px;text-align:center">Unable to load meals from the API.</td></tr>';
        console.error(error);
    }
}

["searchInput", "categoryFilter", "statusFilter", "tagFilter"].forEach(id => {
    const element = document.getElementById(id);
    element.addEventListener(element.tagName === "INPUT" ? "input" : "change", filterMeals);
});

document.getElementById("clearFilters").onclick = () => {
    document.getElementById("searchInput").value = "";
    document.getElementById("categoryFilter").value = "";
    document.getElementById("statusFilter").value = "";
    document.getElementById("tagFilter").value = "";
    filterMeals();
};

const modal = document.getElementById("mealModal");
document.getElementById("openModal").onclick = () => modal.classList.add("show");
document.getElementById("closeModal").onclick = () => modal.classList.remove("show");
document.getElementById("cancelModal").onclick = () => modal.classList.remove("show");
document.getElementById("mealForm").onsubmit = async event => {
    event.preventDefault();
    try {
        const response = await fetch("/api/v1/admin/meals", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ action: "save" })
        });
        if (!response.ok) {
            throw new Error("Unable to save meal");
        }
        const result = await response.json();
        alert(result.message || "Meal saved successfully.");
        modal.classList.remove("show");
    } catch (error) {
        alert("Connect this form to your Spring Boot service to save meal data.");
        console.error(error);
    }
};
document.getElementById("exportButton").onclick = () => alert("Connect this button to your CSV export controller.");

loadMeals();
