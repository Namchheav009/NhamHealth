const profiles = [
    ["SJ","Sarah Johnson","sarah@example.com",28,"Female","165 cm","58 kg","21.3","Moderate","Maintain","None","Peanuts","Complete","May 20, 2025"],
    ["MC","Mike Chen","mike@example.com",34,"Male","175 cm","78 kg","25.5","High","Lose Weight","Low Carb","None","Complete","May 20, 2025"],
    ["PP","Priya Patel","priya@example.com",31,"Female","160 cm","62 kg","24.2","Moderate","Tone","Vegetarian","Dairy","Complete","May 19, 2025"],
    ["JW","James Wilson","james@example.com",45,"Male","180 cm","92 kg","28.4","Low","Lose Weight","None","None","Incomplete","May 18, 2025"],
    ["ED","Emma Davis","emma@example.com",29,"Female","168 cm","70 kg","24.8","Moderate","Maintain","Mediterranean","Shellfish","Incomplete","May 18, 2025"],
    ["AR","Alex Rodriguez","alex@example.com",37,"Male","178 cm","102 kg","32.2","Low","Lose Weight","None","Gluten","Needs Review","May 18, 2025"],
    ["LN","Lisa Nguyen","lisa@example.com",26,"Female","155 cm","50 kg","20.8","High","Build Muscle","High Protein","None","Complete","May 16, 2025"],
    ["DK","Daniel Kim","daniel@example.com",41,"Male","172 cm","88 kg","29.7","Low","Improve Health","Pescatarian","None","Incomplete","May 15, 2025"]
];

const rowsBox = document.getElementById("profileRows");
const resultText = document.getElementById("resultText");
const showingText = document.getElementById("showingText");

function badgeClass(value) {
    const text = value.toLowerCase();
    if (text === "needs review") return "review";
    if (text === "complete" || text === "high") return "complete";
    if (text === "incomplete" || text === "low") return "incomplete";
    return "moderate";
}

function drawRows(list) {
    rowsBox.innerHTML = "";

    if (!list.length) {
        rowsBox.innerHTML = '<tr><td colspan="14" style="padding:40px;text-align:center">No wellness profiles found.</td></tr>';
    } else {
        list.forEach(p => {
            rowsBox.insertAdjacentHTML("beforeend", `
                <tr>
                    <td><input type="checkbox"></td>
                    <td><div class="user-cell"><div class="avatar">${p[0]}</div><div><strong>${p[1]}</strong><small>${p[2]}</small></div></div></td>
                    <td>${p[3]}</td><td>${p[4]}</td><td>${p[5]}</td><td>${p[6]}</td><td>${p[7]}</td>
                    <td><span class="badge ${badgeClass(p[8])}">${p[8]}</span></td>
                    <td>${p[9]}</td><td>${p[10]}</td><td>${p[11]}</td>
                    <td><span class="badge ${badgeClass(p[12])}">${p[12]}</span></td>
                    <td>${p[13]}</td>
                    <td><button class="action"><i class="bi bi-three-dots-vertical"></i></button></td>
                </tr>`);
        });
    }

    resultText.textContent = `${list.length} profile${list.length === 1 ? "" : "s"}`;
    showingText.textContent = list.length
        ? `Showing 1 to ${list.length} of 24,583 profiles`
        : "No wellness profiles to show";
}

function filterRows() {
    const search = document.getElementById("searchInput").value.toLowerCase();
    const status = document.getElementById("statusFilter").value;
    const goal = document.getElementById("goalFilter").value;
    const activity = document.getElementById("activityFilter").value;
    const diet = document.getElementById("dietFilter").value;

    drawRows(profiles.filter(p =>
        (`${p[1]} ${p[2]}`).toLowerCase().includes(search) &&
        (!status || p[12].toLowerCase() === status) &&
        (!goal || p[9].toLowerCase() === goal) &&
        (!activity || p[8].toLowerCase() === activity) &&
        (!diet || p[10].toLowerCase() === diet)
    ));
}

["searchInput","statusFilter","goalFilter","activityFilter","dietFilter"].forEach(id => {
    const el = document.getElementById(id);
    el.addEventListener(el.tagName === "INPUT" ? "input" : "change", filterRows);
});

const modal = document.getElementById("profileModal");
document.getElementById("openModal").onclick = () => modal.classList.add("show");
document.getElementById("closeModal").onclick = () => modal.classList.remove("show");
document.getElementById("cancelModal").onclick = () => modal.classList.remove("show");

document.getElementById("profileForm").onsubmit = e => {
    e.preventDefault();
    alert("Connect this form to your Spring Boot service to save data.");
    modal.classList.remove("show");
};

document.getElementById("exportButton").onclick = () =>
    alert("Connect this button to your CSV export controller.");

drawRows(profiles);
